import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/auth/auth_service.dart';
import 'package:ag_showcase_tasks/modules/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';

/// Login screen.
///
/// Uses [AgBuilder] to react to [AuthController] state (loading spinner,
/// error message) without coupling the layout to [AgBasePage]'s scaffold —
/// auth screens own their full layout.
///
/// Demonstrates [AgStateService] → [AuthService.instance] access without
/// any generic syntax at the call site.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  AuthController get _controller => AuthController.find;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AgBuilder(
                listenable: _controller,
                builder: (context) {
                  final isLoading = _controller.state is AgPageLoading;
                  final error = _controller.errorMessage;
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Branding ─────────────────────────────────
                        const SizedBox(height: 32),
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AG Tasks',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Sign in to your workspace',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        const SizedBox(height: 40),

                        // ── Email ─────────────────────────────────────
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter your email'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // ── Password ──────────────────────────────────
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter your password'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 8),

                        // ── Error banner ──────────────────────────────
                        if (error != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              error,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // ── Sign in button ────────────────────────────
                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign in'),
                        ),
                        const SizedBox(height: 16),

                        // ── Register link ─────────────────────────────
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => AgNavigator.toNamed('/register'),
                          child: const Text("Don't have an account? Sign up"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _controller.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }
}
