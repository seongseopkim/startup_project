import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'app.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => UserProvider()),
  ], child: MyApp()));
}
