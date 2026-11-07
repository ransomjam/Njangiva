import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean URLs without the '/#/' hash on Flutter Web
  usePathUrlStrategy();

  runApp(const ProviderScope(child: NjangiSaveApp()));
}
