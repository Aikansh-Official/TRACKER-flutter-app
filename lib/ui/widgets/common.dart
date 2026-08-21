import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PageIntro extends StatefulWidget {
  const PageIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.showOrbit = false,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool showOrbit;

  @override
  State<PageIntro> createState() => _PageIntroState();
}

class _PageIntroState extends State<PageIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: reduced ? 1 : progress,
          child: Transform.translate(
            offset: Offset(0, reduced ? 0 : 14 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final compact = constraints.maxWidth / textScale < 430;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.eyebrow.toUpperCase(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: TrackerColors.gold),
              ),
              const SizedBox(height: 9),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: compact ? 28 : 31,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.showOrbit && !compact)
                const Positioned(right: -22, top: -28, child: _HeroOrbit()),
              if (compact || widget.trailing == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    text,
                    if (widget.trailing != null) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: widget.trailing!,
                      ),
                    ],
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: text),
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: widget.trailing!,
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroOrbit extends StatefulWidget {
  const _HeroOrbit();
  @override
  State<_HeroOrbit> createState() => _HeroOrbitState();
}

class _HeroOrbitState extends State<_HeroOrbit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = .5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final wave = sin(_controller.value * pi);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0014)
            ..rotateX((_controller.value - .5) * .08)
            ..rotateY((_controller.value - .5) * -.16)
            ..rotateZ((_controller.value - .5) * .22),
          child: Opacity(
            opacity: .17,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: TrackerColors.gold, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: TrackerColors.gold.withValues(
                      alpha: .05 + .07 * wave,
                    ),
                    blurRadius: 14 + 16 * wave,
                  ),
                ],
              ),
              child: Center(
                child: Transform.translate(
                  offset: Offset(6 * (_controller.value - .5), -3 * wave),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TrackerColors.violet.withValues(alpha: .35),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final reduced = MediaQuery.disableAnimationsOf(context);
      final value = reduced ? 1.0 : _controller.value;
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - Curves.easeOut.transform(value))),
          child: child,
        ),
      );
    },
    child: widget.child,
  );
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.children, this.spacing = 10});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final columns =
          constraints.maxWidth < 280 ||
              (textScale > 1.3 && constraints.maxWidth < 520)
          ? 1
          : 2;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class MetricCard extends StatefulWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    this.color,
  });
  final String label, value, caption;
  final Color? color;
  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final reduced = MediaQuery.disableAnimationsOf(context);
      final progress = reduced
          ? 1.0
          : Curves.easeOutBack.transform(_controller.value);
      return Opacity(
        opacity: reduced ? 1 : _controller.value,
        child: Transform.scale(scale: .94 + .06 * progress, child: child),
      );
    },
    child: Card(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 120),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: widget.color ?? TrackerColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 360),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Text(
                  widget.value,
                  key: ValueKey(widget.value),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 34,
                    color: widget.color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.icon = Icons.auto_awesome_outlined,
  });
  final String eyebrow, title, body;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 34, color: TrackerColors.gold),
            const SizedBox(height: 12),
            Text(
              eyebrow.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: TrackerColors.gold),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: TrackerColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.child,
    this.action,
  });
  final String eyebrow, title;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 330;
              final heading = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: TrackerColors.gold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
              if (action == null) return heading;
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 10), action!],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 8),
                  action!,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

EdgeInsets get pagePadding => const EdgeInsets.fromLTRB(18, 20, 18, 124);
