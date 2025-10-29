import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:pipemantra/utils/color_constants.dart';
import 'package:pipemantra/utils/media_query_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  bool _showText = false;

  @override
  void initState() {
    super.initState();

    // Rotation controller
    _rotationController = AnimationController(
      vsync: this,
      duration:  Duration(milliseconds: 700),
    );

    // Animate 0° → 180°
    _rotationAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    // Start rotation
    _rotationController.forward().whenComplete(() async {
      setState(() => _showText = true);

      // 👇 Optional navigation delay
      // await Future.delayed(const Duration(seconds: 2));
      // context.pushReplacement('/dashboard');
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primarycolor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔄 Rotating logo
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: child,
                );
              },
              child: Image.asset(width: SizeConfig.screenWidth*0.8,height: SizeConfig.screenHeight*0.25,
                "assets/logo/pipe-m-logo.png",
              ),
            ),
            if (_showText)
              FadeIn(
                duration: const Duration(milliseconds: 650),
                child: Text(
                  "Pipemantra",
                  style: TextStyle(
                    color: textTittleColor,
                    fontSize: 48,
                    fontFamily: "Orbitron",
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
