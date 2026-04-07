import 'package:flutter/material.dart';

import '../../../../core/widgets/app_shell.dart';
import '../../../../shared/models/mock_data.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 3,
      title: '내 기록',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card(
            child: ListTile(
              title: const Text('연속 기록일'),
              subtitle: Text('${mockStats.streakDays}일째 이어가고 있어요'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('받은 위로'),
              subtitle: Text('${mockStats.receivedReactionCount}개의 리액션을 받았어요'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '최근 7일 감정',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...mockStats.recentEmotionCounts.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: <Widget>[
                          SizedBox(width: 40, child: Text(entry.key)),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: entry.value / 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

