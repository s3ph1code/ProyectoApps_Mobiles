import 'package:flutter/material.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/auth_sandbox_page.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await initDependencies();
  runApp(const DoulappApp());
}

class DoulappApp extends StatelessWidget {
  const DoulappApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doulapp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthSandboxPage(),
    );
  }
}
