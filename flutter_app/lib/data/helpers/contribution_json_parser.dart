import 'dart:convert';

class ContributionJsonResult {
  const ContributionJsonResult({
    required this.payload,
    required this.normalizedJson,
    required this.repairs,
  });

  final Map<String, dynamic> payload;
  final String normalizedJson;
  final List<String> repairs;
}

class ContributionJsonException implements Exception {
  const ContributionJsonException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract final class ContributionJsonParser {
  static ContributionJsonResult parse(String input) {
    var source = input.trim();
    if (source.isEmpty) {
      throw const ContributionJsonException('请先粘贴 AI 生成的 JSON');
    }
    final repairs = <String>[];
    if (source.startsWith('\uFEFF')) {
      source = source.substring(1);
      repairs.add('移除了文本开头的隐藏字符');
    }

    try {
      return _finish(source, repairs);
    } on FormatException {
      source = _extractObject(source, repairs);
      source = _replaceSmartQuotes(source, repairs);
      source = _quoteKeys(source, repairs);
      source = _removeTrailingCommas(source, repairs);
      source = _escapeLatexCommands(source, repairs);
      try {
        return _finish(source, repairs);
      } on FormatException catch (error) {
        throw ContributionJsonException(
          'JSON 仍无法解析：${error.message}${error.offset == null ? '' : '（位置 ${error.offset}）'}',
        );
      }
    }
  }

  static ContributionJsonResult _finish(String source, List<String> repairs) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const ContributionJsonException('JSON 顶层必须是对象');
    }
    final payload = _normalize(Map<String, dynamic>.from(decoded), repairs);
    _validate(payload);
    return ContributionJsonResult(
      payload: payload,
      normalizedJson: const JsonEncoder.withIndent('  ').convert(payload),
      repairs: List.unmodifiable(repairs),
    );
  }

  static String _extractObject(String source, List<String> repairs) {
    final fenced = RegExp(
      r'```(?:json)?\s*([\s\S]*?)\s*```',
      caseSensitive: false,
    ).firstMatch(source);
    if (fenced != null) {
      repairs.add('移除了 Markdown JSON 代码围栏');
      source = fenced.group(1)!.trim();
    }
    final start = source.indexOf('{');
    final end = source.lastIndexOf('}');
    if (start >= 0 && end > start && (start != 0 || end != source.length - 1)) {
      source = source.substring(start, end + 1);
      repairs.add('移除了 JSON 前后的说明文字');
    }
    return source;
  }

  static String _replaceSmartQuotes(String source, List<String> repairs) {
    final replaced = source
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");
    if (replaced != source) repairs.add('将全角引号转换为 JSON 引号');
    return replaced;
  }

  static String _quoteKeys(String source, List<String> repairs) {
    var result = source.replaceAllMapped(
      RegExp(r"([{,]\s*)'([^']+)'\s*:"),
      (match) => '${match.group(1)}"${match.group(2)}":',
    );
    result = result.replaceAllMapped(
      RegExp(r'([{,]\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:'),
      (match) => '${match.group(1)}"${match.group(2)}":',
    );
    if (result != source) repairs.add('补全了字段名的双引号');
    return result;
  }

  static String _removeTrailingCommas(String source, List<String> repairs) {
    final result = source.replaceAllMapped(
      RegExp(r',\s*([}\]])'),
      (match) => match.group(1)!,
    );
    if (result != source) repairs.add('删除了对象或数组末尾的多余逗号');
    return result;
  }

  static String _escapeLatexCommands(String source, List<String> repairs) {
    final output = StringBuffer();
    var inString = false;
    var changed = false;
    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      if (char == '"' && !_isEscaped(source, i)) inString = !inString;
      if (inString && char == r'\' && i + 1 < source.length) {
        final next = source[i + 1];
        if (next == r'\' || next == '"' || next == '/') {
          output.write(char);
          continue;
        }
        final command = RegExp(
          r'^[A-Za-z]+',
        ).firstMatch(source.substring(i + 1));
        if (command != null && command.group(0)!.length > 1) {
          output.write(r'\\');
          changed = true;
          continue;
        }
        if (!'bfnrtu'.contains(next)) {
          output.write(r'\\');
          changed = true;
          continue;
        }
      }
      output.write(char);
    }
    if (changed) repairs.add('修复了 LaTeX 命令的 JSON 反斜杠转义');
    return output.toString();
  }

  static bool _isEscaped(String source, int index) {
    var slashCount = 0;
    for (var i = index - 1; i >= 0 && source[i] == r'\'; i--) {
      slashCount++;
    }
    return slashCount.isOdd;
  }

  static Map<String, dynamic> _normalize(
    Map<String, dynamic> input,
    List<String> repairs,
  ) {
    final aliases = {
      'type': 'question_type',
      'question': 'stem',
      'choices': 'options',
      'tags': 'suggested_tags',
    };
    for (final entry in aliases.entries) {
      if (input.containsKey(entry.key) && !input.containsKey(entry.value)) {
        input[entry.value] = input.remove(entry.key);
        repairs.add('将字段 ${entry.key} 规范为 ${entry.value}');
      }
    }
    input['schema_version'] ??= 1;
    input['question_type'] = _enumValue(input['question_type'], {
      '选择题': 'choice',
      '单选题': 'choice',
      '填空题': 'fill',
      '解答题': 'solution',
      '大题': 'solution',
    });
    input['difficulty'] = _enumValue(input['difficulty'] ?? 'medium', {
      '基础': 'basic',
      '简单': 'easy',
      '较易': 'easy',
      '中等': 'medium',
      '较难': 'hard',
      '困难': 'very_hard',
    });
    input['calculation'] = _enumValue(input['calculation'] ?? 'low', {
      '很少': 'very_low',
      '较少': 'low',
      '较多': 'high',
      '很大': 'very_high',
    });
    final source = input['source'];
    if (source is Map) {
      final normalizedSource = Map<String, dynamic>.from(source);
      normalizedSource['source_type'] =
          _enumValue(normalizedSource['source_type'] ?? 'other', {
            '高考真题': 'gaokao',
            '模拟考试': 'mock_exam',
            '模拟题': 'mock_exam',
            '学校试题': 'school_exam',
            '教辅资料': 'textbook',
            '自拟题': 'self_created',
            '其他': 'other',
          });
      if (normalizedSource.containsKey('exam_name') &&
          !normalizedSource.containsKey('source_name')) {
        normalizedSource['source_name'] = normalizedSource.remove('exam_name');
        repairs.add('将字段 exam_name 规范为 source_name');
      }
      if (normalizedSource.containsKey('number') &&
          !normalizedSource.containsKey('question_number')) {
        normalizedSource['question_number'] = normalizedSource.remove('number');
        repairs.add('将字段 number 规范为 question_number');
      }
      normalizedSource['source_name'] ??= '';
      normalizedSource['question_number'] ??= '';
      input['source'] = normalizedSource;
    } else {
      input['source'] = {'source_type': 'other'};
      if (source != null) repairs.add('将无法识别的来源信息规范为其他');
    }
    input['suggested_tags'] ??= <dynamic>[];
    input['uncertainties'] ??= <dynamic>[];

    final options = input['options'];
    if (options is Map) {
      input['options'] = options.entries
          .map((entry) => {'key': '${entry.key}', 'content': '${entry.value}'})
          .toList();
      repairs.add('将选项对象转换为标准选项数组');
    } else {
      input['options'] ??= <dynamic>[];
    }
    if (!input.containsKey('sub_questions')) {
      final explanation =
          input.remove('explanation') ?? input.remove('analysis') ?? '';
      input['sub_questions'] = [
        {
          'stem': '',
          'answer': '${input.remove('answer') ?? ''}',
          'explanation': '$explanation',
        },
      ];
      repairs.add('将答案和解析整理为默认小题');
    }
    return input;
  }

  static dynamic _enumValue(dynamic value, Map<String, String> aliases) =>
      aliases[value] ?? value;

  static void _validate(Map<String, dynamic> payload) {
    if (payload['schema_version'] != 1) {
      throw const ContributionJsonException('不支持的 schema_version');
    }
    if (!const {
      'choice',
      'fill',
      'solution',
    }.contains(payload['question_type'])) {
      throw const ContributionJsonException(
        'question_type 必须是 choice、fill 或 solution',
      );
    }
    if (payload['stem'] is! String ||
        (payload['stem'] as String).trim().isEmpty) {
      throw const ContributionJsonException('题干不能为空');
    }
    final options = payload['options'];
    if (options is! List) {
      throw const ContributionJsonException('options 必须是数组');
    }
    if (payload['question_type'] == 'choice' && options.length < 2) {
      throw const ContributionJsonException('选择题至少需要两个选项');
    }
    if (payload['question_type'] != 'choice' && options.isNotEmpty) {
      throw const ContributionJsonException('非选择题不能包含选项');
    }
    for (final option in options) {
      if (option is! Map ||
          '${option['key'] ?? ''}'.trim().isEmpty ||
          '${option['content'] ?? ''}'.trim().isEmpty) {
        throw const ContributionJsonException('选项标识和内容不能为空');
      }
    }
    final subs = payload['sub_questions'];
    if (subs is! List || subs.isEmpty) {
      throw const ContributionJsonException('至少需要一个答案项');
    }
    for (final sub in subs) {
      if (sub is! Map || '${sub['answer'] ?? ''}'.trim().isEmpty) {
        throw const ContributionJsonException('每个小题都需要答案');
      }
    }
    if (payload['suggested_tags'] is! List ||
        payload['uncertainties'] is! List) {
      throw const ContributionJsonException('标签和不确定项必须是数组');
    }
    if (!const {
      'basic',
      'easy',
      'medium',
      'hard',
      'very_hard',
    }.contains(payload['difficulty'])) {
      throw const ContributionJsonException('difficulty 无效');
    }
    if (!const {
      'very_low',
      'low',
      'high',
      'very_high',
    }.contains(payload['calculation'])) {
      throw const ContributionJsonException('calculation 无效');
    }
    final source = payload['source'];
    if (source is! Map ||
        !const {
          'gaokao',
          'mock_exam',
          'school_exam',
          'textbook',
          'self_created',
          'other',
        }.contains(source['source_type'])) {
      throw const ContributionJsonException('source_type 无效');
    }
    if (source['source_name'] is! String ||
        source['question_number'] is! String) {
      throw const ContributionJsonException('来源名称和原题题号必须是字符串');
    }
  }
}
