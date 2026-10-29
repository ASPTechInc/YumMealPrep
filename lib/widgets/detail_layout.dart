import 'package:flutter/material.dart';

import 'package:yummealprep/models/catalogue_item.dart';
import 'package:yummealprep/widgets/item_image.dart';

/// The layout shared by the meal and recipe screens: a large picture that
/// collapses into the app bar, the name and type, then [children].
class DetailLayout extends StatelessWidget {
  const DetailLayout({
    required this.item,
    required this.actions,
    required this.children,
    this.subtitle,
    super.key,
  });

  final CatalogueItem item;
  final List<Widget> actions;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        // Round, dark-backed buttons stay readable over any picture, and
        // still look right once the bar has collapsed.
        Theme(
          data: theme.copyWith(
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          child: SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            actions: [...actions, const SizedBox(width: 8)],
            flexibleSpace: FlexibleSpaceBar(
              background: ItemImage(
                source: item.image,
                semanticLabel: item.name,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList.list(
            children: [
              Text(item.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    avatar: Icon(item.type.icon, color: item.type.colour),
                    label: Text(item.type.label),
                  ),
                  if (subtitle != null) Text(subtitle!),
                ],
              ),
              ...children,
            ],
          ),
        ),
      ],
    );
  }
}

/// A heading above a section of a details screen.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Shown when the item being viewed has been deleted.
class ItemMissing extends StatelessWidget {
  const ItemMissing({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(child: Text(message)),
  );
}

/// A favourite toggle for the app bar.
class FavouriteButton extends StatelessWidget {
  const FavouriteButton({
    required this.isFavourite,
    required this.onPressed,
    super.key,
  });

  final bool isFavourite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: isFavourite ? 'Remove from favourites' : 'Add to favourites',
    isSelected: isFavourite,
    icon: const Icon(Icons.favorite_border),
    selectedIcon: Icon(
      Icons.favorite,
      color: Theme.of(context).colorScheme.error,
    ),
    onPressed: onPressed,
  );
}

/// Opens [source] full screen with pinch-to-zoom.
Future<void> showImageViewer(
  BuildContext context, {
  required String source,
  String? title,
}) => showDialog<void>(
  context: context,
  builder: (context) => Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(title: title == null ? null : Text(title)),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: ItemImage(source: source, fit: BoxFit.contain),
        ),
      ),
    ),
  ),
);
