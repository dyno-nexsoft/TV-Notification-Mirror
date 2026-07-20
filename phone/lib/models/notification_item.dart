class NotificationItem {
  final String id;
  final String packageName;
  final String title;
  final String text;
  final int postTime;

  NotificationItem({
    required this.id,
    required this.packageName,
    required this.title,
    required this.text,
    required this.postTime,
  });

  factory NotificationItem.fromMap(Map<dynamic, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      packageName: map['packageName'] ?? '',
      title: map['title'] ?? '',
      text: map['text'] ?? '',
      postTime: map['postTime'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': getAppName(packageName),
      'title': title,
      'text': text,
      'postTime': postTime,
    };
  }

  static String getAppName(String pkg) {
    switch (pkg) {
      case 'com.whatsapp':
        return 'WhatsApp';
      case 'com.facebook.orca':
        return 'Messenger';
      case 'org.telegram.messenger':
        return 'Telegram';
      case 'com.viber.voip':
        return 'Viber';
      case 'com.android.mms':
      case 'com.google.android.apps.messaging':
        return 'Messages';
      case 'com.google.android.gm':
        return 'Gmail';
      case 'com.facebook.katana':
        return 'Facebook';
      case 'com.instagram.android':
        return 'Instagram';
      case 'com.zing.zalo':
        return 'Zalo';
      default:
        // Return capitalized last part of package as fallback
        try {
          return pkg.split('.').last.toUpperCase();
        } catch (_) {
          return pkg;
        }
    }
  }
}
