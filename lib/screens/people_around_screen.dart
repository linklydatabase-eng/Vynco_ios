import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class PeopleAroundScreen extends StatelessWidget {
  const PeopleAroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('People Around'),
      ),
      body: const Center(
        child: Text(
          'People Around Screen\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: AppColors.grey600,
          ),
        ),
      ),
    );
  }
}
