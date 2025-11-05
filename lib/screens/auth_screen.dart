import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as my_auth_provider;
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  static const String routeName = '/auth';

  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true; // To toggle between login and signup
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
      await authProvider.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
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
        MaterialPageRoute(builder: (context) => const HomeScreen()),
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

  // Removed _showReferralDialog as it's related to sign-up flow

  Future<void> _signInWithGoogle() async {
    final errorColor = Theme.of(context).colorScheme.error;
    String? errorMessage; // Declared here
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
        MaterialPageRoute(builder: (context) => const HomeScreen()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                // Lock Icon
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(98, 0, 238, 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Color(0xFF6200EE),
                  ),
                ),
                const SizedBox(height: 20),
                // Welcome Back!
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Log in to your account
                const Text(
                  'Log in to your account',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 40),
                if (_isLogin)
                  ElevatedButton.icon(
                    icon: Image.asset('assets/google_logo.png', height: 24),
                    label: const Text(
                      'Sign in with Google',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.grey, width: 0.5),
                      ),
                      elevation: 0,
                    ),
                  ),
                if (_isLogin) const SizedBox(height: 30),
                // OR Divider
                const Row(
                  children: [
                    Expanded(
                      child: Divider(thickness: 0.5, color: Colors.grey),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('OR', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(
                      child: Divider(thickness: 0.5, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Email address input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (!_isLogin)
                  TextFormField(
                    controller: _referralController,
                    decoration: InputDecoration(
                      labelText: 'Referral Code (Optional)',
                      prefixIcon: const Icon(Icons.card_giftcard),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                if (!_isLogin) const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 7) {
                      return 'Password must be at least 7 characters long.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                // Sign In Button
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6200EE), Color(0xFFBB86FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      onPressed: _submitAuthForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _isLogin ? 'Sign In' : 'Sign Up',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      text: _isLogin
                          ? 'New here? '
                          : 'Already have an account? ',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                      children: [
                        TextSpan(
                          text: _isLogin ? 'Create Account' : 'Sign In',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
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
    );
  }
}
