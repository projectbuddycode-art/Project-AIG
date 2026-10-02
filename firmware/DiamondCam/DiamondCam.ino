/*
  DiamondCam ESP32 firmware — AIG authoritative machine controller
  Version: 2.2.0

  Hardware (confirmed):
    ESP32-WROOM-32
    SoftAP SSID DiamondCam_Device  (password is NOT exposed by HTTP)
    HTTP http://192.168.4.1:80
    NEMA17 1.8 deg/full-step, 200 full steps/rev, direct drive
    DM542 DIP:
      SW1 ON, SW2 ON, SW3 OFF  → 2.84A peak (motor phase-current rating NOT verified)
      SW4 ON                   → full idle current
      SW5 ON, SW6 ON, SW7 OFF, SW8 ON → 3200 pulses/rev, 1/16 microstep
    STEP=26 DIR=27 ENABLE=25 (active LOW) LIGHT PWM=33
    No HOME, no limit, no encoder

  Physical camera-side CW is NOT confirmed. Do not set POSITIVE_DIRECTION_IS_CW
  until a physical test is complete. calibration.confirmed stays false.

  Libraries: ArduinoJson 6 or 7, AccelStepper
  Board: ESP32 Dev Module
*/

#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <AccelStepper.h>
#include <math.h>

static const char *WIFI_SSID = "DiamondCam_Device";
static const char *WIFI_PASSWORD = "12345678";

static const char *MACHINE_ID = "AIG-DIAMONDCAM";
static const char *FIRMWARE_NAME = "DiamondCam";
static const char *FIRMWARE_VERSION = "2.2.0";
static const char *MOTOR_TYPE = "NEMA17";

static const int PIN_STEP = 26;
static const int PIN_DIR = 27;
static const int PIN_ENABLE = 25;
static const int PIN_LED = 33;

static const float MOTOR_STEP_ANGLE_DEG = 1.8f;
static const int FULL_STEPS_PER_REV = 200;
static const int MICROSTEPS = 16;                // DM542 1/16 microstep
static const float PULSES_PER_REVOLUTION = 3200.0f;
static const float PULSES_PER_DEGREE = PULSES_PER_REVOLUTION / 360.0f; // 8.888889
static const float GEAR_RATIO = 1.0f;            // direct drive

// Flutter DiamondCamService clamps rotate to 0..180. Firmware accepts the same
// range so the app contract is not broken. 0 and 180 are valid.
static const float MIN_ANGLE_DEG = 0.0f;
static const float MAX_ANGLE_DEG = 180.0f;
static const float MIN_SPEED = 1.0f;
static const float MAX_SPEED = 100.0f;
static const int MIN_INTENSITY = 0;
static const int MAX_INTENSITY = 100;

// -1 = camera-side CW unconfirmed. 1 = positive pulses are CW. 0 = inverted.
static const int POSITIVE_DIRECTION_IS_CW = -1;

static const int PWM_FREQ_HZ = 5000;
static const int PWM_RESOLUTION_BITS = 8;
static const int LEDC_CHANNEL = 0;
static const int SERIAL_BAUD = 115200;

WebServer server(80);
AccelStepper stepper(AccelStepper::DRIVER, PIN_STEP, PIN_DIR);

bool lightOn = false;
int lightIntensity = 0;
bool motorRunning = false;
bool continuousMode = false;
float commandedAngleDeg = 0.0f;
int lastDuty = -1;
float lastAcceleration = 800.0f;

#if ARDUINOJSON_VERSION_MAJOR >= 7
#define DC_JSON_DOC(name, capacity) JsonDocument name
#else
#define DC_JSON_DOC(name, capacity) StaticJsonDocument<capacity> name
#endif

bool jsonHas(JsonDocument &doc, const char *key) {
#if ARDUINOJSON_VERSION_MAJOR >= 7
  return !doc[key].isNull();
#else
  return doc.containsKey(key);
#endif
}

