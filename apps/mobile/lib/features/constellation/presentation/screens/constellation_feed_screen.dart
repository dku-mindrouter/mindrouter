import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_shell.dart';
import '../../../../shared/models/mock_data.dart';

class ConstellationFeedScreen extends StatelessWidget {
  const ConstellationFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 1,
      title: '오늘 밤의 은하수',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              children: const <Widget>[
                Chip(label: Text('전체')),
                Chip(label: Text('비슷한 감정')),
                Chip(label: Text('밤 시간대')),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: mockStars.length,
                itemBuilder: (context, index) {
                  final star = mockStars[index];
                  return InkWell(
                    onTap: () => context.go('/constellation/star/${star.id}'),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('#${star.primaryTag}'),
                            const Spacer(),
                            Text(
                              star.content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'score ${star.relationScore} · 반응 ${star.reactionCount}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

