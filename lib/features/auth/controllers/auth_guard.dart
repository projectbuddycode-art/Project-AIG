import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.child, required this.redirectTo, this.redirectIfAuthenticated = false});

  final Widget child;
  final String redirectTo;
  final bool redirectIfAuthenticated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child;
  }
}
