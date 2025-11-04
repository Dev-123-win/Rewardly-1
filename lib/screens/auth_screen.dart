import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as my_auth_provider;
import 'home_screen.dart'; // We will create this later

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submitAuthForm() async {
    final errorColor = Theme.of(context).colorScheme.error;
    String? errorMessage; // Declared here
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<my_auth_provider.AuthProvider>(context, listen: false);
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
          _referralCodeController.text.trim(),
        );
      }
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      errorMessage = 'An error occurred, please check your credentials!';
      if (e.message != null) {
        errorMessage = e.message!;
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: errorColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      errorMessage = e.toString();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showReferralDialog() async {
    final referralCodeController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Enter Referral Code'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('If you have a referral code, please enter it below.'),
                TextField(
                  controller: referralCodeController,
                  decoration: const InputDecoration(hintText: "Referral Code (Optional)"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Skip'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                final authProvider = Provider.of<my_auth_provider.AuthProvider>(context, listen: false);
                final navigator = Navigator.of(dialogContext);
                final mainNavigator = Navigator.of(context);
                await authProvider.applyReferralCode(referralCodeController.text.trim());
                if (mounted) {
                  navigator.pop();
                  mainNavigator.pushReplacement(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _signInWithGoogle() async {
    final errorColor = Theme.of(context).colorScheme.error;
    String? errorMessage; // Declared here
    setState(() {
      _isLoading = true;
    });
    final authProvider = Provider.of<my_auth_provider.AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final isNewUser = await authProvider.signInWithGoogle();
      if (!mounted) return;

      if (isNewUser) {
        await _showReferralDialog();
      } else {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      errorMessage = 'Google Sign-In failed.';
      if (e.message != null) {
        errorMessage = e.message!;
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: errorColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      errorMessage = e.toString();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email address'),
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 7) {
                        return 'Password must be at least 7 characters long.';
                      }
                      return null;
                    },
                  ),
                  if (!_isLogin)
                    TextFormField(
                      controller: _referralCodeController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(labelText: 'Referral Code (Optional)'),
                    ),
                  const SizedBox(height: 20),
                  if (_isLoading) const CircularProgressIndicator(),
                  if (!_isLoading)
                    ElevatedButton(
                      onPressed: _submitAuthForm,
                      child: Text(_isLogin ? 'Login' : 'Sign Up'),
                    ),
                  if (!_isLoading)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(_isLogin
                          ? 'Create new account'
                          : 'I already have an account'),
                    ),
                  const SizedBox(height: 20),
                  if (!_isLoading)
                    ElevatedButton.icon(
                      icon: Image.asset('assets/google_logo.png', height: 24), // Placeholder
                      label: const Text('Sign in with Google'),
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
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
}