bool jsonIsNumber(JsonVariant v) {
  if (v.is<float>() || v.is<double>()) {
    return true;
  }
  if (v.is<int>() || v.is<long>() || v.is<unsigned int>() || v.is<unsigned long>()) {
    return true;
  }
  return false;
}

bool jsonIsBool(JsonVariant v) {
  if (v.is<bool>()) {
    return true;
  }
  if (jsonIsNumber(v)) {
    const float n = v.as<float>();
    return n == 0.0f || n == 1.0f;
  }
  return false;
}

JsonObject jsonObject(JsonDocument &doc, const char *key) {
#if ARDUINOJSON_VERSION_MAJOR >= 7
  return doc[key].to<JsonObject>();
#else
  return doc.createNestedObject(key);
#endif
}

long angleToPulses(float angleDeg) {
  return lroundf(angleDeg * PULSES_PER_DEGREE);
}

float speedToPulsesPerSecond(float speed) {
  // App speed 1..100 → 32..3200 pulses/sec. At 100 this is 1 revolution/second.
  return speed * (PULSES_PER_REVOLUTION / 100.0f);
}

int directionSign(const String &dir) {
  const bool wantCw = (dir == "cw");
  if (POSITIVE_DIRECTION_IS_CW == 0) {
    return wantCw ? -1 : 1;
  }
  return wantCw ? 1 : -1;
}

void applyEnable(bool enabled) {
  digitalWrite(PIN_ENABLE, enabled ? LOW : HIGH);
}

void applyLight() {
  int duty = 0;
  if (lightOn) {
    duty = map(lightIntensity, 0, 100, 0, 255);
  }
  if (duty == lastDuty) {
    return;
  }
  lastDuty = duty;
#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcWrite(PIN_LED, duty);
#else
  ledcWrite(LEDC_CHANNEL, duty);
#endif
}

void logLine(const char *tag, const String &msg) {
  Serial.print('[');
  Serial.print(tag);
  Serial.print("] ");
  Serial.println(msg);
}

void sendJson(int code, const String &body) {
  logLine("HTTP", String(code) + " " + body);
  server.sendHeader("Connection", "close");
  server.send(code, "application/json", body);
}

void sendSuccess(const String &message) {
  DC_JSON_DOC(doc, 256);
  doc["success"] = true;
  doc["message"] = message;
  String out;
  serializeJson(doc, out);
  sendJson(200, out);
}

void sendFailure(int code, const String &error) {
  logLine("VALIDATE", error);
  DC_JSON_DOC(doc, 256);
  doc["success"] = false;
  doc["error"] = error;
  String out;
  serializeJson(doc, out);
  sendJson(code, out);
}

String readRequestBody() {
  if (server.hasArg("plain")) {
    return server.arg("plain");
  }
  return "";
}

bool readJsonBody(JsonDocument &doc, bool emptyObjectOk) {
  String contentType = server.header("Content-Type");
  if (contentType.length() == 0) {
    contentType = "(none)";
  }
  logLine("CONTENT-TYPE", contentType);
  String body = readRequestBody();
  body.trim();
  logLine("BODY", body.length() == 0 ? "(empty)" : body);
  if (body.length() == 0) {
    if (emptyObjectOk) {
      body = "{}";
    } else {
      sendFailure(400, "JSON body is required");
      return false;
    }
  }
  const DeserializationError err = deserializeJson(doc, body);
  if (err) {
    sendFailure(400, String("Invalid JSON: ") + err.c_str());
    return false;
  }
  return true;
}

void clearMotionTarget() {
  continuousMode = false;
  const long pos = stepper.currentPosition();
  stepper.setSpeed(0.0f);
  stepper.setCurrentPosition(pos);
  motorRunning = false;
}

void handleHealth() {
  logLine("REQ", "GET /health");
  DC_JSON_DOC(doc, 128);
  doc["ok"] = true;
  doc["healthy"] = true;
  String out;
  serializeJson(doc, out);
  sendJson(200, out);
}

