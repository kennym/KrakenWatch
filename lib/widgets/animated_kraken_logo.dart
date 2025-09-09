import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimatedKrakenLogo extends StatefulWidget {
  final double width;
  final double height;
  final bool autoPlay;
  final String? animationName;

  const AnimatedKrakenLogo({
    super.key,
    this.width = 40,
    this.height = 40,
    this.autoPlay = true,
    this.animationName,
  });

  @override
  State<AnimatedKrakenLogo> createState() => _AnimatedKrakenLogoState();
}

class _AnimatedKrakenLogoState extends State<AnimatedKrakenLogo>
    with TickerProviderStateMixin {
  late RiveAnimationController _riveController;
  late AnimationController _fallbackController;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isRiveLoaded = false;
  bool _useRive = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.animationName != null) {
      _riveController = SimpleAnimation(widget.animationName!, autoplay: widget.autoPlay);
    } else {
      _riveController = SimpleAnimation('idle', autoplay: widget.autoPlay);
    }

    // Setup fallback animations
    _fallbackController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _floatAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _fallbackController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _fallbackController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _fallbackController,
      curve: Curves.elasticInOut,
    ));

    if (widget.autoPlay) {
      _fallbackController.repeat(reverse: true);
    }
  }

  void _onRiveInit(Artboard artboard) {
    setState(() {
      _isRiveLoaded = true;
      _useRive = true;
    });
  }

  @override
  void dispose() {
    _riveController.dispose();
    _fallbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _useRive ? _buildRiveAnimation() : _buildFallbackAnimation(),
    );
  }

  Widget _buildRiveAnimation() {
    return Stack(
      children: [
        // Show loading indicator while Rive is loading
        if (!_isRiveLoaded)
          Center(
            child: SizedBox(
              width: widget.width * 0.3,
              height: widget.height * 0.3,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        // Rive animation
        RiveAnimation.asset(
          'assets/animations/kraken_logo.riv',
          controllers: [_riveController],
          onInit: _onRiveInit,
          fit: BoxFit.contain,
          antialiasing: true,
        ),
      ],
    );
  }

  Widget _buildFallbackAnimation() {
    return AnimatedBuilder(
      animation: _fallbackController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: SvgPicture.asset(
                'assets/images/kraken_logo.svg',
                width: widget.width,
                height: widget.height,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void playAnimation([String? animationName]) {
    if (_useRive) {
      if (animationName != null) {
        _riveController.dispose();
        _riveController = SimpleAnimation(animationName, autoplay: true);
      } else {
        if (_riveController is SimpleAnimation) {
          (_riveController as SimpleAnimation).isActive = true;
        }
      }
    } else {
      _fallbackController.forward();
    }
  }

  void pauseAnimation() {
    if (_useRive) {
      if (_riveController is SimpleAnimation) {
        (_riveController as SimpleAnimation).isActive = false;
      }
    } else {
      _fallbackController.stop();
    }
  }
}