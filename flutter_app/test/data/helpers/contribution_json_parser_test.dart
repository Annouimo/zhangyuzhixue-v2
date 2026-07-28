import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/helpers/contribution_json_parser.dart';

void main() {
  test('parses valid contribution JSON', () {
    final result = ContributionJsonParser.parse(r'''
      {"schema_version":1,"question_type":"fill","stem":"求 $x$", "options":[],
       "sub_questions":[{"stem":"","answer":"$1$","explanation":""}],
       "source":{"source_type":"other"},"suggested_tags":["函数"],
       "difficulty":"easy","calculation":"low","uncertainties":[]}
    ''');
    expect(result.payload['question_type'], 'fill');
    expect(result.repairs, isEmpty);
  });

  test('repairs fences aliases trailing comma and latex slashes', () {
    final result = ContributionJsonParser.parse(r'''
      结果如下：
      ```json
      {type:"选择题", question:"计算 $\frac{1}{2}$", choices:{"A":"1","B":"2"},
       answer:"A", analysis:"因为 $\frac{1}{2}<1$", tags:["分式"],
       difficulty:"简单", calculation:"较少", source:{source_type:"other"},}
      ```
    ''');
    expect(result.payload['question_type'], 'choice');
    expect(result.payload['options'], hasLength(2));
    expect(result.payload['sub_questions'][0]['answer'], 'A');
    expect(result.repairs, isNotEmpty);
  });

  test('rejects missing answer', () {
    expect(
      () => ContributionJsonParser.parse(
        '{"question_type":"fill","stem":"题干","options":[],"sub_questions":[{"answer":""}]}',
      ),
      throwsA(isA<ContributionJsonException>()),
    );
  });
}
