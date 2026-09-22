import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../core/theme/app_colors.dart';

class AppLoading extends StatelessWidget {
  final Color? color;
  final double size;

  const AppLoading({
    super.key,
    this.color,
    this.size = 24.0,
  });

  /// Standard two rotating arc loading indicator requested for dropdowns and pickers
  static Widget twoRotatingArc({Color? color, double size = 20.0}) {
    return LoadingAnimationWidget.twoRotatingArc(
      color: color ?? AppColors.primary,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.twoRotatingArc(
        color: color ?? AppColors.primary,
        size: size,
      ),
    );
  }
}
