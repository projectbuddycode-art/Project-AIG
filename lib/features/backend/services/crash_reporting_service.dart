class CrashReportingService {
  const CrashReportingService();

  Future<void> recordError(Object error, {StackTrace? stackTrace}) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
  }

  Future<void> setUserIdentifier(String? identifier) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
  }
}
