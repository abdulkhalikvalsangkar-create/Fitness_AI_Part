import 'package:flutter/material.dart';
import 'dart:ui';

class FakeGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final List<Color>? colors;

  const FakeGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 30,
    this.padding,
    this.height,
    this.width,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final gradientcolors =
        colors ??
        [
          // Colors.white.withOpacity(0.10),
          // Colors.white.withOpacity(0.03),
          const Color(0xFF6C4AB6).withOpacity(0.12), // soft purple tint
          const Color(0xFF3A2C5A).withOpacity(0.08),
        ];
    return Container(
      height: height,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientcolors,
        ),
        border: Border.all(
          // color: Colors.white.withOpacity(0.25),
          color: const Color(0xFFB39DDB).withOpacity(0.25),
          width: 1,
        ),

        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.5),
        //     blurRadius: 40,
        //     offset: Offset(0, 20),
        //   ),
        // ],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: const Color(0xFF7E57C2).withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
      ),
      child: child,
    );
  }
}

// Another way

// class GlassContainer extends StatelessWidget {
//   final Widget child;
//   final EdgeInsets? padding;
//   final BorderRadius? borderRadius;
//   final List<Color>? colors;

//   const GlassContainer({
//     Key? key,
//     required this.child,
//     this.padding,
//     this.borderRadius,
//     this.colors,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: padding ?? const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         borderRadius: borderRadius ?? BorderRadius.circular(12),
//         gradient: LinearGradient(
//           colors:
//               colors ??
//               [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.15)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
//       ),
//       child: child,
//     );
//   }
// }

Widget glassCard({required Widget child}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: child,
      ),
    ),
  );
}
