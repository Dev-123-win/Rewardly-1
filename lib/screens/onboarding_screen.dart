import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../core/utils/responsive_utils.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/onboarding1.png", // Placeholder
      "title": "Earn Coins by Engaging",
      "description":
          "Watch ads, spin the wheel, play games, and claim daily rewards to earn virtual coins.",
    },
    {
      "image": "assets/onboarding2.png", // Placeholder
      "title": "Invite Friends, Earn More",
      "description":
          "Share your referral code and earn bonus coins when your friends join and become active.",
    },
    {
      "image": "assets/onboarding3.png", // Placeholder
      "title": "Withdraw Your Earnings",
      "description":
          "Convert your virtual coins into real money and withdraw directly to your UPI or bank account.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = isDesktop
        ? 1200.0
        : isTablet
        ? 800.0
        : screenWidth;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Stack(
            children: <Widget>[
              PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    image: onboardingData[index]["image"]!,
                    title: onboardingData[index]["title"]!,
                    description: onboardingData[index]["description"]!,
                  );
                },
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveUtils.isDesktop(context) ? 60.0 : 40.0,
                    left: ResponsiveUtils.getResponsivePadding(context).left,
                    right: ResponsiveUtils.getResponsivePadding(context).right,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          onboardingData.length,
                          (index) => buildDot(index, context),
                        ),
                      ),
                      SizedBox(height: isDesktop ? 32 : 20),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 32 : 24,
                        ),
                        child: _currentPage == onboardingData.length - 1
                            ? FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const AuthScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Iconsax.arrow_right_3),
                                label: const Text("Get Started"),
                                style: FilledButton.styleFrom(
                                  minimumSize: Size(
                                    isDesktop ? 300 : double.infinity,
                                    isDesktop ? 64 : 56,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AuthScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text("Skip"),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () {
                                      _pageController.nextPage(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    icon: const Icon(Iconsax.arrow_right_3),
                                    label: const Text("Next"),
                                  ),
                                ],
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
    );
  }

  Container buildDot(int index, BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    return Container(
      height: isDesktop ? 10 : 8,
      width: _currentPage == index
          ? (isDesktop ? 30 : 24)
          : (isDesktop ? 10 : 8),
      margin: EdgeInsets.only(right: isDesktop ? 8 : 6),
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(isDesktop ? 5 : 4),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final padding = ResponsiveUtils.getResponsivePadding(context);

    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            image,
            height:
                MediaQuery.of(context).size.height *
                (isDesktop
                    ? 0.4
                    : isTablet
                    ? 0.35
                    : 0.3),
            fit: BoxFit.contain,
          ),
          SizedBox(height: isDesktop ? 64 : 48),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop
                  ? 32
                  : isTablet
                  ? 28
                  : null,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDesktop ? 24 : 16),
          SizedBox(
            width: isDesktop
                ? 600
                : isTablet
                ? 500
                : double.infinity,
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: isDesktop ? 18 : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
