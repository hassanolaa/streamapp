import 'dart:io';

class AppConfig {
  // Tuber JAR path configuration
  static String getTuberJarPath() {
    // Check environment variable first
    final envPath = Platform.environment['TUBER_JAR_PATH'];
    if (envPath != null && envPath.isNotEmpty) {
      return envPath;
    }

    // Default paths based on platform
    if (Platform.isLinux) {
      return '/home/hassanola/flutterProjects/streamapp/tuber/tuber.jar'; // Or wherever you install it
    } else if (Platform.isMacOS) {
      return '/usr/local/bin/tuber.jar';
    } else if (Platform.isWindows) {
      return 'C:\\Program Files\\tuber\\tuber.jar';
    }

    // Fallback to current directory
    return './tuber.jar';
  }


    // Get Java path (for compatibility with Tuber)
  static String? getJavaPath() {
    // First, try SDKMAN current Java (your terminal setup)
    const sdkmanPath = '/home/hassanola/.sdkman/candidates/java/current/bin/java';
    if (File(sdkmanPath).existsSync()) {
      print('Using SDKMAN Java: $sdkmanPath');
      return sdkmanPath;
    }

    // Check environment variable (usually not available in Flutter)
    final envPath = Platform.environment['JAVA_HOME'];
    if (envPath != null && envPath.isNotEmpty) {
      final javaExec = '$envPath/bin/java';
      if (File(javaExec).existsSync()) {
        print('Using JAVA_HOME: $javaExec');
        return javaExec;
      }
    }

    // Try to find Java 21+ in common Linux locations
    final possiblePaths = [
      '/usr/lib/jvm/java-25-openjdk-amd64/bin/java',
      '/usr/lib/jvm/java-23-openjdk-amd64/bin/java',
      '/usr/lib/jvm/java-21-openjdk-amd64/bin/java',
      '/usr/lib/jvm/default-java/bin/java',
    ];

    for (final path in possiblePaths) {
      if (File(path).existsSync()) {
        print('Using system Java: $path');
        return path;
      }
    }

    print('Using default system Java');
    return null; // Use system default
  }


  // You can add other app configurations here
  static const String appName = 'Stream App';
  static const String appVersion = '1.0.0';
}
