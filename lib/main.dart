import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/injection.dart';
import 'app.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// ─── Supabase credentials ──────────────────────────────────────────────────
// Replace with your actual Supabase project URL and anon key.
const supabaseUrl = 'https://wnlcdevsrqipzzqtmjos.supabase.co';
const supabaseAnonKey = 'sb_publishable_Tol2w4lzcK3FT8jK82hf5Q_7Lbigtb5';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Register all dependencies
  await setupDependencies();

  // Use path URL strategy for web (removes the # from URL)
  usePathUrlStrategy();

  runApp(QuizzoApp());
}
