import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/utils/responsive_utils.dart';
import 'main_container_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "animation": "assets/lottie/watch_ads.json",
      "title": "Earn Coins by Watching Ads",
      "description":
          "Watch video ads, play games, and complete tasks to earn virtual coins instantly",
      "size": const Size(300, 300),
    },
    {
      "animation": "assets/lottie/spin_wheel.json",
      "title": "Spin, Play & Win Rewards",
      "description":
          "Try your luck on spin wheel, play Tic-Tac-Toe, and other fun games to multiply earnings",
      "size": const Size(300, 300),
    },
    {
      "animation": "assets/lottie/money_transfer.json",
      "title": "Withdraw Real Money",
      "description":
          "Convert coins to cash and withdraw directly to your UPI or bank account",
      "size": const Size(300, 300),
    },
  ];

  Widget buildDot(int index, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 8,
      width: _currentPage == index ? 24 : 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _currentPage == index
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  return _OnboardingPage(
                    animation: onboardingData[index]["animation"]!,
                    title: onboardingData[index]["title"]!,
                    description: onboardingData[index]["description"]!,
                    size: onboardingData[index]["size"] as Size,
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
                                      builder: (context) =>
                                          const MainContainerScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text(
                                  "Get Started",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
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
                                              const MainContainerScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Skip",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
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
                                    icon: const Icon(Icons.arrow_forward),
                                    label: const Text(
                                      "Next",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(120, 56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
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
}

class _OnboardingPage extends StatelessWidget {
  final String animation;
  final String title;
  final String description;
  final Size size;

  const _OnboardingPage({
    required this.animation,
    required this.title,
    required this.description,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation
            Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Lottie.asset(
                animation,
                width: size.width,
                height: size.height,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Description
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
