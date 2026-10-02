/// Single authoritative DiamondCam HTTP contract.
///
/// All machine HTTP paths and payload shapes must come from here.
class DiamondCamProtocol {
  DiamondCamProtocol._();

  static const String wifiSsid = 'DiamondCam_Device';
  static const String wifiPasswordHint = '12345678';
  static const String defaultHost = '192.168.4.1';
  static const int defaultPort = 80;
  static const String defaultScheme = 'http';

  static const String healthPath = '/health';
  static const String infoPath = '/info';
  static const String statusPath = '/status';
  static const String rotatePath = '/rotate';
  static const String rotateContinuousPath = '/rotate/continuous';
  static const String rotateStopPath = '/rotate/stop';
  static const String lightPath = '/light';
  static const String resetPath = '/reset';

  static const String directionCw = 'cw';
  static const String directionCcw = 'ccw';

  /// DM542 DIP SW5–SW8 = ON ON OFF ON → 3200 pulses/rev, 1/16 microstep.
  /// Physical CW is not confirmed by this constant.
  static const int fullStepsPerRevolution = 200;
  static const int microsteps = 16;
  static const int pulsesPerRevolution = 3200;
  static const double pulsesPerDegree = pulsesPerRevolution / 360;

  /// Whole numbers are encoded as JSON integers so the body is not a quoted string.
  static Object jsonNumber(num value) {
    if (value == value.roundToDouble()) {
      return value.round();
    }
    return value;
  }

  static const Set<String> requiredStatusKeys = {
    'connected',
    'rotation',
    'light',
    'intensity',
    'motorRunning',
  };

  /// Known aliases from older sketches. Canonical names remain required after mapping.
  static const Map<String, String> statusKeyAliases = {
    'motor_running': 'motorRunning',
    'motor-running': 'motorRunning',
    'isConnected': 'connected',
    'is_connected': 'connected',
    'lightOn': 'light',
    'light_on': 'light',
    'commandedAngle': 'rotation',
    'commanded_angle': 'rotation',
  };

  static Map<String, Object> rotateBody({required num angle, required num speed}) => {
        'angle': jsonNumber(angle),
        'speed': jsonNumber(speed),
      };

  static Map<String, Object> continuousBody({required String direction, required num speed}) => {
        'direction': direction,
        'speed': jsonNumber(speed),
      };

  static Map<String, Object> lightBody({required bool state, required int intensity}) => {
        'state': state,
        'intensity': intensity,
      };

  static bool isContinuousDirection(String value) {
    final dir = value.trim().toLowerCase();
    return dir == directionCw || dir == directionCcw;
  }
}

enum MachineCommandStage {
  notSent,
  transportFailure,
  httpError,
  invalidJson,
  rejected,
  accepted,
  physicalUnverified,
}
