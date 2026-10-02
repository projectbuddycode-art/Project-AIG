class NotificationService {
  const NotificationService();

  Future<void> requestPermission() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Future<String?> getDeviceToken() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return null;
  }

  Future<void> subscribeToTopic({required String topic}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }
}
