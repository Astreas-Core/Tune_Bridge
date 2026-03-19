import 'dart:async';
import 'package:flutter/material.dart';

class Marquee extends StatefulWidget {
  final Widget child;
  final Duration pauseDuration;
  final double velocity; // Pixels per second
  final Duration backDuration;

  const Marquee({
    super.key,
    required this.child,
    this.pauseDuration = const Duration(seconds: 2),
    this.velocity = 50.0,
    this.backDuration = const Duration(milliseconds: 800),
  });

  @override
  // ignore: library_private_types_in_public_api
  _MarqueeState createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> {
  final ScrollController _scrollController = ScrollController();
  bool _scrolling = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void didUpdateWidget(covariant Marquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _scrolling = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
    }
  }
  
  @override
  void dispose() {
    _retryTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startScrolling() async {
    if (!mounted || _scrolling) return;
    if (!_scrollController.hasClients) {
      _retryStart();
      return;
    }

    final position = _scrollController.position;
    if (!position.hasViewportDimension || position.viewportDimension <= 1) {
      _retryStart();
      return;
    }

    // Only scroll if content is larger than viewport
    if (position.maxScrollExtent > 0) {
      _scrolling = true;
      
      // Wait for initial pause
      await Future.delayed(widget.pauseDuration);
      if (!mounted) {
        _scrolling = false;
        return;
      }
      
      final maxScroll = position.maxScrollExtent;
      // Calculate duration based on distance and velocity
      final durationMs = (maxScroll / widget.velocity * 1000).toInt();
      final duration = Duration(milliseconds: durationMs);
      
      try {
          // Scroll to end
          await _scrollController.animateTo(
            maxScroll,
            duration: duration,
            curve: Curves.linear,
          );
          
          if (!mounted) return;
          await Future.delayed(widget.pauseDuration);
          
          if (!mounted) return;
          // Scroll back to start quickly
          await _scrollController.animateTo(
            0.0,
            duration: widget.backDuration,
            curve: Curves.easeOut,
          );
          
          // Loop
          _scrolling = false;
          _startScrolling();
      } catch (e) {
          // Animation interrupted (e.g., disposal)
          _scrolling = false;
      }
    }
  }

  void _retryStart() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _startScrolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If width is not yet laid out, avoid attaching a scroll position.
        if (!constraints.hasBoundedWidth || constraints.maxWidth <= 1) {
          return widget.child;
        }

        return SizedBox(
          width: constraints.maxWidth,
          child: ClipRect(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(), // Disable user scrolling
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}