import 'package:flutter/material.dart';

import '../../../../shared/models/mock_data.dart';

class StarDetailScreen extends StatelessWidget {
  const StarDetailScreen({
    required this.starId,
    super.key,
  });

  final String starId;

  @override
  Widget build(BuildContext context) {
    final star = mockStars.firstWhere((item) => item.id == starId);

    return Scaffold(
      appBar: AppBar(title: const Text('별 상세')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Chip(label: Text('#${star.primaryTag}')),
            const SizedBox(height: 16),
            Text(star.content, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              '${star.timeBucket} · 반응 ${star.reactionCount}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              '다정한 리액션만 보낼 수 있어요.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.4,
                ),
                itemCount: reactionTypes.length,
                itemBuilder: (context, index) {
                  final reaction = reactionTypes[index];
                  return Card(
                    child: Center(
                      child: ListTile(
                        title: Text(
                          reaction.icon,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                        ),
                        subtitle: Text(
                          reaction.labelKo,
                          textAlign: TextAlign.center,
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

