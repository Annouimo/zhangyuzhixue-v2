"""学号生成工具 — LCG 编码 + 模板读取"""

# LCG 参数（一旦确定，严禁修改）
A = 71237      # 乘数，与 100000 互质
C = 58417      # 偏移量
M = 100000
INV_A = 48173  # A 在模 M 下的逆元


def encode_lcg(uid: int) -> str:
    """自增 ID → 5 位 LCG 数字串

    >>> encode_lcg(1)
    '58417'
    >>> encode_lcg(2)
    '29654'
    """
    return f"{((uid - 1) * A + C) % M:05d}"


def decode_lcg(encoded: str) -> int:
    """5 位 LCG 数字串 → 原始自增 ID（内部查询用）

    >>> decode_lcg('58417')
    1
    >>> decode_lcg('29654')
    2
    """
    return ((int(encoded) - C) * INV_A) % M + 1


def get_student_id_template() -> str:
    """从 SystemConfig 读取学号模板，兜底返回默认值"""
    from system.models import SystemConfig
    obj = SystemConfig.objects.filter(key='student_id_template').first()
    return obj.value if obj else '202610{lcg}'
