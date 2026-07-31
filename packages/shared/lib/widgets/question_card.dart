import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/md_latex_body.dart';
import 'package:shared/widgets/status_style.dart';

/// 题目卡片 — 跨页面共享组件
///
/// 在以下 6 个页面复用：
/// - 推荐页（智能/偏好）
/// - 组卷预览页（自己的/他人的）
/// - 做题历史页
/// - 自主选题页
///
/// 两种交互模式：
/// - 导航模式（默认）：点击跳转到解题页，尾部显示 chevron_right
/// - 选择模式（selectable=true）：点击切换选中态，尾部显示 checkbox/radio
class QuestionCard extends StatelessWidget {
  final int questionId;
  final String title;
  final String questionType;

  /// 副信息行文本（如日期、来源），显示在题型/难度标签之后
  final String? subtitle;

  /// 难度值（0~10），提供时显示难度标签
  final double? difficulty;

  /// 做题状态：'pending' / 'in_progress' / 'completed'
  final String? status;

  /// 推荐原因（推荐页专用）
  final String? reason;

  /// 选择模式：true 时尾部显示 checkbox 替代默认的 chevron
  final bool selectable;

  /// 选择模式下的选中态
  final bool selected;

  /// 点击回调，为 null 时卡片不可点击
  final VoidCallback? onTap;

  /// 完全自定义尾部组件，覆盖默认的 chevron/checkbox
  final Widget? trailing;
  final bool compact;

  const QuestionCard({
    super.key,
    required this.questionId,
    required this.title,
    required this.questionType,
    this.subtitle,
    this.difficulty,
    this.status,
    this.reason,
    this.selectable = false,
    this.selected = false,
    this.onTap,
    this.trailing,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadius.lg);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(
        color: selected ? colors.primary : colors.border,
        width: 1,
      ),
    );
    return Material(
      color: selected ? colors.primaryContainer : colors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        hoverColor: selected ? colors.primaryContainer : colors.surfaceSubtle,
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeTag(colors),
                  if (difficulty != null) ...[
                    const SizedBox(width: 6),
                    _buildDiffTag(colors),
                  ],
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Spacer(),
                  ],
                  if (status != null) ...[
                    _buildStatusTag(colors),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  _buildTrailing(context),
                ],
              ),
              SizedBox(height: compact ? 6 : 8),
              MdLatexBody(
                _previewSource(title, maxCharacters: 72),
                fontSize: 14,
              ),
              if (reason != null && reason!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 14,
                      color: colors.warning,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '推荐原因：$reason',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colors.warning),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _previewSource(String source, {required int maxCharacters}) {
    if (source.length <= maxCharacters) return source;

    final output = StringBuffer();
    var index = 0;
    var used = 0;
    while (index < source.length && used < maxCharacters) {
      final formulaStart = source.indexOf(r'$', index);
      if (formulaStart < 0) {
        final remaining = maxCharacters - used;
        final available = source.length - index;
        final take = available < remaining ? available : remaining;
        output.write(source.substring(index, index + take));
        used += take;
        break;
      }

      final plainText = source.substring(index, formulaStart);
      final plainRemaining = maxCharacters - used;
      if (plainText.length >= plainRemaining) {
        output.write(plainText.substring(0, plainRemaining));
        used += plainRemaining;
        break;
      }
      output.write(plainText);
      used += plainText.length;

      final delimiter = source.startsWith(r'$$', formulaStart) ? r'$$' : r'$';
      final formulaEnd = source.indexOf(
        delimiter,
        formulaStart + delimiter.length,
      );
      if (formulaEnd < 0) break;
      final formula = source.substring(
        formulaStart,
        formulaEnd + delimiter.length,
      );
      if (used + formula.length > maxCharacters && used > 0) break;
      output.write(formula);
      used += formula.length;
      index = formulaEnd + delimiter.length;
    }

    final preview = output.toString().trimRight();
    return preview == source ? preview : '$preview…';
  }

  Widget _buildTypeTag(AppSemanticColors colors) {
    return _Tag(
      QuestionTypeLabels.of(questionType),
      bg: colors.primaryContainer,
      fg: colors.primary,
    );
  }

  Widget _buildDiffTag(AppSemanticColors colors) {
    return _Tag(
      DifficultySegments.diffNameFor(difficulty!),
      bg: colors.warningContainer,
      fg: colors.onWarningContainer,
    );
  }

  Widget _buildStatusTag(AppSemanticColors colors) {
    final style = _statusStyle(status!, colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: 11,
          color: style.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final colors = context.colors;
    if (trailing != null) return trailing!;
    if (selectable) {
      return Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? colors.primary : colors.textSecondary,
        size: 24,
      );
    }
    return Icon(Icons.chevron_right, size: 18, color: colors.textSecondary);
  }
}

// ─── 辅助组件 ─────────────────────────────────────────

/// 圆角标签
class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Tag(this.text, {required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}

/// 状态标签样式
({String label, Color color, Color bg}) _statusStyle(
  String status,
  AppSemanticColors colors,
) {
  return statusStyle(status, colors);
}
