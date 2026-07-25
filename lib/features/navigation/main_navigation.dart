import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../home/home_screen.dart';
import '../operations/operations_screen.dart';
import '../accounts/accounts_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  DateTime? _lastBackPressTime;
  final PageController _pageController = PageController();
  bool _snackBarVisible = false;

  final pages = const [HomeScreen(), OperationsScreen(), AccountsScreen()];

  void _resetExitState() {
    _lastBackPressTime = null;
    _snackBarVisible = false;
  }

  Future<bool> _onWillPop() async {
    if (currentIndex != 0) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => currentIndex = 0);
      return false;
    }

    final now = DateTime.now();

    // Если SnackBar был смахнут или закрыт — сбрасываем состояние
    if (_snackBarVisible &&
        _lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _resetExitState();
    }

    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      _snackBarVisible = true;

      ScaffoldMessenger.of(context)
          .showSnackBar(
            SnackBar(
              content: const Text(
                'Нажмите еще раз, чтобы выйти',
                style: TextStyle(color: Colors.white),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
              elevation: 4,
            ),
          )
          .closed
          .then((_) => _resetExitState());

      return false;
    }

    SystemNavigator.pop();
    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => currentIndex = index);
          },
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Главная',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Операции',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Счета',
            ),
          ],
        ),
      ),
    );
  }
}
