import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/routes/app_routes.dart';
import 'package:dine_pulse/core/utils/app_utils.dart';
import 'package:dine_pulse/member_1/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final success = await auth.signIn(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.m1Home);
    } else if (auth.error != null) {
      SnackBarHelper.showError(context, auth.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Consumer<AuthService>(
        builder: (context, auth, _) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryDark, AppTheme.primary],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Top brand header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
                              child: FadeTransition(
                                opacity: _fadeAnim,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.12),
                                            blurRadius: 16,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.restaurant_menu, size: 44, color: Colors.white),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'DinePulse',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Discover • Reserve • Dine',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        letterSpacing: 1.8,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // White Form Sheet extending to bottom
                            Expanded(
                              child: SlideTransition(
                                position: _slideAnim,
                                child: FadeTransition(
                                  opacity: _fadeAnim,
                                  child: Container(
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(32),
                                        topRight: Radius.circular(32),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 20,
                                          offset: Offset(0, -4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 440),
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Welcome Back',
                                                style: TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              const Text(
                                                'Sign in to continue',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 28),

                                              // Email field
                                              TextFormField(
                                                controller: _emailController,
                                                keyboardType: TextInputType.emailAddress,
                                                textInputAction: TextInputAction.next,
                                                validator: AppValidators.validateEmail,
                                                decoration: const InputDecoration(
                                                  labelText: 'Email Address',
                                                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primary),
                                                ),
                                              ),
                                              const SizedBox(height: 16),

                                              // Password field
                                              TextFormField(
                                                controller: _passwordController,
                                                obscureText: _obscurePassword,
                                                textInputAction: TextInputAction.done,
                                                onFieldSubmitted: (_) => _handleLogin(),
                                                validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                                                decoration: InputDecoration(
                                                  labelText: 'Password',
                                                  prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.primary),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),

                                              // Forgot password
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: () => _showForgotPassword(context),
                                                  child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                                                ),
                                              ),
                                              const SizedBox(height: 12),

                                              // Login button
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: auth.isLoading ? null : _handleLogin,
                                                  child: auth.isLoading
                                                      ? const SizedBox(
                                                          height: 20,
                                                          width: 20,
                                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                        )
                                                      : const Text('Sign In'),
                                                ),
                                              ),
                                              const SizedBox(height: 24),

                                              // Divider
                                              Row(
                                                children: [
                                                  const Expanded(child: Divider()),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                                    child: Text('or', style: TextStyle(color: AppTheme.textHint, fontSize: 13, fontWeight: FontWeight.w500)),
                                                  ),
                                                  const Expanded(child: Divider()),
                                                ],
                                              ),
                                              const SizedBox(height: 20),

                                              // Create account button
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton(
                                                  onPressed: () => Navigator.pushNamed(context, AppRoutes.createAccount),
                                                  child: const Text('Create Account'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a reset link.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              SnackBarHelper.showSuccess(context, 'Reset link sent to ${emailCtrl.text}');
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }
}
