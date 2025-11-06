import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as my_auth_provider;
import '../core/utils/responsive_utils.dart';
import 'responsive_home_screen.dart';

class ResponsiveAuthScreen extends StatefulWidget {
  static const String routeName = '/auth';

  const ResponsiveAuthScreen({super.key});

  @override
  State<ResponsiveAuthScreen> createState() => _ResponsiveAuthScreenState();
}

class _ResponsiveAuthScreenState extends State<ResponsiveAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _isPasswordVisible = false;

  Future<void> _submitAuthForm() async {
    final errorColor = Theme.of(context).colorScheme.error;
    String? errorMessage;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<my_auth_provider.AuthProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (_isLogin) {
        await authProvider.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await authProvider.signUpWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
          _referralController.text,
        );
      }
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const ResponsiveHomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      errorMessage = 'An error occurred, please check your credentials!';
      if (e.message != null) {
        errorMessage = e.message!;
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: errorColor),
      );
    } catch (e) {
      if (!mounted) return;
      errorMessage = e.toString();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: errorColor),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final errorColor = Theme.of(context).colorScheme.error;
    String? errorMessage;
    setState(() {
      _isLoading = true;
    });
    final authProvider = Provider.of<my_auth_provider.AuthProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await authProvider.signInWithGoogle();
      if (!mounted) return;

      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const ResponsiveHomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      errorMessage = 'Google Sign-In failed.';
      if (e.message != null) {
        errorMessage = e.message!;
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: errorColor),
      );
    } catch (e) {
      if (!mounted) return;
      errorMessage = e.toString();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: errorColor),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAuthForm(BuildContext context, BoxConstraints constraints) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final maxWidth = isDesktop
        ? constraints.maxWidth * 0.3
        : isTablet
        ? constraints.maxWidth * 0.5
        : constraints.maxWidth;

    return Container(
      width: maxWidth,
      padding: padding,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock Icon with responsive size
            Container(
              padding: EdgeInsets.all(
                ResponsiveUtils.getResponsiveSpacing(context),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: ResponsiveUtils.getResponsiveFontSize(context, 40),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Text(
              'Welcome Back!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log in to your account',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              ),
            ),
            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
            ),

            if (_isLogin)
              ElevatedButton.icon(
                icon: Image.asset(
                  'assets/google_logo.png',
                  height: ResponsiveUtils.getResponsiveFontSize(context, 24),
                ),
                label: Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      16,
                    ),
                  ),
                ),
                onPressed: _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  minimumSize: Size(
                    double.infinity,
                    ResponsiveUtils.getResponsiveFontSize(context, 56),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  elevation: 0,
                ),
              ),

            if (_isLogin)
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),

            // OR Divider
            const Row(
              children: [
                Expanded(child: Divider(thickness: 0.5, color: Colors.grey)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('OR', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(thickness: 0.5, color: Colors.grey)),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),

            // Email input field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              ),
              decoration: InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: ResponsiveUtils.getResponsiveFontSize(context, 24),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Please enter a valid email address.';
                }
                return null;
              },
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),

            // Referral Code field for signup
            if (!_isLogin) ...[
              TextFormField(
                controller: _referralController,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                ),
                decoration: InputDecoration(
                  labelText: 'Referral Code (Optional)',
                  prefixIcon: Icon(
                    Icons.card_giftcard,
                    size: ResponsiveUtils.getResponsiveFontSize(context, 24),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            ],

            // Password input field
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              ),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  size: ResponsiveUtils.getResponsiveFontSize(context, 24),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    size: ResponsiveUtils.getResponsiveFontSize(context, 24),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 7) {
                  return 'Password must be at least 7 characters long.';
                }
                return null;
              },
            ),
            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
            ),

            // Sign In/Up Button
            if (_isLoading)
              SizedBox(
                height: ResponsiveUtils.getResponsiveFontSize(context, 24),
                width: ResponsiveUtils.getResponsiveFontSize(context, 24),
                child: const CircularProgressIndicator(),
              )
            else
              SizedBox(
                width: double.infinity,
                height: ResponsiveUtils.getResponsiveFontSize(context, 56),
                child: FilledButton(
                  onPressed: _submitAuthForm,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isLogin ? 'Sign In' : 'Sign Up',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        18,
                      ),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),

            // Toggle between Sign In and Sign Up
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: RichText(
                text: TextSpan(
                  text: _isLogin ? 'New here? ' : 'Already have an account? ',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      16,
                    ),
                  ),
                  children: [
                    TextSpan(
                      text: _isLogin ? 'Create Account' : 'Sign In',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = ResponsiveUtils.isDesktop(context);
          final isTablet = ResponsiveUtils.isTablet(context);

          if (isDesktop || isTablet) {
            // Tablet and Desktop layout with split screen
            return Row(
              children: [
                // Left side - Decorative area
                Expanded(
                  flex: isDesktop ? 6 : 5,
                  child: Container(
                    color: Theme.of(context).colorScheme.primary,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              80,
                            ),
                            color: Colors.white,
                          ),
                          SizedBox(
                            height: ResponsiveUtils.getResponsiveSpacing(
                              context,
                            ),
                          ),
                          Text(
                            'Welcome to EarnPlay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                32,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveUtils.getResponsiveSpacing(
                              context,
                            ),
                          ),
                          Text(
                            'Play, Watch, and Earn!',
                            style: TextStyle(
                              color: Colors.white.withAlpha(230),
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right side - Auth form
                Expanded(
                  flex: isDesktop ? 4 : 5,
                  child: Center(
                    child: SingleChildScrollView(
                      child: _buildAuthForm(context, constraints),
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile layout
          return Center(
            child: SingleChildScrollView(
              child: _buildAuthForm(context, constraints),
            ),
          );
        },
      ),
    );
  }
}
