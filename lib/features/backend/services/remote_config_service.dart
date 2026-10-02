class RemoteConfigService {
  const RemoteConfigService();

  Future<bool> boolValue({required String key, bool defaultValue = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return defaultValue;
  }

  Future<String> stringValue({required String key, String defaultValue = ''}) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return defaultValue;
  }
}
