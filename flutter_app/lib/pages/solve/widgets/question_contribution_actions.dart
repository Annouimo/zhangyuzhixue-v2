import 'package:flutter/material.dart';

import '../../router.dart';

List<Widget> questionContributionActions(
  BuildContext context,
  int questionId,
) => [
  IconButton(
    tooltip: '投稿新的解法',
    icon: const Icon(Icons.account_tree_outlined),
    onPressed: () => RouterUtils.push(
      context,
      '${AppRoutes.contributionNew}?mode=solution&questionId=$questionId',
    ),
  ),
  IconButton(
    tooltip: '反馈题目错误',
    icon: const Icon(Icons.report_outlined),
    onPressed: () => RouterUtils.push(
      context,
      '${AppRoutes.contributionCorrection}?questionId=$questionId',
    ),
  ),
];
