import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../router.dart';

class GrowthCenterPage extends StatelessWidget {
  const GrowthCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('成长中心')),
      body: AppContentContainer(
        maxWidth: AppContentWidth.reading,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            AppNavigationList(
              children: [
                AppNavigationListItem(
                  icon: Icons.trending_up_rounded,
                  title: '等级',
                  subtitle: '查看当前等级和升级进度',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.profileLevel),
                ),
                AppNavigationListItem(
                  icon: Icons.toll_rounded,
                  title: '积分',
                  subtitle: '查看积分余额和变动记录',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.profilePoints),
                ),
                AppNavigationListItem(
                  icon: Icons.emoji_events_outlined,
                  title: '成就',
                  subtitle: '查看已经达成的学习里程碑',
                  onTap: () =>
                      RouterUtils.push(context, AppRoutes.profileAchievements),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
