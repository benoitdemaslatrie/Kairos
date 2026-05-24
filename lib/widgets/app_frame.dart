import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AppFrame extends StatelessWidget {
  final Widget? child;
  const AppFrame({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox.shrink();
    if (!kIsWeb) return child!;

    return Container(
      color: const Color(0xFFD0D8E8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: Colors.black.withOpacity(0.12), width: 1),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 48, spreadRadius: 0),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: child!,
          ),
        ),
      ),
    );
  }
}
