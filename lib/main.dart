import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ytm_downloader_gui',
          theme: ThemeData(
            colorScheme: lightDynamic ??
                ColorScheme.fromSeed(
                    seedColor: Colors.blue, brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ??
                ColorScheme.fromSeed(
                    seedColor: Colors.blue, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          home: const AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
            child: Home(),
          ),
        );
      },
    );
  }
}
