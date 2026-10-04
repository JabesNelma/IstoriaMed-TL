import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/auth_bloc/auth_bloc.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'splash_screen.dart';

/// Login screen. Talks to the existing backend login endpoint through the
/// AuthBloc; on success the role router decides the destination.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthLoginSubmitted(
            loginIdentifier: _identifier.text.trim(),
            password: _password.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil(routeForRole(state.session), (_) => false);
          }
        },
        builder: (context, state) {
          final loading = state is AuthAuthenticating;
          final failure = state is AuthLoginFailure ? state.message : null;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_outlined,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('IstoriaMed-TL', style: AppTextStyles.appTitle),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('Sistem Rekam Medis Timor-Leste',
                          style: AppTextStyles.caption),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Login', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Username / Email',
                        controller: _identifier,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Username tenke prenxe.'
                                : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Password',
                        controller: _password,
                        obscure: true,
                        visible: _passwordVisible,
                        onToggleVisible: () => setState(
                            () => _passwordVisible = !_passwordVisible),
                        textInputAction: TextInputAction.done,
                        onSubmitted: _submit,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Password tenke prenxe.'
                            : null,
                      ),
                      if (failure != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(failure, style: AppTextStyles.error),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: loading ? 'Loading...' : 'LOGIN',
                        loading: loading,
                        onPressed: loading ? null : _submit,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Reset password seidauk disponivel iha versiu ida-ne\'e.'),
                                  ),
                                ),
                        child: const Text('Lupa password?'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
