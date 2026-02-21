import 'dart:io';

class AppConfig {
  // Tuber binary path configuration
  static String getTuberPath() {
    // Check environment variable first
    final envPath = Platform.environment['TUBER_PATH'];
    if (envPath != null && envPath.isNotEmpty) {
      return envPath;
    }

    // Default paths based on platform
    if (Platform.isLinux) {
      return '/home/hassanola/flutterProjects/streamapp/tuber/bin/tuber';
    } else if (Platform.isMacOS) {
      return '/usr/local/bin/tuber';
    } else if (Platform.isWindows) {
      return 'C:\\Program Files\\tuber\\bin\\tuber.bat';
    }

    // Fallback to PATH
    return 'tuber';
  }

  // Get Java home directory (for tuber binary environment)
  static String? getJavaHome() {
    // First, try SDKMAN current Java (your terminal setup)
    const sdkmanPath = '/home/hassanola/.sdkman/candidates/java/current';
    if (Directory(sdkmanPath).existsSync()) {
      print('Using SDKMAN Java: $sdkmanPath');
      return sdkmanPath;
    }

    // Check environment variable
    final envPath = Platform.environment['JAVA_HOME'];
    if (envPath != null && envPath.isNotEmpty && Directory(envPath).existsSync()) {
      print('Using JAVA_HOME: $envPath');
      return envPath;
    }

    // Try to find Java 21+ in common Linux locations
    final possiblePaths = [
      '/usr/lib/jvm/java-25-openjdk-amd64',
      '/usr/lib/jvm/java-23-openjdk-amd64',
      '/usr/lib/jvm/java-21-openjdk-amd64',
      '/usr/lib/jvm/default-java',
    ];

    for (final path in possiblePaths) {
      if (Directory(path).existsSync()) {
        print('Using system Java: $path');
        return path;
      }
    }

    print('No specific JAVA_HOME found, using system default');
    return null;
  }

  // You can add other app configurations here
  static const String appName = 'Stream App';
  static const String appVersion = '1.0.0';
}
