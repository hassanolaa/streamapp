import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:streamapp/core/di/service_locator.dart' as di;
import 'package:streamapp/core/theme/app_theme.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await GetStorage.init();
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
      home:  Scaffold(
        body: Center(
          child: Text('AppTitle'.tr()),
        ),
      ),
    );
  }
}

