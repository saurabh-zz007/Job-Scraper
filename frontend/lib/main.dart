import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/config/env_config.dart';
import 'core/routes/app_pages.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.init();
  runApp(const JobIoApp());
}

class JobIoApp extends StatelessWidget {
  const JobIoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Job.io — Tech Jobs Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
    );
  }
}

// Backward compatibility alias for tests
typedef TalentStreamApp = JobIoApp;
