import 'package:flutter/material.dart';

class CustomPageScrollPhysics extends PageScrollPhysics {
  const CustomPageScrollPhysics({super.parent});

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (velocity.abs() < toleranceFor(position).velocity) {
      return super.createBallisticSimulation(position, velocity);
    }

    final currentPage = position.pixels / position.viewportDimension;

    final pagesToMove = (velocity / 1300).round();

    final targetPage = (currentPage + pagesToMove).clamp(
      0,
      position.maxScrollExtent / position.viewportDimension,
    );

    return ScrollSpringSimulation(
      const SpringDescription(mass: 0.7, stiffness: 2000, damping: 150),
      position.pixels,
      targetPage * position.viewportDimension,
      velocity,
      tolerance: toleranceFor(position),
    );
  }
}
