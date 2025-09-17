import 'package:flutter/material.dart';

/// Animation utilities for enhanced UI/UX
class AppAnimations {
  // Standard durations
  static const Duration ultraFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);
  static const Duration superSlow = Duration(milliseconds: 1200);

  // Standard curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve decelerate = Curves.decelerate;
  
  // Custom curves for mobile feel
  static const Curve materialCurve = Curves.fastOutSlowIn;
  static const Curve iosCurve = Curves.easeInOut;

  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = medium,
    Curve curve = easeInOut,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide in animation
  static Widget slideIn({
    required Widget child,
    Duration duration = medium,
    Curve curve = easeOut,
    Offset begin = const Offset(0, 1),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale animation
  static Widget scaleIn({
    required Widget child,
    Duration duration = medium,
    Curve curve = elasticOut,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Staggered list animation
  static Widget staggeredList({
    required List<Widget> children,
    Duration duration = medium,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Curve curve = easeOut,
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: duration + (staggerDelay * index),
          curve: curve,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: child,
        );
      }).toList(),
    );
  }

  /// Shimmer loading effect
  static Widget shimmer({
    required Widget child,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: duration,
      curve: Curves.linear,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (value - 1).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  /// Pulse animation
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      onEnd: () {
        // This would need to be implemented with AnimationController for continuous animation
      },
      child: child,
    );
  }

  /// Bounce animation
  static Widget bounce({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: Curves.bounceOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Rotation animation
  static Widget rotate({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159, // Full rotation
          child: child,
        );
      },
      child: child,
    );
  }

  /// Hero transition wrapper
  static Widget hero({
    required String tag,
    required Widget child,
    Duration duration = medium,
  }) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      child: child,
    );
  }

  /// Morphing container animation
  static Widget morphingContainer({
    required Widget child,
    required Duration duration,
    BorderRadius? borderRadius,
    Color? color,
    double? width,
    double? height,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Curve curve = materialCurve,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      child: child,
    );
  }

  /// Enhanced staggered list with better mobile performance
  static Widget enhancedStaggeredList({
    required List<Widget> children,
    Duration duration = medium,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Curve curve = materialCurve,
    Axis direction = Axis.vertical,
    double offset = 50.0,
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return AnimatedBuilder(
          animation: AlwaysStoppedAnimation(1.0),
          builder: (context, _) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: duration + (staggerDelay * index),
              curve: curve,
              builder: (context, value, child) {
                final slideOffset = direction == Axis.vertical
                    ? Offset(0, offset * (1 - value))
                    : Offset(offset * (1 - value), 0);
                
                return Transform.translate(
                  offset: slideOffset,
                  child: Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: child,
                    ),
                  ),
                );
              },
              child: child,
            );
          },
        );
      }).toList(),
    );
  }

  /// Parallax scroll effect
  static Widget parallax({
    required Widget child,
    required ScrollController scrollController,
    double rate = 0.5,
  }) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final offset = scrollController.hasClients 
            ? scrollController.offset * rate 
            : 0.0;
        
        return Transform.translate(
          offset: Offset(0, -offset),
          child: child,
        );
      },
    );
  }

  /// Elastic scale animation for mobile interactions
  static Widget elasticScale({
    required Widget child,
    Duration duration = medium,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = elasticOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Liquid swipe animation
  static Widget liquidSwipe({
    required Widget child,
    required Animation<double> animation,
    Color waveColor = Colors.blue,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return ClipPath(
          clipper: _LiquidSwipeClipper(animation.value),
          child: Container(
            color: waveColor,
            child: child,
          ),
        );
      },
    );
  }

  /// Breathing animation for attention-grabbing elements
  static Widget breathing({
    required Widget child,
    Duration duration = const Duration(milliseconds: 2000),
    double minScale = 0.98,
    double maxScale = 1.02,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      onEnd: () {
        // This creates a continuous breathing effect
        // In a real implementation, this would use AnimationController
      },
      child: child,
    );
  }
}

/// Liquid swipe clipper for advanced transitions
class _LiquidSwipeClipper extends CustomClipper<Path> {
  final double progress;

  _LiquidSwipeClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final waveHeight = size.height * 0.2;
    final waveWidth = size.width * progress;

    path.moveTo(0, 0);
    path.lineTo(waveWidth - waveHeight, 0);
    
    // Create liquid wave effect
    path.quadraticBezierTo(
      waveWidth, 
      waveHeight, 
      waveWidth + waveHeight, 
      size.height * 0.5,
    );
    
