import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_shell.dart';
import '../../../../shared/models/mock_data.dart';

class EmotionPickerScreen extends StatelessWidget {
  const EmotionPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 0,
      title: '오늘의 마음',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '가장 가까운 감정 구슬을 선택해 주세요.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emotionTags
                  .map(
                    (tag) => Chip(
                      label: Text('#${tag.nameKo}'),
                      avatar: const Icon(Icons.auto_awesome, size: 18),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              maxLength: 80,
              decoration: const InputDecoration(
                hintText: '짧은 문장으로 오늘의 마음을 남겨보세요',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go('/constellation'),
              child: const Text('내 별 띄우기'),
            ),
          ],
        ),
      ),
    );
  }
}

