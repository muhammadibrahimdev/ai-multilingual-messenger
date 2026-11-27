import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_language.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_scaffold.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AppLanguage _language = AppLanguage.english;
  bool _submitting = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
      _notice = null;
    });

    try {
      final outcome = await ref
          .read(authControllerProvider)
          .signUp(
            email: _emailController.text,
            password: _passwordController.text,
            username: _usernameController.text,
            displayName: _nameController.text,
            language: _language,
          );

      // When email confirmation is disabled the router redirects to the home
      // screen on its own; otherwise tell the user to check their inbox.
      if (outcome == SignUpOutcome.emailConfirmationRequired && mounted) {
        setState(() {
          _notice =
              'Account created. Check your email to confirm your address, '
              'then sign in.';
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = AppException.messageOf(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Chat across English and Urdu with automatic translation',
      footer: AuthFooterLink(
        prompt: 'Already have an account?',
        action: 'Sign in',
        onTap: () => context.go(AppRoutes.login),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              InlineMessage(message: _error!),
              const SizedBox(height: 16),
            ],
            if (_notice != null) ...[
              InlineMessage(message: _notice!, type: InlineMessageType.info),
              const SizedBox(height: 16),
            ],
            AppTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'Your full name',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: Validators.displayName,
              enabled: !_submitting,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _usernameController,
              label: 'Username',
              hint: 'your_username',
              helper: '3-20 characters: letters, numbers or underscore',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]')),
                LengthLimitingTextInputFormatter(20),
              ],
              validator: Validators.username,
              enabled: !_submitting,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              enabled: !_submitting,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'At least ${Validators.minPasswordLength} characters',
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: Validators.password,
              enabled: !_submitting,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text('Preferred language', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            LanguageSelector(
              value: _language,
              enabled: !_submitting,
              onChanged: (language) => setState(() => _language = language),
            ),
            const SizedBox(height: 6),
            Text(
              'Messages you receive are translated into this language.',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Create account',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
