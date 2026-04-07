import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_env.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_state.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authStatusProvider);
    final authAction = ref.watch(authControllerProvider);

    final status = authStatus.asData?.value ?? AuthStatus.unauthenticated;
    final isAuthenticated = status == AuthStatus.authenticated;

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
              const SizedBox(height: 16),
              Chip(
                label: Text(
                  AppEnv.hasSupabase
                      ? 'Supabase 연결 모드'
                      : '로컬 데모 모드',
                ),
              ),
              if (authAction.errorMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  authAction.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: authAction.isLoading
                    ? null
                    : () async {
                        final success = await ref
                            .read(authControllerProvider.notifier)
                            .signInForDevelopment();

                        if (success && context.mounted) {
                          context.go('/today');
                        }
                      },
                child: Text(
                  isAuthenticated ? '오늘의 감정 기록하러 가기' : '시작하기',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: isAuthenticated ? () => context.go('/today') : null,
                child: const Text('이미 로그인됨: 오늘 화면으로 이동'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
