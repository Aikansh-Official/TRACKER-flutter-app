import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../core/theme.dart';

const _celebrationColors = <Color>[
  TrackerColors.gold,
  TrackerColors.brightGold,
  TrackerColors.cream,
  TrackerColors.coral,
  TrackerColors.violet,
  TrackerColors.mint,
];

class SpringIconButton extends StatefulWidget {
  const SpringIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
  });

  final Widget icon;
  final FutureOr<void> Function() onPressed;
  final String tooltip;
  final Color? color;

  @override
  State<SpringIconButton> createState() => _SpringIconButtonState();
}

class _SpringIconButtonState extends State<SpringIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    lowerBound: .82,
    upperBound: 1.12,
    value: 1,
  );

  Future<void> _activate() async {
    if (!MediaQuery.disableAnimationsOf(context)) {
      _controller.value = .86;
      _controller.animateWith(
        SpringSimulation(
          const SpringDescription(mass: 1, stiffness: 430, damping: 22),
          .86,
          1,
          0,
        ),
      );
    }
    await widget.onPressed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _controller,
    child: IconButton(
      tooltip: widget.tooltip,
      onPressed: _activate,
      color: widget.color,
      icon: widget.icon,
    ),
  );
}

class LiveIndicator extends StatefulWidget {
  const LiveIndicator({super.key});

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Live time',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final wave = sin(_controller.value * pi);
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TrackerColors.coral,
                boxShadow: [
                  BoxShadow(
                    color: TrackerColors.coral.withValues(alpha: .28 * wave),
                    blurRadius: 3 + 9 * wave,
                    spreadRadius: 1 + 4 * wave,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 7),
        Text(
          'LIVE',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: TrackerColors.coral),
        ),
      ],
    ),
  );
}

