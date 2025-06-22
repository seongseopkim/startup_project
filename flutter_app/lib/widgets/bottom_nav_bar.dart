import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF1E1E1E), // 다크 배경
      selectedItemColor: Colors.purpleAccent, // 선택된 아이템 컬러
      unselectedItemColor: Colors.grey[500], // 비선택 아이템 컬러
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.search), label: '주식'),
        BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: '투자 기록'),
        BottomNavigationBarItem(icon: Icon(Icons.forum), label: '용어 사전'),
      ],
    );
  }
}
