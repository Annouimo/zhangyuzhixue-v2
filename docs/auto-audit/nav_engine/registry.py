"""
页面导航注册表 — 35 页的导航路径和点击坐标。
G1-G6 分组策略。
"""
from dataclasses import dataclass, field


@dataclass
class NavTarget:
    """一个导航目标的定义"""
    group: str          # G1-G6
    name: str           # 页面英文名（对应 audit_engine 的 _EXPECTED_RT_PAGES）
    label: str          # 显示用中文名
    parent: str = ""    # 父页面（从哪进入）
    nav_seq: list = field(default_factory=list)  # 操作序列 (action, x, y or target)
    sub_pages: list = field(default_factory=list)  # 子页面列表


# 导航注册表
REGISTRY = [
    # ── G1: 核心导航 ──
    NavTarget("G1", "IndexPage", "首页", nav_seq=[
        ("wait", 2.0),  # 启动后等渲染
        ("screenshot", "full"),
    ]),
    NavTarget("G1", "RecommendPage", "推荐页", nav_seq=[
        ("click_bottom_tab", 1),  # 第二个 Tab "推荐"
        ("screenshot", "full"),
    ]),
    NavTarget("G1", "LoginPage", "登录页", nav_seq=[
        ("click_bottom_tab", 4),
        ("click_text", "退出"),
        ("click_text", "退出登录"),
        ("screenshot", "full"),
    ]),
    NavTarget("G1", "RegisterPage", "注册页", nav_seq=[
        ("click_text", "注册"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),

    # ── G2: 组卷/试题浏览 ──
    NavTarget("G2", "ExamHomePage", "组卷首页", nav_seq=[
        ("click_bottom_tab", 2),
        ("screenshot", "full"),
    ]),
    NavTarget("G2", "ExamPickPage", "自主选题", nav_seq=[
        ("click_text", "自主选题"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
    NavTarget("G2", "ExamAutoPage", "智能组卷", nav_seq=[
        ("click_text", "智能组卷"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
    NavTarget("G2", "ExamExplorePage", "发现组卷", nav_seq=[
        ("click_text", "发现组卷"),
        ("screenshot", "full"),
    ]),
    NavTarget("G2", "ExamQuicklookPage", "试卷预览", parent="ExamExplorePage", nav_seq=[
        ("wait", 1.0),
        ("click_text", "第一张试卷"),  # 点第一条
        ("screenshot", "full"),
    ]),
    NavTarget("G2", "ExamQuicklookOtherPage", "其它答案", parent="ExamQuicklookPage", nav_seq=[
        ("click_text", "其它答案"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
    NavTarget("G2", "AnswerSheetPage", "答题卡", parent="ExamQuicklookPage", nav_seq=[
        ("click_text", "答题卡"),
        ("screenshot", "full"),
        ("click_text", "返回"),
        ("click_text", "返回"),
    ]),
    NavTarget("G2", "ExamFavoritesPage", "收藏", nav_seq=[
        ("click_text", "收藏"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
    NavTarget("G2", "ExamHistoryPage", "组卷历史", nav_seq=[
        ("click_text", "组卷历史"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),

    # ── G3: 解题流程 ──
    NavTarget("G3", "SolveChoicePage", "选择题解题", nav_seq=[
        ("click_bottom_tab", 2),
        ("click_text", "自主选题"),
        ("click_text", "确认组卷"),
        ("click_text", "开始做题"),
        ("screenshot", "full"),
    ]),
    NavTarget("G3", "SolveFillPage", "填空题解题", parent="SolveChoicePage", nav_seq=[
        ("click_text", "下一题"),
        ("screenshot", "full"),
    ]),
    NavTarget("G3", "SolveStepPage", "步骤题解题", parent="SolveFillPage", nav_seq=[
        ("click_text", "下一题"),
        ("screenshot", "full"),
    ]),
    NavTarget("G3", "SolveRatePage", "评分页", parent="SolveStepPage", nav_seq=[
        ("click_text", "评分"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
    NavTarget("G3", "SolveMapPage", "解题地图", parent="SolveChoicePage", nav_seq=[
        ("click_text", "解题地图"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),

    # ── G4: 讲义 ──
    NavTarget("G4", "LectureCoursesPage", "讲义课程", nav_seq=[
        ("click_bottom_tab", 0),
        ("click_text", "讲义"),
        ("screenshot", "full"),
    ]),
    NavTarget("G4", "LectureChaptersPage", "讲义章节", parent="LectureCoursesPage", nav_seq=[
        ("click_text", "第一门课"),
        ("screenshot", "full"),
    ]),
    NavTarget("G4", "LectureContentPage", "讲义内容", parent="LectureChaptersPage", nav_seq=[
        ("click_text", "第一章"),
        ("screenshot", "full"),
        ("click_text", "返回"),
        ("click_text", "返回"),
    ]),

    # ── G5: 作业 ──
    NavTarget("G5", "HomeworkListPage", "作业列表", nav_seq=[
        ("click_bottom_tab", 0),
        ("click_text", "作业"),
        ("screenshot", "full"),
    ]),
    NavTarget("G5", "HomeworkDetailPage", "作业详情", parent="HomeworkListPage", nav_seq=[
        ("click_text", "第一个作业"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),

    # ── G6: 个人中心 ──
    NavTarget("G6", "ProfilePage", "个人资料", nav_seq=[
        ("click_bottom_tab", 3),
        ("screenshot", "full"),
    ]),
    NavTarget("G6", "ProfileEditPage", "编辑资料", nav_seq=[
        ("click_text", "编辑"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
    NavTarget("G6", "StatisticsPage", "学习统计", nav_seq=[
        ("click_text", "统计"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
    NavTarget("G6", "AchievementPage", "成就", nav_seq=[
        ("click_text", "成就"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
    NavTarget("G6", "LevelDetailPage", "等级", nav_seq=[
        ("click_text", "等级"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
    NavTarget("G6", "PointsPage", "积分", nav_seq=[
        ("click_text", "积分"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
    NavTarget("G6", "QuestionHistoryPage", "做题历史", nav_seq=[
        ("click_text", "做题历史"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
    NavTarget("G6", "PreferenceListPage", "学习偏好列表", nav_seq=[
        ("click_text", "学习偏好"),
        ("screenshot", "full"),
    ]),
    NavTarget("G6", "PreferenceEditPage", "学习偏好编辑", parent="PreferenceListPage", nav_seq=[
        ("click_text", "第一个偏好"),
        ("screenshot", "full"),
        ("click_text", "返回"),
        ("click_text", "返回"),
    ]),
    NavTarget("G6", "SyncQueuePage", "同步状态", nav_seq=[
        ("click_text", "同步状态"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
    NavTarget("G6", "AboutPage", "关于", nav_seq=[
        ("click_text", "关于"),
        ("screenshot", "full"),
        ("click_text", "返回"),
    ]),
]


def get_by_group(group: str) -> list[NavTarget]:
    return [t for t in REGISTRY if t.group == group]


def get_by_name(name: str) -> NavTarget | None:
    for t in REGISTRY:
        if t.name == name:
            return t
    return None
