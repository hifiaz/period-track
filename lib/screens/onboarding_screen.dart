import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'setup_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Welcome to PeriodTrack",
          body: "Your personal companion for tracking menstrual cycles, symptoms, and fertility. Take control of your reproductive health with advanced insights and predictions.",
          image: _buildImage('assets/images/welcome.svg', context),
          decoration: _getPageDecoration(context),
        ),
        PageViewModel(
          title: "Track Your Cycle",
          body: "Log your periods, symptoms, and mood changes. Our smart algorithm learns your patterns to provide accurate predictions for your next cycle.",
          image: _buildImage('assets/images/cycle.svg', context),
          decoration: _getPageDecoration(context),
        ),
        PageViewModel(
          title: "Fertility Insights",
          body: "Get personalized fertility windows and ovulation predictions. Whether you're trying to conceive or avoid pregnancy, we've got you covered.",
          image: _buildImage('assets/images/fertility.svg', context),
          decoration: _getPageDecoration(context),
        ),
        PageViewModel(
          title: "Health Analytics",
          body: "Discover patterns in your cycle with detailed charts and insights. Understand your body better with comprehensive health analytics.",
          image: _buildImage('assets/images/analytics.svg', context),
          decoration: _getPageDecoration(context),
        ),
        PageViewModel(
          title: "Privacy First",
          body: "Your data stays on your device. We use advanced offline storage to ensure your personal health information remains completely private and secure.",
          image: _buildImage('assets/images/privacy.svg', context),
          decoration: _getPageDecoration(context),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      back: const Icon(Icons.arrow_back),
      skip: Text(
        'Skip',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
      next: Icon(
        Icons.arrow_forward,
        color: Theme.of(context).primaryColor,
      ),
      done: Text(
        'Get Started',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: Theme.of(context).primaryColor.withOpacity(0.3),
        activeSize: const Size(22.0, 10.0),
        activeColor: Theme.of(context).primaryColor,
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }

  Widget _buildImage(String assetName, BuildContext context) {
    return Container(
      height: 250,
      width: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Icon(
        _getIconForAsset(assetName),
        size: 120,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  IconData _getIconForAsset(String assetName) {
    if (assetName.contains('welcome')) return Icons.favorite;
    if (assetName.contains('cycle')) return Icons.calendar_today;
    if (assetName.contains('fertility')) return Icons.child_care;
    if (assetName.contains('analytics')) return Icons.analytics;
    if (assetName.contains('privacy')) return Icons.security;
    return Icons.favorite;
  }

  PageDecoration _getPageDecoration(BuildContext context) {
    return PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).textTheme.headlineLarge?.color,
      ),
      bodyTextStyle: TextStyle(
        fontSize: 16.0,
        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
        height: 1.5,
      ),
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Theme.of(context).scaffoldBackgroundColor,
      imagePadding: const EdgeInsets.only(top: 40),
    );
  }

  void _onIntroEnd(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SetupScreen()),
    );
  }
}

class OnboardingWrapper extends StatelessWidget {
  const OnboardingWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (appProvider.user == null || appProvider.isFirstTime) {
          return const OnboardingScreen();
        }

        // Navigate to main app
        return const MainAppScreen();
      },
    );
  }
}

// Placeholder for main app screen - will be implemented later
class MainAppScreen extends StatelessWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PeriodTrack'),
      ),
      body: const Center(
        child: Text(
          'Main App Screen\n(To be implemented)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}