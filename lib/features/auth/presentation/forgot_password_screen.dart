import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/auth/providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(authStateNotifierProvider);
    final state = notifier.state;

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            if (state.error != null) Text(state.error!.message),
            ElevatedButton(
              onPressed: state.isLoading ? null : () async {
                await notifier.sendPasswordResetEmail(email: _emailController.text);
              },
              child: Text(state.isLoading ? 'Sending...' : 'Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }
}
