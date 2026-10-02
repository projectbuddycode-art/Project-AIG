import 'package:aig/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aig/features/auth/providers/auth_providers.dart';

class AuthLoginScreen extends ConsumerStatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  ConsumerState<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends ConsumerState<AuthLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(authStateNotifierProvider);
    final state = notifier.state;

    return Scaffold(
      backgroundColor: _LoginColors.background,
      body: Stack(
        children: [
          const _LoginBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 18),
                    const _BrandPanel(),
                    const SizedBox(height: 32),
                    const _WelcomeSection(),
                    const SizedBox(height: 26),
                    _LoginForm(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      showPassword: _showPassword,
                      onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                      onSubmit: state.isLoading
                          ? null
                          : () async {
                              final router = GoRouter.of(context);

                              await notifier.signIn(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                              );

                              if (!mounted) return;

                              // Navigate to dashboard on successful sign-in and replace history
                              final updatedState = notifier.state;
                              if (updatedState.isAuthenticated) {
                                debugPrint('[login] signIn success, navigating to dashboard');
                                router.go(AppRoutePath.dashboard);
                              } else {
                                debugPrint('[login] signIn did not authenticate');
                              }
                            },
                      errorText: state.error?.message,
                      isLoading: state.isLoading,
                      onForgotPassword: () => GoRouter.of(context).push(AppRoutePath.forgotPassword),
                    ),
                    const SizedBox(height: 20),
                    const _DividerLabel(),
                    const SizedBox(height: 20),
                    const _QuickAccessHint(),
                    const SizedBox(height: 24),
                    const _SignUpPrompt(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFFDF8EE)],
              ),
            ),
          ),
        ),
        const Positioned(
          left: -80,
          top: -120,
          child: _GoldRibbon(size: 220, rotation: -0.24),
        ),
        const Positioned(
          right: -60,
          top: 20,
          child: _GoldRibbon(size: 260, rotation: 0.18),
        ),
        const Positioned(
          left: 0,
          top: 40,
          right: 0,
          child: _WorldMapPattern(opacity: 0.08),
        ),
        const Positioned(
          bottom: -30,
          left: -20,
          child: _DiamondAccent(size: 84, opacity: 0.14),
        ),
        const Positioned(
          bottom: 16,
          right: -10,
          child: _DiamondAccent(size: 64, opacity: 0.16),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Center(child: _BrandBadge()),
        ),
      ],
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _DiamondIcon(size: 26),
        SizedBox(height: 12),
        Text(
          'AIG',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: _LoginColors.goldText,
          ),
        ),
      ],
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: _LoginColors.title,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Sign in to continue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _LoginColors.subtitle,
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.errorText,
    required this.isLoading,
    required this.onForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback? onSubmit;
  final String? errorText;
  final bool isLoading;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 12,
      shadowColor: Colors.black.withAlpha(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _LoginColors.title,
              ),
            ),
            const SizedBox(height: 22),
            _LoginTextField(
              controller: emailController,
              labelText: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 16),
            _LoginTextField(
              controller: passwordController,
              labelText: 'Password',
              icon: Icons.lock_outline,
              obscureText: !showPassword,
              suffixIcon: IconButton(
                icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, color: _LoginColors.icon),
                onPressed: onTogglePassword,
              ),
              autofillHints: const [AutofillHints.password],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: _LoginColors.goldText,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Forgot Password?'),
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 4),
              Text(
                errorText!,
                style: const TextStyle(color: Color(0xFFB00020), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 10),
            FilledButton(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: _LoginColors.buttonGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
              child: Text(isLoading ? 'Signing in...' : 'LOGIN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.labelText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF9F7F2),
        labelText: labelText,
        labelStyle: const TextStyle(color: _LoginColors.subtitle),
        prefixIcon: Icon(icon, color: _LoginColors.icon),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE9E2CE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _LoginColors.goldText),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: Color(0xFFE6D9C4), thickness: 1)),
        SizedBox(width: 12),
        Text(
          'OR CONTINUE WITH',
          style: TextStyle(fontSize: 12, letterSpacing: 1.8, color: _LoginColors.subtitle, fontWeight: FontWeight.w600),
        ),
        SizedBox(width: 12),
        Expanded(child: Divider(color: Color(0xFFE6D9C4), thickness: 1)),
      ],
    );
  }
}

class _QuickAccessHint extends StatelessWidget {
  const _QuickAccessHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9E2CE)),
      ),
      child: const Text(
        'Use your email and password to continue into the studio.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _LoginColors.subtitle,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SignUpPrompt extends StatelessWidget {
  const _SignUpPrompt();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: _LoginColors.subtitle, fontSize: 14),
        ),
        Text(
          'Sign Up',
          style: TextStyle(
            color: _LoginColors.goldText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GoldRibbon extends StatelessWidget {
  const _GoldRibbon({required this.size, required this.rotation});

  final double size;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size * 0.44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF3E2B8), Color(0xFFDBC17A)],
          ),
          borderRadius: BorderRadius.circular(size * 0.18),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 28, offset: const Offset(0, 8)),
          ],
        ),
      ),
    );
  }
}

class _WorldMapPattern extends StatelessWidget {
  const _WorldMapPattern({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        painter: _WorldMapPainter(),
        child: const SizedBox(height: 260),
      ),
    );
  }
}

class _WorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF8BB9B5);
    const points = [
      Offset(0.08, 0.32), Offset(0.12, 0.34), Offset(0.16, 0.30), Offset(0.2, 0.32),
      Offset(0.28, 0.26), Offset(0.32, 0.28), Offset(0.36, 0.24), Offset(0.42, 0.26),
      Offset(0.52, 0.34), Offset(0.58, 0.32), Offset(0.64, 0.36), Offset(0.72, 0.34),
      Offset(0.78, 0.38), Offset(0.84, 0.34), Offset(0.88, 0.30), Offset(0.92, 0.32),
    ];
    for (final point in points) {
      canvas.drawCircle(Offset(point.dx * size.width, point.dy * size.height), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiamondIcon extends StatelessWidget {
  const _DiamondIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.8),
      painter: _DiamondPainter(color: _LoginColors.goldText),
    );
  }
}

class _DiamondAccent extends StatelessWidget {
  const _DiamondAccent({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(size, size * 0.8),
        painter: _DiamondPainter(color: _LoginColors.goldText),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  const _DiamondPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height * 0.45)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(0, size.height * 0.45)
      ..close();
    canvas.drawShadow(path, Colors.black.withAlpha(16), 3, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color title = Color(0xFF2F2B24);
  static const Color subtitle = Color(0xFF6F6C63);
  static const Color icon = Color(0xFF8F8475);
  static const Color goldText = Color(0xFFB48C39);
  static const Color buttonGold = Color(0xFFB08934);
}
