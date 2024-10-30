import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:cash_scan/home.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AnimatedSplashScreen(
        backgroundColor: const Color.fromARGB(255, 255, 192, 83),
        duration: 9000,
        centered: true,
        splash: Stack(
          alignment: Alignment.center,
          children: [
            Lottie.asset('asset/splash.json'),
            Positioned(
              bottom: 0.0,
              child: Image.asset(
                'asset/logo.jpg',
                //height: 220,
                width: 250,
              ),
            ),
          ],
        ),
        splashIconSize: 650,
        nextScreen: const Home(),
      ),
    );
  }
}
