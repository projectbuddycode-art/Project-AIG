# DiamondCam firmware 2.1.0

Authoritative sketch: `firmware/DiamondCam/DiamondCam.ino`

Local LAN machine controller only. No cloud. Wi-Fi password is never returned by HTTP.

## Wiring / GPIO

| Signal | ESP32 GPIO | Notes |
|--------|------------|--------|
| STEP | 26 | DM542 PUL |
| DIR | 27 | DM542 DIR |
| ENABLE | 25 | DM542 ENA, active LOW |
| LIGHT PWM | 33 | Single lighting channel |
| GND | GND | Common with DM542 |

## Stepper / drive

- NEMA17, 1.8°/full step, 200 full steps/revolution
- Direct drive (no gearbox, no pulley)
- DM542 DIP (as documented by hardware builder):

| Switch | Setting |
|--------|---------|
| SW1 | ON |
| SW2 | ON |
| SW3 | ON |
| SW4 | OFF |
| SW5 | OFF |
| SW6 | OFF |
| SW7 | ON |
| SW8 | ON |

- 400 pulses/revolution
- 1/2 microstep
- 1.111111 pulses/degree (`400 / 360`)

There is no HOME sensor, no limit sensor, and no encoder.
`rotation` in `/status` is **commanded angle**, not measured physical position.

Physical camera-side CW is **not confirmed**. Firmware `calibration.confirmed` is **false**.

## Wi-Fi / HTTP

- SSID: `DiamondCam_Device`
- Password: `12345678` (station config only; not in API JSON)
- IP: `192.168.4.1`
- Port: 80
- Machine ID: `AIG-DIAMONDCAM` (not the IP)

## API

| Method | Path | Body | Success | Failure |
|--------|------|------|---------|---------|
| GET | `/health` | — | `{ok,healthy}` | |
| GET | `/info` | — | identity, motor, mechanical, calibration, sensors | |
| GET | `/status` | — | `{connected,rotation,light,intensity,motorRunning}` | |
| POST | `/rotate` | `{angle,speed}` | `{success:true,message}` | HTTP 4xx `{success:false,error}` |
| POST | `/rotate/continuous` | `{direction:"cw"\|"ccw",speed}` | `{success:true,message}` | HTTP 4xx `{success:false,error}` |
| POST | `/rotate/stop` | `{}` | `{success:true,message}` | |
| POST | `/light` | `{state,intensity}` | `{success:true,message}` | HTTP 4xx `{success:false,error}` |
| POST | `/reset` | `{}` | `{success:true,message}` then restart | |

Ranges (match current Flutter contract):

- angle: 0..180 (app slider is 0–180; firmware rejects out of range)
- speed: 1..100
- intensity: 0..100
- direction: exactly `cw` or `ccw`

Speed 100 = 400 pulses/s = 1 revolution/s.

CW and CCW apply opposite signed `stepper.setSpeed()`. STOP clears continuous mode, zeros speed, and sets target = current position.

No `/home` endpoint. HOME remains unavailable.

## Flash (Arduino IDE)

1. Install **ArduinoJson** and **AccelStepper**.
2. Board: **ESP32 Dev Module** (ESP32-WROOM-32).
3. Open `firmware/DiamondCam/DiamondCam.ino`.
4. Port: the ESP32 USB COM port.
5. Upload.
6. Serial Monitor 115200 baud: confirm boot, AP IP, `ppr=400`.

## Flash (arduino-cli, if installed)

```
arduino-cli compile --fqbn esp32:esp32:esp32 firmware/DiamondCam
arduino-cli upload -p COMx --fqbn esp32:esp32:esp32 firmware/DiamondCam
```

## Physical calibration checklist (not complete)

Do **not** mark calibration confirmed until all of these pass on the real machine:

- [ ] ESP32 boots, AP `DiamondCam_Device`, phone gets `192.168.4.x`
- [ ] GET `/health`, `/info`, `/status` succeed
- [ ] `/info` shows 400 pulses/rev, microsteps 2, `confirmed: false`
- [ ] Light GPIO 33 on/off and intensity
- [ ] CW command turns the camera-side view clockwise (or invert `POSITIVE_DIRECTION_IS_CW`)
- [ ] CCW is the opposite direction
- [ ] STOP actually stops and does not resume
- [ ] Commanded 90° is approximately 90° physically
- [ ] Commanded 180° is approximately 180° physically

Until those physical checks pass: **Calibration = Unconfirmed**.
