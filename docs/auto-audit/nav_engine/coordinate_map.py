"""
设计图推算的按钮坐标映射。
窗口被移动到 (0, 0)，尺寸 390×844。
标题栏 ~30px，客户区偏移 (8, 30)。
pyautogui.click 使用**屏幕绝对坐标**。

推算依据：docs/04-UI/html/*.html 的布局结构 + styles.css 的尺寸变量。
坐标均为屏幕绝对坐标 (screen_x, screen_y)，基准于 96 DPI (100% 缩放)。

用法：
    from coordinate_map import get, set_scale, get_tab
    set_scale(1.75)          # 175% DPI 缩放
    x, y = get("自主选题")    # 返回缩放后的屏幕坐标
    x, y = get_tab(0)        # 返回缩放后的底部 Tab 坐标
"""
from typing import Optional

# ── DPI 缩放 ──
_scale = 1.0

def set_scale(s: float):
    """设置 DPI 缩放因子（如 1.75 表示 175%）"""
    global _scale
    _scale = s

def _s(v: int) -> int:
    """按当前缩放因子缩放坐标值"""
    return int(v * _scale)

# ── 布局常量（基准 96 DPI）──
TITLE_BAR = 30        # 标题栏高度
LEFT_BORDER = 8       # 左边框
WINDOW_W = 390        # 窗口宽
WINDOW_H = 844        # 窗口高
HEADER_H = 56         # page-header 高度
NAV_H = 64            # bottom-nav 高度

# 客户区尺寸
CLIENT_W = WINDOW_W - LEFT_BORDER * 2  # ≈ 374
CLIENT_H = WINDOW_H - TITLE_BAR        # ≈ 814
CONTENT_Y0 = TITLE_BAR + HEADER_H      # 页面内容起始 Y (screen)

# 底部导航 Y 坐标
NAV_Y0 = TITLE_BAR + CLIENT_H - NAV_H  # ≈ 750
NAV_TAB_CENTER_Y = NAV_Y0 + NAV_H // 2  # ≈ 782

# Tab 在底部导航中的水平中心（4 个平均分布）
TAB_CENTERS = [50, 145, 240, 341]  # Tab 3 原 335 → 341 (四等分 390/8=48.75×7)

# 页面内容区域水平中心
CONTENT_CENTER_X = LEFT_BORDER + CLIENT_W // 2  # ≈ 195


def sy(client_y: int) -> int:
    """从客户区 Y 转为屏幕 Y"""
    return client_y + TITLE_BAR


# ═══════════════════════════════════════════════════
# 各个页面的按钮坐标
# ═══════════════════════════════════════════════════

# 注意：x=None 表示使用 CONTENT_CENTER_X（全宽按钮或 list-item）
#       y 是按钮/条目的纵向中心点屏幕坐标

# ── IndexPage（首页）──
# 结构: header(56) + page padding(16) + 欢迎卡(≈82h+12mb) + 待办作业(≈72h+8mb) + 讲义(≈72h+12mb)
# 客户区起始: 56+16=72
INDEX_CARD_H = 82     # 欢迎卡高度（含padding，估算）
INDEX_LIST_H = 72     # list-item 高度（含padding，估算）

