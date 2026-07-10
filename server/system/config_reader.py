"""SystemConfig 统一读取工具

所有业务参数优先通过此模块读取，避免代码中硬编码数值。

使用示例：
    from system.config_reader import get_config_int

    cooldown = get_config_int('solve_choice_cooldown_seconds', 10)
"""

from system.models import SystemConfig


def get_config(key: str, default: str = '') -> str:
    """读取字符串配置，不存在返回 default"""
    obj = SystemConfig.objects.filter(key=key).first()
    return obj.value if obj else default


def get_config_int(key: str, default: int = 0) -> int:
    """读取整数配置，不存在返回 default"""
    obj = SystemConfig.objects.filter(key=key).first()
    return int(obj.value) if obj else default


def get_config_float(key: str, default: float = 0.0) -> float:
    """读取浮点数配置，不存在返回 default"""
    obj = SystemConfig.objects.filter(key=key).first()
    return float(obj.value) if obj else default
