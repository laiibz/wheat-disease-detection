import 'package:workmanager/workmanager.dart';
import 'news_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Native Background Task Running: $task");
    try {
      // 1. Initialize Notifications for the background process
      await NotificationService.init();

      // 2. Fetch fresh news
      final newsService = NewsService();
      final articles = await newsService.fetchAgriNews();

      if (articles.isNotEmpty) {
        print("Background News Found: ${articles[0].title}");
        // 3. Show notification with the latest headline and URL payload
        await NotificationService.showNotification(
          id: 999,
          title: "🗞️ WheatGuard Live Update",
          body: articles[0].title,
          payload: articles[0].url,
        );
      }
      return Future.value(true);
    } catch (e) {
      print("Background Task Error: $e");
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true if you want to see detailed Android logs
    );
  }

  static Future<void> scheduleDailyNewsTask() async {
    await Workmanager().registerPeriodicTask(
      "daily_news_task",
      "fetch_daily_news",
      frequency: const Duration(minutes: 15), // Minimum allowed for testing
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
