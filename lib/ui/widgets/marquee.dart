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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startScrolling() async {
    if (!mounted || _scrolling) return;
    
    // Allow layout to settle
    if (!_scrollController.hasClients) return;
    
    // Only scroll if content is larger than viewport
    if (_scrollController.position.maxScrollExtent > 0) {
      _scrolling = true;
      
      // Wait for initial pause
      await Future.delayed(widget.pauseDuration);
      if (!mounted) {
        _scrolling = false;
        return;
      }
      
      final maxScroll = _scrollController.position.maxScrollExtent;
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(), // Disable user scrolling
      child: widget.child,
    );
  }
}