import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/navigation_service.dart';
import '../../services/language_service.dart';
import '../../models/user_model.dart';
import '../home/home_screen.dart';
import '../detect/detect_screen.dart';
import '../history/history_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_dashboard.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<User?>(context);

    if (firebaseUser != null) {
      return FutureBuilder<UserModel?>(
        future: context.read<AuthService>().getUserData(firebaseUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.hasData && snapshot.data!.role == 'admin') {
            return const AdminDashboard(); 
          }
          
          // Show main navigation for regular users
          return const MainNavigation();
        },
      );
    } else {
      return const LoginScreen();
    }
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const DetectScreen(),
    const HistoryScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navService = Provider.of<NavigationService>(context);
    final langService = Provider.of<LanguageService>(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (navService.currentIndex != 0) {
          navService.setIndex(0);
        } else {
          // If already at home, close the app
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: _screens[navService.currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: navService.currentIndex,
          onTap: (index) => navService.setIndex(index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF0A1F11) : theme.cardColor,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: isDark ? const Color(0xFF8DAA91) : Colors.grey,
          elevation: 8,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: langService.translate('home')),
            BottomNavigationBarItem(icon: const Icon(Icons.camera_outlined), activeIcon: const Icon(Icons.camera_alt), label: langService.translate('detect')),
            BottomNavigationBarItem(icon: const Icon(Icons.history_outlined), activeIcon: const Icon(Icons.history), label: langService.translate('history')),
            BottomNavigationBarItem(icon: const Icon(Icons.people_outline), activeIcon: const Icon(Icons.people), label: langService.translate('community')),
            BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: langService.translate('profile')),
          ],
        ),
      ),
    );
  }
}
