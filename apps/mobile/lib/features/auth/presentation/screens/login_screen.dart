import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Spacer(),
              Text(
                '오늘 밤의 마음을\n별처럼 남겨보세요',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                '자유 채팅 대신 안전한 리액션으로 연결되는 감정 기록 MVP입니다.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/today'),
                child: const Text('Google로 시작하기'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/today'),
                child: const Text('Apple로 시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