void handleInfo() {
  logLine("REQ", "GET /info");
  DC_JSON_DOC(doc, 1536);
  doc["machineId"] = MACHINE_ID;
  doc["firmware"] = FIRMWARE_VERSION;
  doc["firmwareName"] = FIRMWARE_NAME;
  doc["identity"] = FIRMWARE_NAME;

  JsonObject motor = jsonObject(doc, "motor");
  motor["type"] = MOTOR_TYPE;
  motor["stepAngle"] = MOTOR_STEP_ANGLE_DEG;
  motor["fullStepsPerRevolution"] = FULL_STEPS_PER_REV;

  JsonObject mechanical = jsonObject(doc, "mechanical");
  mechanical["drive"] = "direct";
  mechanical["gearRatio"] = GEAR_RATIO;
  mechanical["gearbox"] = false;
  mechanical["pulley"] = false;

  JsonObject calibration = jsonObject(doc, "calibration");
  calibration["microsteps"] = MICROSTEPS;
  calibration["pulsesPerRevolution"] = PULSES_PER_REVOLUTION;
  calibration["stepsPerRevolution"] = PULSES_PER_REVOLUTION;
  calibration["stepsPerDegree"] = PULSES_PER_DEGREE;
  calibration["pulsesPerDegree"] = PULSES_PER_DEGREE;
  calibration["dm542"] = "SW1 ON, SW2 ON, SW3 OFF, SW4 ON, SW5 ON, SW6 ON, SW7 OFF, SW8 ON";
  calibration["dm542CurrentPeakA"] = 2.84;
  calibration["motorPhaseCurrentVerified"] = false;
  calibration["positiveDirectionIsCWUnconfirmed"] = true;
  // Physical CW from camera view is not confirmed. Do not set the bool.
  calibration["confirmed"] = false;
  calibration["note"] = "Pulse geometry is 3200 pulses/revolution (1/16). Physical CW direction unconfirmed. Commanded angle is not measured position. 2.84A peak is the DIP setting; motor phase-current rating is not verified.";

  JsonObject sensors = jsonObject(doc, "sensors");
  sensors["home"] = false;
  sensors["limit"] = false;
  sensors["encoder"] = false;

  String out;
  serializeJson(doc, out);
  sendJson(200, out);
}

void handleStatus() {
  logLine("REQ", "GET /status");
  DC_JSON_DOC(doc, 256);
  doc["connected"] = true;
  doc["rotation"] = commandedAngleDeg;
  doc["light"] = lightOn;
  doc["intensity"] = lightIntensity;
  doc["motorRunning"] = motorRunning;
  String out;
  serializeJson(doc, out);
  sendJson(200, out);
}

void handleRotate() {
  logLine("REQ", "POST /rotate");
  DC_JSON_DOC(doc, 256);
  if (!readJsonBody(doc, false)) {
    return;
  }
  if (!jsonHas(doc, "angle") || !jsonHas(doc, "speed")) {
    sendFailure(400, "angle and speed are required");
    return;
  }
  if (!jsonIsNumber(doc["angle"]) || !jsonIsNumber(doc["speed"])) {
    sendFailure(400, "angle and speed must be numeric");
    return;
  }
  const float angle = doc["angle"].as<float>();
  const float speed = doc["speed"].as<float>();
  if (isnan(angle) || isnan(speed) || isinf(angle) || isinf(speed)) {
    sendFailure(400, "angle and speed must be finite numbers");
    return;
  }
  if (angle < MIN_ANGLE_DEG || angle > MAX_ANGLE_DEG) {
    sendFailure(400, "angle must be 0..180");
    return;
  }
  if (speed < MIN_SPEED || speed > MAX_SPEED) {
    sendFailure(400, "speed must be 1..100");
    return;
  }

  const long targetPulses = angleToPulses(angle);
  const float maxSpeed = speedToPulsesPerSecond(speed);
  const long currentPosition = stepper.currentPosition();
  logLine("ROTATE", String("angle=") + angle);
  logLine("ROTATE", String("speed=") + speed);
  logLine("ROTATE", String("targetPulses=") + targetPulses);
  logLine("ROTATE", String("maxSpeed=") + maxSpeed);
  logLine("ROTATE", String("currentPosition=") + currentPosition);
  logLine("ROTATE", String("targetPosition=") + targetPulses);
  commandedAngleDeg = angle;
  continuousMode = false;
  applyEnable(true);
  stepper.setAcceleration(lastAcceleration);
  stepper.setMaxSpeed(maxSpeed);
  stepper.moveTo(targetPulses);
  motorRunning = stepper.distanceToGo() != 0;
  sendSuccess("Rotate command accepted (commanded angle, not measured position)");
}