    path.quadraticBezierTo(
      waveWidth, 
      size.height - waveHeight, 
      waveWidth - waveHeight, 
      size.height,
    );
    
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

/// Custom page transitions optimized for mobile
class CustomPageTransitions {
  /// iOS-style slide transition
  static PageRouteBuilder iosSlideTransition({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.medium,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        
        final slideAnimation = animation.drive(
          Tween(begin: begin, end: end).chain(
            CurveTween(curve: AppAnimations.iosCurve),
          ),
        );
        
        final secondarySlideAnimation = secondaryAnimation.drive(
          Tween(begin: Offset.zero, end: const Offset(-0.3, 0.0)).chain(
            CurveTween(curve: AppAnimations.iosCurve),
          ),
        );
        
        return Stack(
          children: [
            SlideTransition(
              position: secondarySlideAnimation,
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
            SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          ],
        );
      },
    );
  }

  /// Material design slide transition
  static PageRouteBuilder materialSlideTransition({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.medium,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: begin, end: end).chain(
              CurveTween(curve: AppAnimations.materialCurve),
            ),
          ),
          child: child,
        );
      },
    );
  }

  /// Slide transition (legacy support)
  static PageRouteBuilder slideTransition({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.medium,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
  }) {
    return materialSlideTransition(
      page: page,
      settings: settings,
      duration: duration,
      begin: begin,
      end: end,
    );
  }

  /// Fade transition
  static PageRouteBuilder fadeTransition({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.medium,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Scale transition
  static PageRouteBuilder scaleTransition({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.medium,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween(begin: begin, end: end).chain(
              CurveTween(curve: Curves.elasticOut),
            ),
          ),
          child: child,
        );
      },
    );
  }

  /// Bottom sheet style transition
  static PageRouteBuilder bottomSheetTransition({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.medium,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        
        final slideAnimation = animation.drive(
          Tween(begin: begin, end: end).chain(
            CurveTween(curve: AppAnimations.materialCurve),
          ),
        );
        
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Shared element transition
  static PageRouteBuilder sharedElementTransition({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.medium,
    String? heroTag,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: AppAnimations.materialCurve),
          ),
          child: ScaleTransition(
            scale: animation.drive(
              Tween(begin: 0.8, end: 1.0).chain(
                CurveTween(curve: AppAnimations.materialCurve),
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Morphing transition for related content
  static PageRouteBuilder morphingTransition({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.slow,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: AppAnimations.elasticOut),
          ),
        );
        
        final rotationAnimation = animation.drive(
          Tween(begin: 0.1, end: 0.0).chain(
            CurveTween(curve: AppAnimations.materialCurve),
          ),
        );
        
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Transform.rotate(
            angle: rotationAnimation.value,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Custom transition combining multiple effects
  static PageRouteBuilder customTransition({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.medium,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: AppAnimations.materialCurve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Zoom transition for modal presentations
  static PageRouteBuilder zoomTransition({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.medium,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: AppAnimations.materialCurve),
          ),
        );
        
        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

/// Micro-interaction widgets
class MicroInteractions {
  /// Tap feedback with scale animation
  static Widget tapFeedback({
    required Widget child,
    required VoidCallback onTap,
    double scaleDown = 0.95,
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return _TapFeedbackWidget(
      onTap: onTap,
      scaleDown: scaleDown,
      duration: duration,
      child: child,
    );
  }

  /// Hover effect for web/desktop
  static Widget hoverEffect({
    required Widget child,
    double scale = 1.05,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return _HoverEffectWidget(
      scale: scale,
      duration: duration,
      child: child,
    );
  }

  /// Ripple effect
  static Widget rippleEffect({
    required Widget child,
    required VoidCallback onTap,
    Color? rippleColor,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: rippleColor?.withOpacity(0.3),
        highlightColor: rippleColor?.withOpacity(0.1),
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}

/// Tap feedback widget implementation
class _TapFeedbackWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;
  final Duration duration;

  const _TapFeedbackWidget({
    required this.child,
    required this.onTap,
    required this.scaleDown,
    required this.duration,
  });

  @override
  State<_TapFeedbackWidget> createState() => _TapFeedbackWidgetState();
}

class _TapFeedbackWidgetState extends State<_TapFeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Hover effect widget implementation
class _HoverEffectWidget extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;

  const _HoverEffectWidget({
    required this.child,
    required this.scale,
    required this.duration,
  });

  @override
  State<_HoverEffectWidget> createState() => _HoverEffectWidgetState();
}

class _HoverEffectWidgetState extends State<_HoverEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}