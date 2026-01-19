import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
      ),
      body: const Center(
        child: Text(
          'Posts Screen\nComing Soon!',
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
