import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'theme_context.dart';
import 'tokens.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
    this.eyebrow,
    this.buttonIcon,
    this.thumbnailPath,
    this.thumbnailTag,
    this.showBars = false,
  });

  final String title;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final String? eyebrow;
  final IconData? buttonIcon;
  final String? thumbnailPath;
  final String? thumbnailTag;
  final bool showBars;

  static const _bars = [
    8, 14, 22, 12, 18, 26, 16, 10, 20, 24, 14, 8, 18, 22, //
    12, 16, 26, 20, 10, 14, 22, 18, 12, 8, 16, 20, 12, 8,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.appText;
    final hasMedia = eyebrow != null || thumbnailPath != null || showBars;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: colors.heroGradient),
        child: Stack(
          children: [
            const Positioned(top: -80, right: -60, child: _HeroRing()),
            Padding(
              padding: const EdgeInsets.all(AppSpace.s18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasMedia)
                    Row(
                      children: [
                        _Thumb(path: thumbnailPath, tag: thumbnailTag),
                        const SizedBox(width: AppSpace.s14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (eyebrow != null)
                                Text(
                                  eyebrow!,
                                  style: text.footnote.copyWith(
                                    color: const Color(0xCCFFFFFF),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              const SizedBox(height: AppSpace.s6),
                              Text(title, style: text.heroTitle),
                              if (showBars) ...[
                                const SizedBox(height: AppSpace.s6),
                                const _Bars(heights: _bars),
                              ],
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Text(title, style: text.heroTitle),
                  const SizedBox(height: AppSpace.s16),
                  Material(
                    color: colors.heroText,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    child: InkWell(
                      onTap: onPressed,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      child: SizedBox(
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (buttonIcon != null) ...[
                              Icon(
                                buttonIcon,
                                size: 18,
                                color: colors.heroButtonText,
                              ),
                              const SizedBox(width: AppSpace.s8),
                            ],
                            Flexible(
                              child: Text(
                                buttonLabel,
                                overflow: TextOverflow.ellipsis,
                                style: text.button.copyWith(
                                  color: colors.heroButtonText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.path, this.tag});

  final String? path;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final file = path == null ? null : File(path!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.row),
      child: SizedBox(
        width: 96,
        height: 120,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (file != null && file.existsSync())
              Image.file(file, fit: BoxFit.cover, cacheWidth: 300)
            else
              ColoredBox(
                color: const Color(0x24FFFFFF),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIcons.filmSlate(PhosphorIconsStyle.fill),
                    color: colors.heroText,
                    size: 32,
                  ),
                ),
              ),
            if (tag != null)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x80000000),
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                  child: Text(
                    tag!,
                    style: context.appText.micro.copyWith(
                      color: colors.heroText,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.heights});

  final List<int> heights;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < heights.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Container(
              width: 3,
              height: heights[i].toDouble(),
              decoration: BoxDecoration(
                color: i < 17
                    ? const Color(0xFFFFFFFF)
                    : const Color(0x66FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroRing extends StatelessWidget {
  const _HeroRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x14FFFFFF), width: 26),
      ),
    );
  }
}
