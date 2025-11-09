import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/user_provider_new.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';

class EditProfileScreen extends StatefulWidget {
  static const String routeName = '/edit-profile';

  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProviderNew>(context, listen: false);
    _displayNameController.text = userProvider.currentUser?.displayName ?? '';
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // In a real app, you would have a method in UserProvider to update the user's profile.
        // For this example, we'll just show a success message.
        await Future.delayed(
          const Duration(seconds: 1),
        ); // Simulate network request

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: ${e.toString()}'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = isDesktop
        ? 800.0
        : isTablet
        ? 600.0
        : screenWidth;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Profile',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: isDesktop
                        ? Theme.of(context).textTheme.headlineSmall
                        : Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: isDesktop ? 24 : 16),
                  TextFormField(
                    controller: _displayNameController,
                    style: isDesktop
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(
                        Iconsax.user,
                        color: Theme.of(context).colorScheme.primary,
                        size: isDesktop ? 28 : 24,
                      ),
                      helperText: 'This is how other users will see you',
                      helperStyle: TextStyle(fontSize: isDesktop ? 16 : 14),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : 16,
                        vertical: isDesktop ? 20 : 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a display name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isDesktop ? 48 : 32),
                  if (_isLoading)
                    Center(
                      child: SizedBox(
                        width: isDesktop ? 32 : 24,
                        height: isDesktop ? 32 : 24,
                        child: CircularProgressIndicator(
                          strokeWidth: isDesktop ? 3 : 2,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: isDesktop ? 300 : double.infinity,
                      child: FilledButton.icon(
                        onPressed: _updateProfile,
                        icon: Icon(
                          Iconsax.tick_square,
                          size: isDesktop ? 24 : 20,
                        ),
                        label: Text(
                          'Save Changes',
                          style: TextStyle(fontSize: isDesktop ? 18 : 16),
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: Size(
                            double.infinity,
                            isDesktop ? 64 : 56,
                          ),
                        ),
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