/// A single-ticker, painter-based celebration. Particles have independent
/// physics while remaining cheap to render because they are painted on one
/// canvas instead of being built as individual widgets.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.title,
    required this.wholeDay,
  });

  final String title;
  final bool wholeDay;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;
  late final List<_FireworkBurst> _fireworks;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.wholeDay ? 4600 : 2100),
    );
    _buildScene();
  }

  void _buildScene() {
    final random = Random(widget.wholeDay ? 4762026 : 476);
    final count = widget.wholeDay ? 120 : 44;
    _particles = List.generate(count, (index) {
      final fromCenter = !widget.wholeDay;
      return _ConfettiParticle(
        origin: fromCenter
            ? Offset(.5 + (random.nextDouble() - .5) * .08, .48)
            : Offset(random.nextDouble(), -.04 - random.nextDouble() * .12),
        velocity: Offset(
          fromCenter
              ? (random.nextDouble() - .5) * 390
              : (random.nextDouble() - .5) * 90,
          fromCenter
              ? -110 - random.nextDouble() * 260
              : 35 + random.nextDouble() * 100,
        ),
        gravity: 230 + random.nextDouble() * 210,
        drag: .1 + random.nextDouble() * .34,
        rotation: random.nextDouble() * pi * 2,
        angularVelocity: (random.nextDouble() - .5) * 10,
        color: _celebrationColors[random.nextInt(_celebrationColors.length)],
        size: 4 + random.nextDouble() * 8,
        delay: widget.wholeDay ? random.nextDouble() * 2.5 : 0,
        lifetime: 1.25 + random.nextDouble() * (widget.wholeDay ? 2.1 : .7),
        round: random.nextDouble() < .28,
      );
    });

    if (!widget.wholeDay) {
      _fireworks = const [];
      return;
    }
    _fireworks = [
      _FireworkBurst.seeded(
        center: const Offset(.22, .3),
        delay: .42,
        seed: 17,
      ),
      _FireworkBurst.seeded(
        center: const Offset(.74, .23),
        delay: 1.05,
        seed: 29,
      ),
      _FireworkBurst.seeded(
        center: const Offset(.5, .16),
        delay: 1.7,
        seed: 43,
      ),
      _FireworkBurst.seeded(
        center: const Offset(.83, .42),
        delay: 2.35,
        seed: 71,
      ),
      _FireworkBurst.seeded(
        center: const Offset(.14, .48),
        delay: 2.9,
        seed: 89,
      ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value < 1) {
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
    final durationSeconds = _controller.duration!.inMilliseconds / 1000;
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        label: widget.wholeDay
            ? 'Day complete. You kept every promise today.'
            : '${widget.title} complete.',
        child: ColoredBox(
          color: Colors.black.withValues(alpha: widget.wholeDay ? .76 : .52),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!reduced)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => CustomPaint(
                      key: const ValueKey('celebration-particles'),
                      painter: _CelebrationPainter(
                        seconds: _controller.value * durationSeconds,
                        particles: _particles,
                        fireworks: _fireworks,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      if (reduced) return child!;
                      final entrance = Curves.easeOutBack.transform(
                        (_controller.value / .2).clamp(0, 1),
                      );
                      final exit = widget.wholeDay
                          ? 1.0
                          : (1 - ((_controller.value - .78) / .22)).clamp(
                              0.0,
                              1.0,
                            );
                      return Opacity(
                        opacity: exit,
                        child: Transform.scale(
                          scale: .88 + .12 * entrance,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - entrance)),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _CelebrationMessage(
                      title: widget.title,
                      wholeDay: widget.wholeDay,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CelebrationMessage extends StatelessWidget {
  const _CelebrationMessage({required this.title, required this.wholeDay});

  final String title;
  final bool wholeDay;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF24212B).withValues(alpha: .88),
      border: Border.all(
        color: TrackerColors.brightGold.withValues(alpha: .55),
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: TrackerColors.gold.withValues(alpha: .22),
          blurRadius: 36,
          spreadRadius: 5,
        ),
      ],
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              wholeDay ? '✦ DAY COMPLETE ✦' : '✓ COMPLETE',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TrackerColors.brightGold,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              wholeDay ? 'You kept every promise today.' : title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'serif',
                fontSize: 31,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              wholeDay
                  ? 'Pause for a second. This is what consistency feels like.'
                  : 'One meaningful step is now part of your story.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFE8E1D1), height: 1.35),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter({
    required this.seconds,
    required this.particles,
    required this.fireworks,
  });

  final double seconds;
  final List<_ConfettiParticle> particles;
  final List<_FireworkBurst> fireworks;

  @override
  void paint(Canvas canvas, Size size) {
    final confettiPaint = Paint();
    final sparkPaint = Paint()..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final firework in fireworks) {
      _paintFirework(canvas, size, firework, sparkPaint);
    }
    for (final particle in particles) {
      _paintConfetti(canvas, size, particle, confettiPaint);
    }
    canvas.restore();
  }

  void _paintConfetti(
    Canvas canvas,
    Size size,
    _ConfettiParticle particle,
    Paint paint,
  ) {
    final age = seconds - particle.delay;
    if (age < 0 || age > particle.lifetime) return;
    final dragTravel = (1 - exp(-particle.drag * age)) / particle.drag;
    final position = Offset(
      particle.origin.dx * size.width + particle.velocity.dx * dragTravel,
      particle.origin.dy * size.height +
          particle.velocity.dy * age +
          .5 * particle.gravity * age * age,
    );
    final fade = (1 - age / particle.lifetime).clamp(0.0, 1.0);
    paint.color = particle.color.withValues(alpha: fade);
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(particle.rotation + particle.angularVelocity * age);
    if (particle.round) {
      canvas.drawCircle(Offset.zero, particle.size * .45, paint);
    } else {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * .48,
        ),
        paint,
      );
    }
    canvas.restore();
  }

  void _paintFirework(
    Canvas canvas,
    Size size,
    _FireworkBurst firework,
    Paint sparkPaint,
  ) {
    final age = seconds - firework.delay;
    final center = Offset(
      firework.center.dx * size.width,
      firework.center.dy * size.height,
    );
    if (age >= -.42 && age < 0) {
      final launch = Curves.easeOut.transform((age + .42) / .42);
      final start = Offset(center.dx, size.height + 16);
      final head = Offset.lerp(start, center, launch)!;
      final trail = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.transparent, TrackerColors.brightGold],
        ).createShader(Rect.fromPoints(start, head))
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset.lerp(start, head, .65)!, head, trail);
      canvas.drawCircle(head, 3, Paint()..color = TrackerColors.cream);
      return;
    }
    if (age < 0 || age > 1.35) return;
    final progress = age / 1.35;
    final fade = (1 - progress).clamp(0.0, 1.0);
    for (final sparkData in firework.sparks) {
      final spark =
          center +
          Offset(
            sparkData.direction.dx * sparkData.speed * age,
            sparkData.direction.dy * sparkData.speed * age + 48 * age * age,
          );
      final color = _celebrationColors[sparkData.colorIndex].withValues(
        alpha: fade * sparkData.depth.clamp(0, 1),
      );
      sparkPaint
        ..color = color
        ..strokeWidth = 1.2 + sparkData.depth * 1.6;
      final tail = spark - sparkData.direction * (5 + 9 * fade);
      canvas.drawLine(tail, spark, sparkPaint);
      if (progress > .55 && sparkData.ember) {
        canvas.drawCircle(spark, 1.2 * fade, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      oldDelegate.seconds != seconds;
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.origin,
    required this.velocity,
    required this.gravity,
    required this.drag,
    required this.rotation,
    required this.angularVelocity,
    required this.color,
    required this.size,
    required this.delay,
    required this.lifetime,
    required this.round,
  });

  final Offset origin;
  final Offset velocity;
  final double gravity;
  final double drag;
  final double rotation;
  final double angularVelocity;
  final Color color;
  final double size;
  final double delay;
  final double lifetime;
  final bool round;
}

class _FireworkBurst {
  const _FireworkBurst._({
    required this.center,
    required this.delay,
    required this.sparks,
  });

  factory _FireworkBurst.seeded({
    required Offset center,
    required double delay,
    required int seed,
  }) {
    final random = Random(seed);
    return _FireworkBurst._(
      center: center,
      delay: delay,
      sparks: List.generate(24, (index) {
        final angle = (pi * 2 * index / 24) + (random.nextDouble() - .5) * .14;
        final depth = .55 + random.nextDouble() * .75;
        return _FireworkSpark(
          direction: Offset(cos(angle), sin(angle)),
          depth: depth,
          speed: (70 + random.nextDouble() * 100) * depth,
          colorIndex: (index + seed) % _celebrationColors.length,
          ember: index.isEven,
        );
      }),
    );
  }

  final Offset center;
  final double delay;
  final List<_FireworkSpark> sparks;
}

class _FireworkSpark {
  const _FireworkSpark({
    required this.direction,
    required this.depth,
    required this.speed,
    required this.colorIndex,
    required this.ember,
  });

  final Offset direction;
  final double depth;
  final double speed;
  final int colorIndex;
  final bool ember;
}
