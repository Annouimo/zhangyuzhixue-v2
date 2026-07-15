/// 积分/金额显示格式化
///
/// 整数去尾零（5 → "5"），非整数保留 1 位小数（0.3 → "0.3"）。
/// 匹配金融类 UI 的通行惯例——微信余额显示 "100" 而非 "100.0"。
String formatAmount(double value) {
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