void handleContinuous() {
  logLine("REQ", "POST /rotate/continuous");
  DC_JSON_DOC(doc, 256);
  if (!readJsonBody(doc, false)) {
    return;
  }
  if (!jsonHas(doc, "direction") || !jsonHas(doc, "speed")) {
    sendFailure(400, "direction and speed are required");
    return;
  }
  if (!doc["direction"].is<const char *>() && !doc["direction"].is<String>()) {
    sendFailure(400, "direction must be a string");
    return;
  }
  if (!jsonIsNumber(doc["speed"])) {
    sendFailure(400, "speed must be numeric");
    return;
  }
  String dir = doc["direction"].as<String>();
  dir.trim();
  dir.toLowerCase();
  if (dir != "cw" && dir != "ccw") {
    sendFailure(400, "direction must be cw or ccw");
    return;
  }
  const float speed = doc["speed"].as<float>();
  if (isnan(speed) || isinf(speed) || speed < MIN_SPEED || speed > MAX_SPEED) {
    sendFailure(400, "speed must be 1..100");
    return;
  }

  const int sign = directionSign(dir);
  const float pps = speedToPulsesPerSecond(speed);
  logLine("CONTINUOUS", String("direction=") + dir);
  logLine("CONTINUOUS", String("sign=") + sign);
  logLine("CONTINUOUS", String("speed=") + speed);
  logLine("CONTINUOUS", String("pulsesPerSec=") + pps);
  logLine("CONTINUOUS", "physicalCwUnconfirmed=true");
  continuousMode = true;
  applyEnable(true);
  stepper.setAcceleration(lastAcceleration);
  stepper.setMaxSpeed(pps);
  stepper.setSpeed(sign * pps);
  motorRunning = true;
  sendSuccess(dir == "cw" ? "Continuous CW accepted (physical CW unconfirmed)"
                          : "Continuous CCW accepted (physical CW unconfirmed)");
}

void handleStop() {
  logLine("REQ", "POST /rotate/stop");
  DC_JSON_DOC(doc, 256);
  if (!readJsonBody(doc, true)) {
    return;
  }
  clearMotionTarget();
  applyEnable(false);
  logLine("STOP", "continuousMode=false");
  logLine("STOP", "speed=0");
  logLine("STOP", String("distanceToGo=") + stepper.distanceToGo());
  logLine("STOP", "enable=HIGH (disabled, active-low)");
  logLine("STOP", "motorRunning=false");
  sendSuccess("Stopped");
}

void handleLight() {
  logLine("REQ", "POST /light");
  DC_JSON_DOC(doc, 256);
  if (!readJsonBody(doc, false)) {
    return;
  }
  if (!jsonHas(doc, "state") || !jsonHas(doc, "intensity")) {
    sendFailure(400, "state and intensity are required");
    return;
  }
  if (!jsonIsBool(doc["state"])) {
    sendFailure(400, "state must be boolean");
    return;
  }
  if (!jsonIsNumber(doc["intensity"])) {
    sendFailure(400, "intensity must be numeric");
    return;
  }
  const int intensity = doc["intensity"].as<int>();
  if (intensity < MIN_INTENSITY || intensity > MAX_INTENSITY) {
    sendFailure(400, "intensity must be 0..100");
    return;
  }
  lightOn = doc["state"].as<bool>() || doc["state"].as<int>() == 1;
  lightIntensity = intensity;
  const int duty = lightOn ? map(lightIntensity, 0, 100, 0, 255) : 0;
  applyLight();
  logLine("LIGHT", String("state=") + (lightOn ? "true" : "false"));
  logLine("LIGHT", String("intensity=") + lightIntensity);
  logLine("LIGHT", String("pwmDuty=") + duty);
  sendSuccess(lightOn ? "Light on" : "Light off");
}

