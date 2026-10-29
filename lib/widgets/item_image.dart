import 'package:flutter/material.dart';

import 'package:yummealprep/app_services.dart';

/// Shows a meal or recipe picture from any stored image source.
///
/// Pictures are optional. When there is none, or it cannot be loaded (a
/// missing file, an unreadable or damaged picture, or a source the app does
/// not support such as a web address), a "no picture" placeholder is shown
/// instead. The placeholder is drawn rather than loaded, so it is sharp at
/// any size and matches the light or dark theme.
class ItemImage extends StatelessWidget {
  const ItemImage({
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel,
    super.key,
  });

  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    var provider = AppScope.of(context).images.resolve(source);
    Widget child;
    if (provider == null) {
      child = _NoPicture(width: width, height: height);
    } else {
      // Decode thumbnails at the size they are shown rather than at full
      // resolution, which keeps long lists smooth and memory use low.
      if (width != null && width!.isFinite) {
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        provider = ResizeImage.resizeIfNeeded(
          (width! * pixelRatio).round(),
          null,
          provider,
        );
      }
      child = Image(
        image: provider,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            _NoPicture(width: width, height: height),
      );
    }
    return borderRadius == null
        ? child
        : ClipRRect(borderRadius: borderRadius!, child: child);
  }
}

class _NoPicture extends StatelessWidget {
  const _NoPicture({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: colours.surfaceContainerHighest,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.biggest.shortestSide;
            final iconSize = (side.isFinite ? side * 0.4 : 48.0).clamp(
              16.0,
              72.0,
            );
            return Center(
              child: Icon(
                Icons.no_photography_outlined,
                size: iconSize,
                color: colours.onSurfaceVariant,
                semanticLabel: 'No picture',
              ),
            );
          },
        ),
      ),
    );
  }
}
