import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:medisync_app/global/theme/app_theme.dart';

class LoadingWidget extends StatefulWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔄 Animated Gradient Spinner
          AnimatedBuilder(
            animation: _controller,
            builder: (_, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: child,
              );
            },
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.2),
                    AppColors.primary,
                  ],
                ),
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ✨ Pulse Text
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.05),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            onEnd: () {
              setState(() {});
            },
            child: Text(
              widget.message ?? "Please wait...",
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        if (isLoading)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isLoading ? 1 : 0,
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: LoadingWidget(message: message),
            ),
          ),
      ],
    );
  }
}