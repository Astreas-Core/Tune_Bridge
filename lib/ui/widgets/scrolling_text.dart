import 'dart:async';
import 'package:flutter/material.dart';

class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double pauseDuration;
  final double velocity;

  const ScrollingText({
    super.key,
    required this.text,
    this.style,
    this.pauseDuration = 2.0,
    this.velocity = 30.0,
  });

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  Timer? _pauseTimer;

  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ScrollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _resetScroll();
    }
  }

  void _resetScroll() {
     if (!mounted) return;
    _pauseTimer?.cancel();
    _scrollController.jumpTo(0);
    _animationController.stop();
    _startScrolling();
  }

  void _startScrolling() {
    if (!mounted) return;
    // Wait for layout to determine if scrolling is needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        
        _isScrolling = true;
        
        // Initial Pause
        _pauseTimer = Timer(Duration(seconds: widget.pauseDuration.toInt()), () {
           if (!mounted) return;
           final maxScroll = _scrollController.position.maxScrollExtent;
           final duration = Duration(milliseconds: (maxScroll / widget.velocity * 1000).toInt());

           _animationController.duration = duration;
           
           // Animate to end
           _scrollController.animateTo(
             maxScroll, 
             duration: duration, 
             curve: Curves.linear
           ).then((_) {
              // Pause at end
              if (!mounted) return;
              _pauseTimer = Timer(Duration(seconds: widget.pauseDuration.toInt()), () {
                  if (!mounted) return;
                  // Jump back to start and repeat
                  _scrollController.jumpTo(0);
                  _startScrolling();
              });
           });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _startScrolling();
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(), // Controlled manually
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}
