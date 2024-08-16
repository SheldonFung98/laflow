import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:particles_flutter/component/particle/particle.dart';
import 'package:particles_flutter/particles_engine.dart';
import 'dart:math';

class Background extends StatelessWidget {
  final Widget? child;

  const Background({
    Key? key,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 172, 182, 184), // End color
              Color.fromARGB(255, 95, 126, 144), // End color
            ],
          ),
        ),
        child: Particles(
          awayRadius: 50,
          particles: createParticles(),
          height: screenHeight,
          width: screenWidth,
          onTapAnimation: false,
          awayAnimationDuration: const Duration(milliseconds: 100),
          awayAnimationCurve: Curves.decelerate,
          enableHover: false,
          hoverRadius: 90,
          connectDots: true,
        ),
      ),
      this.child ?? Container(),
    ]);
  }

  List<Particle> createParticles() {
    var rng = Random();
    List<Particle> particles = [];
    for (int i = 0; i < 30; i++) {
      particles.add(Particle(
        color: Colors.white.withOpacity(0.3),
        size: rng.nextDouble() * 10,
        velocity: Offset(rng.nextDouble() * 20 * randomSign(),
            rng.nextDouble() * 20 * randomSign()),
      ));
    }
    return particles;
  }

  double randomSign() {
    var rng = Random();
    return rng.nextBool() ? 1 : -1;
  }
}
