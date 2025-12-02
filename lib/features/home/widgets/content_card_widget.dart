import 'package:flutter/material.dart';

class ContentCardWidget extends StatelessWidget {
  final String imageUrl;
  final bool isFocused;

  const ContentCardWidget({
    super.key,
    required this.imageUrl,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 240,
      height: 180,
      transform: Matrix4.identity()..scale(isFocused ? 1.1 : 1.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: 3,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[800]),
            ),
            if (isFocused)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.center,
                  child: Icon(Icons.play_circle_filled, color: Colors.white, size: 56),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
