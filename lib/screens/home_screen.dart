import 'package:flutter/material.dart';
import 'package:period_track/screens/profile_screen.dart';


import '../screens/calendar_screen.dart';
import '../screens/cycle_tracking_screen.dart';
import '../screens/insights_screen.dart';
import '../services/performance_service.dart';
import '../utils/animations.dart';
import '../widgets/banner_ad_widget.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PerformanceService _performanceService = PerformanceService();
  late PageController _pageController;

  // Lazy loading for screens
  final Map<int, Widget?> _loadedScreens = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _performanceService.startOperation('home_screen_init');

    // Pre-load the first screen
    _loadScreen(0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performanceService.endOperation('home_screen_init');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _loadScreen(int index) {
    if (_loadedScreens[index] != null) {
      return _loadedScreens[index]!;
    }

    _performanceService.startOperation('screen_load_$index');

    Widget screen;
    switch (index) {
      case 0:
        screen = const CycleTrackingScreen();
        break;
      case 1:
        screen = const CalendarScreen();
        break;
      case 2:
        screen = const InsightsScreen();
        break;
      case 3:
        screen = const ProfileScreen();
        break;
      default:
        screen = const CycleTrackingScreen();
    }

    _loadedScreens[index] = screen;
    _performanceService.endOperation('screen_load_$index');

    return screen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: AppAnimations.fadeIn(
              duration: AppAnimations.medium,
              child: AnimatedSwitcher(
                duration: AppAnimations.medium,
                switchInCurve: AppAnimations.materialCurve,
                switchOutCurve: AppAnimations.materialCurve,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return AppAnimations.slideIn(
                    child: AppAnimations.fadeIn(
                      child: child,
                      duration: AppAnimations.medium,
                    ),
                    duration: AppAnimations.medium,
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  );
                },
                child: _loadScreen(_currentIndex),
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),

      bottomNavigationBar: AppAnimations.slideIn(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
        duration: AppAnimations.slow,
        child: Stack(
          children: [
            // Background content for glass effect
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.3),
                    Theme.of(context).primaryColor.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: Colors.grey,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            onTap: (index) {
              _performanceService.startOperation('navigation_tap');

              // Add haptic feedback for better mobile feel
              // HapticFeedback.lightImpact(); // Uncomment when haptic feedback is needed

              setState(() {
                _currentIndex = index;
              });
              _performanceService.endOperation('navigation_tap');

              // Pre-load adjacent screens for better performance
              if (index > 0) _loadScreen(index - 1);
              if (index < 3) _loadScreen(index + 1);
            },
            items: [
              BottomNavigationBarItem(
                icon: AppAnimations.elasticScale(
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    padding: EdgeInsets.all(_currentIndex == 0 ? 8 : 4),
                    decoration: BoxDecoration(
                      color: _currentIndex == 0
                          ? Colors.pink.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _currentIndex == 0
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _currentIndex == 0
                          ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                          : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                    ),
                  ),
                  duration: AppAnimations.fast,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: AppAnimations.elasticScale(
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    padding: EdgeInsets.all(_currentIndex == 1 ? 8 : 4),
                    decoration: BoxDecoration(
                      color: _currentIndex == 1
                          ? Colors.pink.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _currentIndex == 1
                          ? Icons.calendar_today
                          : Icons.calendar_today_outlined,
                      color: _currentIndex == 1
                          ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                          : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                    ),
                  ),
                  duration: AppAnimations.fast,
                ),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: AppAnimations.elasticScale(
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    padding: EdgeInsets.all(_currentIndex == 2 ? 8 : 4),
                    decoration: BoxDecoration(
                      color: _currentIndex == 2
                          ? Colors.pink.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _currentIndex == 2
                          ? Icons.insights
                          : Icons.insights_outlined,
                      color: _currentIndex == 2
                          ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                          : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                    ),
                  ),
                  duration: AppAnimations.fast,
                ),
                label: 'Insights',
              ),
              BottomNavigationBarItem(
                icon: AppAnimations.elasticScale(
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    padding: EdgeInsets.all(_currentIndex == 3 ? 8 : 4),
                    decoration: BoxDecoration(
                      color: _currentIndex == 3
                          ? Colors.pink.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _currentIndex == 3 ? Icons.person : Icons.person_outlined,
                      color: _currentIndex == 3
                          ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                          : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                    ),
                  ),
                  duration: AppAnimations.fast,
                ),
                label: 'Profile',
              ),
            ],
              ),
            ),
           ],
         ),
       ),
    );
  }
}
