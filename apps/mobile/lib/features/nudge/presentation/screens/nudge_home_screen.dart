import 'package:flutter/material.dart';

import '../../../../core/widgets/app_shell.dart';
import '../../../../shared/models/mock_data.dart';

class NudgeHomeScreen extends StatelessWidget {
  const NudgeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 2,
      title: '소프트 넛지',
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: mockNudges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final nudge = mockNudges[index];
          return Card(
            child: ListTile(
              title: Text(nudge.title),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(nudge.body),
              ),
            ),
          );
        },
      ),
    );
  }
}

