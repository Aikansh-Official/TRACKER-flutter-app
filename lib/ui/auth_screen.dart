import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../state/tracker_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.controller,
    required this.hasProfile,
  });
  final TrackerController controller;
  final bool hasProfile;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  late bool login = widget.hasProfile;
  bool busy = false;
  bool obscure = true;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    final result = login
        ? await widget.controller.login(email.text, password.text)
        : await widget.controller.createProfile(
            name.text,
            email.text,
            password.text,
          );
    if (mounted) {
      setState(() {
        busy = false;
        error = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F5F3),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 38, 28, 34),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5541B6), Color(0xFF7D6EE5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(42),
                      bottomRight: Radius.circular(42),
                    ),
                  ),
                  child: const _AuthHero(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'WELCOME TO TRACKER',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: TrackerColors.gold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          login ? 'Welcome back' : 'Start your journey',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(color: TrackerColors.ink),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          login
                              ? 'Unlock your private workspace.'
                              : 'Create an offline profile. Nothing leaves your phone.',
                          style: const TextStyle(color: TrackerColors.muted),
                        ),
                        const SizedBox(height: 28),
                        if (!login) ...[
                          TextField(
                            controller: name,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(color: TrackerColors.ink),
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: TrackerColors.ink),
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: password,
                          obscureText: obscure,
                          style: const TextStyle(color: TrackerColors.ink),
                          onSubmitted: (_) => submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'At least 8 characters',
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => obscure = !obscure),
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFECE8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(13),
                                child: Text(
                                  error!,
                                  style: const TextStyle(
                                    color: Color(0xFFB74432),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: busy ? null : submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: TrackerColors.violet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(17),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: busy
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  login
                                      ? 'Unlock TRACKER →'
                                      : 'Create my profile →',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        TextButton(
                          onPressed: widget.hasProfile
                              ? null
                              : () => setState(() => login = !login),
                          child: Text(
                            login
                                ? 'Create a different local profile'
                                : 'Already have a profile? Sign in',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _AuthHero extends StatefulWidget {
  const _AuthHero();
  @override
  State<_AuthHero> createState() => _AuthHeroState();
}

class _AuthHeroState extends State<_AuthHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Positioned(
          right: -44,
          bottom: -54 + _controller.value * 12,
          child: Transform.rotate(
            angle: _controller.value * .22,
            child: Opacity(
              opacity: .34,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70),
                ),
                child: Center(
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x55998AEA),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.all(Radius.circular(13)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.auto_awesome_rounded, color: Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'TRACKER',
                style: TextStyle(
                  fontFamily: 'serif',
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 44),
          Text(
            'YOUR PERSONAL RHYTHM',
            style: TextStyle(
              color: Color(0xFFE6E0FF),
              fontFamily: 'monospace',
              letterSpacing: 2.1,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Build a life you\nwant to repeat.',
            style: TextStyle(
              fontFamily: 'serif',
              color: Colors.white,
              fontSize: 43,
              height: .98,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 13),
          Text(
            'Private by design. Every plan, feeling, and honest effort stays on this device.',
            style: TextStyle(
              color: Color(0xFFE9E5FF),
              height: 1.45,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ],
  );
}
