import 'package:flutter/material.dart';

import '../../router.dart';

List<Widget> questionContributionActions(
  BuildContext context,
  int questionId,
) => [
  PopupMenuButton<String>(
    tooltip: '更多题目操作',
    icon: const Icon(Icons.more_horiz),
    onSelected: (value) => RouterUtils.push(
      context,
      value == 'solution'
          ? '${AppRoutes.contributionNew}?mode=solution&questionId=$questionId'
          : '${AppRoutes.contributionCorrection}?questionId=$questionId',
    ),
    itemBuilder: (context) => const [
      PopupMenuItem(
        value: 'solution',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.account_tree_outlined),
          title: Text('投稿新的解法'),
        ),
      ),
      PopupMenuItem(
        value: 'correction',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.report_outlined),
          title: Text('反馈题目错误'),
        ),
      ),
    ],
  ),
];
