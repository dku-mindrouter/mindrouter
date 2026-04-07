import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_shell.dart';
import '../../application/emotion_providers.dart';

class EmotionPickerScreen extends ConsumerWidget {
  const EmotionPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(emotionTagsProvider);
    final composer = ref.watch(emotionComposerProvider);

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
            tagsAsync.when(
              data: (tags) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: tags.map((tag) {
                  final isPrimary = composer.primaryTagId == tag.id;
                  final isSecondary = composer.secondaryTagIds.contains(tag.id);

                  return FilterChip(
                    selected: isPrimary || isSecondary,
                    onSelected: (_) {
                      if (isPrimary) {
                        return;
                      }

                      if (composer.primaryTagId == null) {
                        ref
                            .read(emotionComposerProvider.notifier)
                            .selectPrimary(tag.id);
                        return;
                      }

                      ref
                          .read(emotionComposerProvider.notifier)
                          .toggleSecondary(tag.id);
                    },
                    label: Text(
                      isPrimary ? '#${tag.nameKo} (대표)' : '#${tag.nameKo}',
                    ),
                    avatar: const Icon(Icons.auto_awesome, size: 18),
                  );
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('감정 태그를 불러오지 못했어요: $error'),
            ),
            const SizedBox(height: 24),
            TextField(
              maxLength: 80,
              onChanged:
                  ref.read(emotionComposerProvider.notifier).updateContent,
              decoration: const InputDecoration(
                hintText: '짧은 문장으로 오늘의 마음을 남겨보세요',
                border: OutlineInputBorder(),
              ),
            ),
            if (composer.errorMessage != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                composer.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: composer.canSubmit
                  ? () async {
                      final success = await ref
                          .read(emotionComposerProvider.notifier)
                          .submit();

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('오늘의 별이 은하수에 등록되었어요.'),
                          ),
                        );
                        context.go('/constellation');
                      }
                    }
                  : null,
              child: Text(
                composer.isSubmitting ? '등록 중...' : '내 별 띄우기',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