# 待办作业入口（client Y 72+82+12=166, center=166+36=202, screen=202+30=232）
INDEX_HOMEWORK_Y = sy(56 + 16 + INDEX_CARD_H + 12 + INDEX_LIST_H // 2)

# 讲义入口（client Y 166+72+8=246, center=246+36=282, screen=282+30=312）
INDEX_LECTURE_Y = sy(56 + 16 + INDEX_CARD_H + 12 + INDEX_LIST_H + 8 + INDEX_LIST_H // 2)


# ── ExamHomePage（组卷首页）──
# 结构: header(56) + page padding(8) + 新组卷card(≈148h+16mb) + 我的组卷list(68h+8mb) + 发现组卷(68h+8mb) + 收藏(68h)
# 客户区起始: 56+8=64
EXAM_CARD_TOP = 56 + 8  # 64
# card内: padding-top 16, title 15+12mb, "智能组卷" btn ~35h+8mb, "自主选题" btn ~35h, padding-bottom 16
# card总高≈16+15+12+35+8+35+16=137
# card底部: 64+137=201, 所以 card 占 64-201
EXAM_CARD_H = 137

# "智能组卷" btn: client Y 64+16+15+12 = 107, center = 107+17 = 124, screen = 154
EXAM_AUTO_Y = sy(64 + 16 + 15 + 12 + 17)
# "自主选题" btn: client Y 107+35+8 = 150, center = 150+17 = 167, screen = 197
EXAM_PICK_Y = sy(64 + 16 + 15 + 12 + 35 + 8 + 17)

EXAM_LIST_H = 72    # list-item 高度
# 以下 list-item 高度 72h, margin-bottom 8
EXAM_LIST_TOP = 64 + EXAM_CARD_H + 16  # 201 (card + margin)
# "我的组卷": center client Y = 201+34=235, screen = 265
EXAM_HISTORY_Y = sy(EXAM_LIST_TOP + 34)
# "发现组卷": client Y 201+68+8=277, center=277+34=311, screen=341
EXAM_EXPLORE_Y = sy(EXAM_LIST_TOP + EXAM_LIST_H + 8 + 34)
# "收藏": client Y 277+68+8=353, center=353+34=387, screen=417
EXAM_FAVORITES_Y = sy(EXAM_LIST_TOP + (EXAM_LIST_H+8)*2 + 34)


# ── ProfilePage（个人中心）──
# 结构: profile card(≈106h+8mb) + page(0) + section titles + list-items
# Header: 56
# profile card 是 a.card（margin 16左右, padding 20-12）
# client Y: 56+16=72, card height≈60+内容
# 第一段 list-item: 学习偏好, 统计, 做题历史
# 第二段: 成就, 等级, 积分
# 第三段: 同步状态, 关于
# 粗略从卡片+section+list高度估算

# 简化：假设 profile card 约 120px, 第一个 section-title 在 client Y 200
PROFILE_CARD_H = 120  # 从 72 到 192
PROFILE_SECTION_GAP = 20  # section-title 间距

# 各 list-item 在 profile 页面的起始 client Y
# 学习: section-title + 3个list-item(68h+8mb) 
# 成长: section-title + 3个list-item
# 系统: section-title + 3个list-item
_P1 = 56 + 16 + PROFILE_CARD_H + 8
# section-title "学习" at ~192, height ~24
_P2 = _P1 + 24  # ~224
PREF_LIST_Y = sy(_P2 + 34)      # "📋 学习偏好" center
STATS_Y = sy(_P2 + 68 + 8 + 34) # "📊 学习统计"
QHIST_Y = sy(_P2 + (68+8)*2 + 34) # "📝 做题历史"

_P3 = _P2 + (68+8)*3 + 24  # "成长" section starts
ACHIEVE_Y = sy(_P3 + 34)    # "🏆 成就"
LEVEL_Y = sy(_P3 + 68 + 8 + 34)  # "🏅 等级"
POINTS_Y = sy(_P3 + (68+8)*2 + 34)  # "💰 积分流水"

_P4 = _P3 + (68+8)*3 + 24  # "系统" section starts
SYNC_Y = sy(_P4 + 34)      # "📤 同步状态"
ABOUT_Y = sy(_P4 + 68 + 8 + 34)  # "ℹ️ 关于"
LOGOUT_Y = sy(_P4 + (68+8)*2 + 34)  # "退出登录"


# ═══════════════════════════════════════════════════
# 完整映射表
# ═══════════════════════════════════════════════════

CLICK_MAP = {
    # ── 底部 Tab ──
    "tab_0": (TAB_CENTERS[0], NAV_TAB_CENTER_Y),  # 首页 Tab
    "tab_1": (TAB_CENTERS[1], NAV_TAB_CENTER_Y),  # 推荐 Tab
    "tab_2": (TAB_CENTERS[2], NAV_TAB_CENTER_Y),  # 组卷 Tab
    "tab_3": (TAB_CENTERS[3], NAV_TAB_CENTER_Y),  # 我的 Tab

    # ── IndexPage ──
    "待办作业": (CONTENT_CENTER_X, INDEX_HOMEWORK_Y),
    "作业": (CONTENT_CENTER_X, INDEX_HOMEWORK_Y),  # 同"待办作业"
    "讲义": (CONTENT_CENTER_X, INDEX_LECTURE_Y),

    # ── ExamHomePage ──
    "智能组卷": (CONTENT_CENTER_X, EXAM_AUTO_Y),
    "自主选题": (CONTENT_CENTER_X, EXAM_PICK_Y),
    "我的组卷": (CONTENT_CENTER_X, EXAM_HISTORY_Y),
    "组卷历史": (CONTENT_CENTER_X, EXAM_HISTORY_Y),  # 同"我的组卷"
    "发现组卷": (CONTENT_CENTER_X, EXAM_EXPLORE_Y),
    "收藏": (CONTENT_CENTER_X, EXAM_FAVORITES_Y),

    # ── ExamExplorePage (发现组卷) ──
    "第一张试卷": (CONTENT_CENTER_X, sy(56 + 8 + 42 + 60)),   # 第一个card中心
    "查看试卷": (243, sy(56 + 8 + 42 + 120)),                 # card底部"查看试卷"按钮

    # ── ExamQuicklookPage (试卷预览) ──
    "其它答案": (CONTENT_CENTER_X, sy(450)),   # 页面靠下位置
    "答题卡": (CONTENT_CENTER_X, sy(350)),     # "快对答案"按钮区域
    "自主选题": (CONTENT_CENTER_X, sy(64 + 16 + 15 + 12 + 35 + 8 + 35 + 8 + 17)),  # 比"智能组卷"多一个按钮间距

    # ── SolveChoicePage (解题) — 答题流程 ──
    # options-grid: flex column, gap 8px
    # 每个 option-btn: padding 12px top, label 28px + text 15px, padding 12px bottom = 67px
    # 起始 client Y: header(56)+solve-container(16)+meta(~16)+stem(88)+gap(12) ≈ 188
    "选项A": (CONTENT_CENTER_X, sy(188 + 67 // 2)),
    "选项B": (CONTENT_CENTER_X, sy(188 + 67 + 8 + 67 // 2)),
    "选项C": (CONTENT_CENTER_X, sy(188 + (67 + 8) * 2 + 67 // 2)),
    "选项D": (CONTENT_CENTER_X, sy(188 + (67 + 8) * 3 + 67 // 2)),
    "提交答案": (CONTENT_CENTER_X, sy(188 + (67 + 8) * 4 + 12 + 12 + 17)),
    "下一题": (CONTENT_CENTER_X, sy(600)),     # done-section "下一题" 按钮
    "评分": (CONTENT_CENTER_X, sy(500)),       # solve-rate 评分按钮
    "解题地图": (CONTENT_CENTER_X, sy(400)),   # 解题地图入口

    # ── LectureCoursesPage (讲义课程) ──
    "第一门课": (CONTENT_CENTER_X, sy(56 + 8 + 34)),

    # ── LectureChaptersPage (讲义章节) ──
    "第一章": (CONTENT_CENTER_X, sy(56 + 8 + 34)),

    # ── HomeworkListPage (作业列表) ──
    "第一个作业": (CONTENT_CENTER_X, sy(56 + 8 + 34)),

    # ── PreferenceListPage (偏好列表) ──
    "第一个偏好": (CONTENT_CENTER_X, sy(56 + 8 + 16 + 30)),

    # ── ProfilePage ──
    "编辑": (CONTENT_CENTER_X, sy(56 + 16 + PROFILE_CARD_H // 2)),
    "学习偏好": (CONTENT_CENTER_X, PREF_LIST_Y),
    "统计": (CONTENT_CENTER_X, STATS_Y),
    "做题历史": (CONTENT_CENTER_X, QHIST_Y),
    "成就": (CONTENT_CENTER_X, ACHIEVE_Y),
    "等级": (CONTENT_CENTER_X, LEVEL_Y),
    "积分": (CONTENT_CENTER_X, POINTS_Y),
    "同步状态": (CONTENT_CENTER_X, SYNC_Y),
    "关于": (CONTENT_CENTER_X, ABOUT_Y),
    "退出登录": (CONTENT_CENTER_X, LOGOUT_Y),

    # ── LoginPage ──
    "注册": (CONTENT_CENTER_X, sy(400)),

    # ── 通用 ──
    "返回": (20, sy(28)),  # back-btn 在 header 左侧
    "退出": (CONTENT_CENTER_X, LOGOUT_Y),  # Profile 页退出同"退出登录"

    # ── 预设占位（需运行时验证调整）──
    "确认组卷": (CONTENT_CENTER_X, sy(750)),  # paper_pick sticky bar
    "开始做题": (CONTENT_CENTER_X, sy(300)),  # 试卷预览→做题按钮
}


def get(text: str) -> Optional[tuple]:
    """获取文本对应的点击坐标（已缩放），找不到返回 None"""
    base = CLICK_MAP.get(text)
    if base is None:
        return None
    return (_s(base[0]), _s(base[1]))


def get_tab(index: int) -> tuple:
    """获取底部 Tab 坐标（已缩放），index 0-3"""
    base = CLICK_MAP.get(f"tab_{index}")
    if base is None:
        raise ValueError(f"无效的 Tab index: {index}")
    return (_s(base[0]), _s(base[1]))


def list_known() -> list[str]:
    """列出所有已知文本"""
    return sorted(CLICK_MAP.keys())


if __name__ == "__main__":
    print(f"DPI 缩放: {_scale:.2f}")
    print(f"内容中心 X: {CONTENT_CENTER_X}")
    print(f"底部导航 Y: {NAV_TAB_CENTER_Y}")
    print(f"已知文本: {len(CLICK_MAP)} 个")
    for k, v in sorted(CLICK_MAP.items()):
        scaled = (_s(v[0]), _s(v[1]))
        print(f"  {k}: base({v[0]}, {v[1]}) → scaled({scaled[0]}, {scaled[1]})")
