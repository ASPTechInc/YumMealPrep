import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a bundled text or Markdown document, such as the privacy policy.
///
/// Headings (`#`), bullet points (`-`), paragraphs and links are laid out;
/// other Markdown is shown as written. This keeps the app free of a Markdown
/// dependency for a handful of simple documents.
class TextDocumentScreen extends StatelessWidget {
  const TextDocumentScreen({
    required this.title,
    required this.assetPath,
    super.key,
  });

  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('This document is missing.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SelectionArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: markdownBlocks(
                snapshot.data!,
              ).map((block) => _BlockView(block: block)).toList(),
            ),
          );
        },
      ),
    );
  }
}

enum BlockKind { heading1, heading2, heading3, bullet, paragraph }

typedef TextBlock = ({BlockKind kind, String text});

/// Splits simple Markdown into headings, bullets and paragraphs. Lines of a
/// paragraph are joined, matching how Markdown renders them.
List<TextBlock> markdownBlocks(String markdown) {
  final blocks = <TextBlock>[];
  final paragraph = <String>[];
  void endParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add((kind: BlockKind.paragraph, text: paragraph.join(' ')));
    paragraph.clear();
  }

  for (final rawLine in markdown.split('\n')) {
    final line = rawLine.trim();
    final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
    final bullet = RegExp(r'^[-*]\s+(.*)$').firstMatch(line);
    if (line.isEmpty) {
      endParagraph();
    } else if (heading != null) {
      endParagraph();
      final level = heading.group(1)!.length;
      blocks.add((
        kind: switch (level) {
          1 => BlockKind.heading1,
          2 => BlockKind.heading2,
          _ => BlockKind.heading3,
        },
        text: heading.group(2)!,
      ));
    } else if (bullet != null) {
      endParagraph();
      blocks.add((kind: BlockKind.bullet, text: bullet.group(1)!));
    } else if (rawLine.startsWith('  ') &&
        blocks.isNotEmpty &&
        blocks.last.kind == BlockKind.bullet &&
        paragraph.isEmpty) {
      // A wrapped continuation of the previous bullet.
      final last = blocks.removeLast();
      blocks.add((kind: BlockKind.bullet, text: '${last.text} $line'));
    } else {
      paragraph.add(line);
    }
  }
  endParagraph();
  return blocks;
}

/// A run of text, optionally linking to [url].
typedef InlineRun = ({String text, String? url});

final RegExp _link = RegExp(r'\[([^\]]+)\]\(([^)\s]+)\)');

/// Splits Markdown links (`[text](https://...)`) out of [text]. Bold and
/// code markers are removed.
List<InlineRun> inlineRuns(String text) {
  final plain = text.replaceAll(RegExp(r'\*\*|__|`'), '');
  final runs = <InlineRun>[];
  var position = 0;
  for (final match in _link.allMatches(plain)) {
    if (match.start > position) {
      runs.add((text: plain.substring(position, match.start), url: null));
    }
    runs.add((text: match.group(1)!, url: match.group(2)));
    position = match.end;
  }
  if (position < plain.length) {
    runs.add((text: plain.substring(position), url: null));
  }
  return runs;
}

class _BlockView extends StatefulWidget {
  const _BlockView({required this.block});

  final TextBlock block;

  @override
  State<_BlockView> createState() => _BlockViewState();
}

class _BlockViewState extends State<_BlockView> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _text(TextStyle? style) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    final spans = <TextSpan>[];
    for (final run in inlineRuns(widget.block.text)) {
      final url = run.url;
      if (url == null) {
        spans.add(TextSpan(text: run.text));
        continue;
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => unawaited(_open(url));
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(text: run.text, style: linkStyle, recognizer: recognizer),
      );
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return switch (widget.block.kind) {
      BlockKind.heading1 => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _text(textTheme.headlineSmall),
      ),
      BlockKind.heading2 => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: _text(textTheme.titleLarge),
      ),
      BlockKind.heading3 => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: _text(textTheme.titleMedium),
      ),
      BlockKind.bullet => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  '),
            Expanded(child: _text(null)),
          ],
        ),
      ),
      BlockKind.paragraph => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _text(null),
      ),
    };
  }
}
