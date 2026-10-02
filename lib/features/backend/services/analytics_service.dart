class AnalyticsService {
  const AnalyticsService();

  Future<void> logEvent({required String name, Map<String, Object?>? parameters}) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
  }
}
