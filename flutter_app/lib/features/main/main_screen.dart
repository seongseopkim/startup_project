import 'package:flutter/material.dart';
import 'package:flutter_app/features/alpha/alpha_chart_screen.dart';
import '../../../widgets/bottom_nav_bar.dart';
import '../check/check_screen.dart';
import '../../features/gemini_dictionary_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    //MockInvestmentScreen(),
    AlphaChartScreen(),
    CheckScreen(),
    GeminiDictionaryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ANT HOUSE', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F1F1F),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