void handleReset() {
  logLine("REQ", "POST /reset");
  DC_JSON_DOC(doc, 256);
  if (!readJsonBody(doc, true)) {
    return;
  }
  sendSuccess("Restarting");
  delay(80);
  ESP.restart();
}

void handleNotFound() {
  sendFailure(404, "Unknown endpoint");
}

void setupLedc() {
#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcAttach(PIN_LED, PWM_FREQ_HZ, PWM_RESOLUTION_BITS);
#else
  ledcSetup(LEDC_CHANNEL, PWM_FREQ_HZ, PWM_RESOLUTION_BITS);
  ledcAttachPin(PIN_LED, LEDC_CHANNEL);
#endif
  applyLight();
}

void setup() {
  Serial.begin(SERIAL_BAUD);
  delay(200);
  logLine("BOOT", String(FIRMWARE_NAME) + " firmware " + FIRMWARE_VERSION);
  logLine("BOOT", String("machineId=") + MACHINE_ID);
  logLine("BOOT", String("pulsesPerRevolution=") + PULSES_PER_REVOLUTION);
  logLine("BOOT", String("microsteps=") + MICROSTEPS);
  logLine("BOOT", String("pulsesPerDegree=") + String(PULSES_PER_DEGREE, 6));
  logLine("BOOT", "drive=direct fullSteps=200 stepAngle=1.8");
  logLine("BOOT", "calibration=unconfirmed physicalCw=unconfirmed");
  logLine("BOOT", "DM542 current DIP=2.84A peak; motor phase-current rating not verified");
  logLine("GPIO", "STEP=26 DIR=27 ENABLE=25 LIGHT=33");
  logLine("GPIO", "ENABLE LOW=enabled HIGH=disabled");

  pinMode(PIN_ENABLE, OUTPUT);
  applyEnable(false);
  setupLedc();

  stepper.setMaxSpeed(PULSES_PER_REVOLUTION);
  stepper.setAcceleration(lastAcceleration);
  stepper.setCurrentPosition(0);

  WiFi.persistent(false);
  WiFi.mode(WIFI_AP);
  WiFi.softAP(WIFI_SSID, WIFI_PASSWORD);
  const IPAddress ip = WiFi.softAPIP();
  logLine("WIFI", String("ap=") + WIFI_SSID + " ip=" + ip.toString() + " port=80");

  const char *headerKeys[] = {"Content-Type", "Content-Length"};
  server.collectHeaders(headerKeys, 2);

  server.on("/health", HTTP_GET, handleHealth);
  server.on("/info", HTTP_GET, handleInfo);
  server.on("/status", HTTP_GET, handleStatus);
  server.on("/rotate", HTTP_POST, handleRotate);
  server.on("/rotate/continuous", HTTP_POST, handleContinuous);
  server.on("/rotate/stop", HTTP_POST, handleStop);
  server.on("/light", HTTP_POST, handleLight);
  server.on("/reset", HTTP_POST, handleReset);
  server.onNotFound(handleNotFound);
  server.begin();
  logLine("HTTP", "server ready");
}

void loop() {
  server.handleClient();
  if (continuousMode) {
    stepper.runSpeed();
    motorRunning = true;
  } else {
    stepper.run();
    motorRunning = stepper.distanceToGo() != 0;
    if (!motorRunning) {
      applyEnable(false);
    }
  }
}
