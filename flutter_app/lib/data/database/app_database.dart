import 'package:drift/drift.dart';

part 'app_database.g.dart';

// ═══════════════════════════════════════════════
// 表定义 — SQL 表名与设计文档 docs/02-数据/数据库结构设计.md 一致（单数）
// ═══════════════════════════════════════════════

/// 用户信息缓存（本地专用）
@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  @override
  String get tableName => 'user_profile';
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn? get realName => text().nullable()();
  TextColumn? get studentId => text().nullable()();
  TextColumn? get avatar => text().nullable()();
  TextColumn? get school => text().nullable()();
  TextColumn? get gaokaoYear => text().nullable()();
  IntColumn? get classGroupId => integer().nullable()();
  TextColumn? get phone => text().nullable()();
  TextColumn? get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 登录轨迹
@DataClassName('UserLoginLogRow')
class UserLoginLogs extends Table {
  @override
  String get tableName => 'user_login_log';
  IntColumn get id => integer().autoIncrement()();
  TextColumn get loginDate => text().unique()();
  TextColumn get createdAt => text()();
}

/// 积分流水
@DataClassName('PointsTransactionRow')
class PointsTransactions extends Table {
  @override
  String get tableName => 'points_transaction';
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get transactionType => text()();
  TextColumn get source => text()();
  IntColumn? get sourceObjectId => integer().nullable()();
  TextColumn? get description => text().nullable()();
  TextColumn get createdAt => text()();
}

/// 成就进度缓存
@DataClassName('StudentAchievementRow')
class StudentAchievements extends Table {
  @override
  String get tableName => 'student_achievement';
  IntColumn get id => integer().autoIncrement()();
  TextColumn get achievementCode => text()();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get isUnlocked =>
      integer().withDefault(const Constant(0))();
  TextColumn? get unlockedAt => text().nullable()();
  TextColumn? get updatedAt => text().nullable()();
}

/// 提交头
@DataClassName('SubmissionRow')
class Submissions extends Table {
  @override
  String get tableName => 'submission';
  IntColumn get id => integer().autoIncrement()();
  IntColumn? get serverId => integer().nullable()();
  IntColumn get studentId => integer()();
  IntColumn? get assignmentId => integer().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}

/// 提交明细
@DataClassName('SubmissionDetailRow')
class SubmissionDetails extends Table {
  @override
  String get tableName => 'submission_detail';
  IntColumn get id => integer().autoIncrement()();
  IntColumn? get serverId => integer().nullable()();
  IntColumn? get submissionId => integer().nullable()();
  IntColumn get questionId => integer()();
  IntColumn get attemptNumber => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(const Constant('in_progress'))();
  TextColumn? get answerText => text().nullable()();
  IntColumn? get isCorrect => integer().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}

/// 步骤反馈
@DataClassName('StepFeedbackRow')
class StepFeedbacks extends Table {
  @override
  String get tableName => 'step_feedback';
  IntColumn get id => integer().autoIncrement()();
  IntColumn? get serverId => integer().nullable()();
  IntColumn get submissionDetailId => integer()();
  IntColumn get questionId => integer()();
  IntColumn? get subQuestionIndex => integer().nullable()();
  IntColumn? get methodId => integer().nullable()();
  IntColumn get stepNumber => integer()();
  TextColumn get status => text()();
  TextColumn get createdAt => text()();
}

/// 卡片反馈
@DataClassName('CardFeedbackRow')
class CardFeedbacks extends Table {
  @override
  String get tableName => 'card_feedback';
  IntColumn get id => integer().autoIncrement()();
  IntColumn? get serverId => integer().nullable()();
  IntColumn get submissionDetailId => integer()();
  IntColumn get questionId => integer()();
  TextColumn get cardTitle => text()();
  TextColumn get cardStatus => text()();
  TextColumn get createdAt => text()();
}

/// 题目评分
@DataClassName('QuestionRatingRow')
class QuestionRatings extends Table {
  @override
  String get tableName => 'question_rating';
  IntColumn get id => integer().autoIncrement()();
  IntColumn? get serverId => integer().nullable()();
  IntColumn get questionId => integer().unique()();
  IntColumn get difficultyScore => integer()();
  IntColumn get calculationScore => integer()();
  IntColumn get eleganceScore => integer()();
  TextColumn get createdAt => text()();
}

/// 个性化组卷
@DataClassName('CustomPaperRow')
class CustomPapers extends Table {
  @override
  String get tableName => 'custom_paper';
  IntColumn get id => integer().autoIncrement()();
  IntColumn? get serverId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn? get description => text().nullable()();
  TextColumn? get filterSnapshot => text().nullable()();
  IntColumn get isPublic => integer().withDefault(const Constant(0))();
  IntColumn get viewCount => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}

/// 组卷-题目中间表
@DataClassName('CustomPaperQuestionRow')
class CustomPaperQuestions extends Table {
  @override
  String get tableName => 'custom_paper_question';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get paperId => integer()();
  IntColumn get questionId => integer()();
  IntColumn get sortOrder => integer()();
}

/// 组卷点赞
@DataClassName('PaperLikeRow')
class PaperLikes extends Table {
  @override
  String get tableName => 'paper_like';
  IntColumn get paperId => integer()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {paperId};
}

/// 组卷收藏
@DataClassName('PaperCollectRow')
class PaperCollects extends Table {
  @override
  String get tableName => 'paper_collect';
  IntColumn get paperId => integer()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {paperId};
}

/// 筛选预设
@DataClassName('PreferenceFilterRow')
class PreferenceFilters extends Table {
  @override
  String get tableName => 'preference_filter';
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get years => text()();
  TextColumn get regions => text()();
  TextColumn get conceptTags => text()();
  TextColumn? get types => text().nullable()();
  TextColumn? get knowledgeCards => text().nullable()();
  TextColumn? get questionTypes => text().nullable()();
  RealColumn? get diffMin => real().nullable()();
  RealColumn? get diffMax => real().nullable()();
  RealColumn? get calcMin => real().nullable()();
  RealColumn? get calcMax => real().nullable()();
}

/// 同步队列（表名已是单数，与设计文档一致）
@DataClassName('SyncQueueRow')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get operationType => text()();
  IntColumn get entityId => integer()();
  IntColumn? get serverId => integer().nullable()();
  TextColumn get payload => text()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn? get updatedAt => text().nullable()();
}

// ═══════════════════════════════════════════════
// Database
// ═══════════════════════════════════════════════

@DriftDatabase(tables: [
  UserProfiles,
  UserLoginLogs,
  PointsTransactions,
  StudentAchievements,
  Submissions,
  SubmissionDetails,
  StepFeedbacks,
  CardFeedbacks,
  QuestionRatings,
  CustomPapers,
  CustomPaperQuestions,
  PaperLikes,
  PaperCollects,
  PreferenceFilters,
  SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from <= 2 && to >= 3) {
        await m.addColumn(preferenceFilters, preferenceFilters.knowledgeCards);
        await m.addColumn(preferenceFilters, preferenceFilters.questionTypes);
      }
      if (from <= 3 && to >= 4) {
        // 清理 submission_detail 重复记录（保留每组 question_id+attempt_number 中 id 最小的那条）
        await customStatement(
          'DELETE FROM submission_detail WHERE id NOT IN '
          '(SELECT MIN(id) FROM submission_detail GROUP BY question_id, attempt_number)'
        );
        // 添加唯一索引防止再次产生重复
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_submission_detail_unique '
          'ON submission_detail(question_id, attempt_number)'
        );
      }
    },
  );
}
