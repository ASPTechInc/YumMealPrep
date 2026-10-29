import 'package:flutter/material.dart';

import 'package:yummealprep/utils/constants.dart';

/// Shown in place of a list that has nothing in it.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.action,
    this.showImage = true,
    super.key,
  });

  final String message;
  final Widget? action;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showImage)
              Image.asset(
                Constants.noDataImage,
                height: 140,
                excludeFromSemantics: true,
              ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
