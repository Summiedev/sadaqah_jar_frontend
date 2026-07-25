import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
  );
  late final Animation<double> _rise = Tween<double>(begin: 24, end: 0).animate(
    CurvedAnimation(parent: _controller, curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic)),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F150E), // Luxurious dark brown background
      body: Stack(
        children: [
          // Elegant top accent line
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 70),
              child: SizedBox(
                width: 48,
                height: 1.2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x26E7DFCF),
                  ),
                ),
              ),
            ),
          ),
          
          // Main brand contents
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final floatOffset = math.sin(_controller.value * math.pi) * 2;
                return Opacity(
                  opacity: _fade.value,
                  child: Transform.translate(
                    offset: Offset(0, _rise.value + floatOffset),
                    child: Transform.scale(
                      scale: _scale.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Actual Mizan logo
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(44),
                      border: Border.all(color: const Color(0x11E7DFCF), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(44),
                      child: SvgPicture.asset(
                        'lib/assets/images/mizan_logo.svg',
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 38),
                  
                  // Brand Name MIZAN
                  const Text(
                    'M I Z A N',
                    style: TextStyle(
                      fontSize: 34,
                      letterSpacing: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFE7DFCF),
                      fontFamily: 'serif', // Elegant serif rendering
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Arabic Subtitle "ميزان"
                  Text(
                    'ميزان',
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFE7DFCF).withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Elegant Bottom Tagline
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 56),
              child: Text(
                'THE BEAUTY OF CONSTANCY',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 4.5,
                  color: const Color(0xFFE7DFCF).withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
