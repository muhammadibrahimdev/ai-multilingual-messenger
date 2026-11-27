/// Route paths used across the app.
abstract final class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String newChat = '/new-chat';
  static const String settings = '/settings';
  static const String chat = '/chat/:conversationId';

  static String chatPath(String conversationId) => '/chat/$conversationId';
}
