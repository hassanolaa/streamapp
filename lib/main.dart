import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:streamapp/core/di/service_locator.dart' as di;
import 'package:streamapp/core/theme/app_theme.dart';
import 'package:streamapp/features/home/presentation/pages/navigation_shell.dart';
import 'package:streamapp/features/videos/data/datasources/videos_remote_data_source.dart';
import 'package:streamapp/test_videos_page.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await GetStorage.init();

 final process = await Process.start(
  "printenv",
  ["PATH"],
  runInShell: true,
);

// Read stdout
final stdoutString = await process.stdout.transform(utf8.decoder).join();

// Read stderr
final stderrString = await process.stderr.transform(utf8.decoder).join();

// Wait for exit
final exitCode = await process.exitCode;

if (exitCode != 0) {
  print('❌ Exit code: $exitCode');
  print('stderr: $stderrString');
  throw TuberException(stderrString);
}

print('✅ tuber is accessible:\n$stdoutString');


  di.setupLocator();
  
  

  runApp(EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations', 
    // startLocale: Locale('ar'),                                                                                                                                                                                                                                           
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ), );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stream App',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
     // home:  const TestVideosPage()
      home: const NavigationShell(),
    );
  }
}

