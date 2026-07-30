TRAINING_CASE_ID = 'T-001'

TRAINING_INITIAL_PAYLOAD = {
    'schema_version': 2,
    'question_type': 'fill',
    'stem': '已知函数 $f(x)=x^2-4x+3$，则 $f(x)$ 的最小值为______。',
    'options': [],
    'sub_questions': [{
        'stem': '',
        'answer': '1',
        'explanation': (
            '因为 $f(x)=(x-2)^2+1$，且 $(x-2)^2\\geq 0$，'
            '所以最小值为 $1$。'
        ),
        'solution_methods': [],
    }],
    'source': {
        'source_type': 'self_created',
        'year': None,
        'region': '',
        'source_name': '审核员培训样题 T-001',
        'question_number': 'T-001',
    },
    'content_origin': 'original',
    'images': [],
    'default_score': 5,
    'suggested_tags': ['二次函数最值'],
    'difficulty': 'basic',
    'calculation': 'very_low',
    'uncertainties': [],
    'originality_confirmed': True,
}

TRAINING_EXPECTED = {
    'answer': '-1',
    'explanation': (
        '$f(x)=x^2-4x+3=(x-2)^2-1$。因为 $(x-2)^2\\geq 0$，'
        '所以当 $x=2$ 时，$f(x)$ 取得最小值 $-1$。'
    ),
    'review_note': (
        '配方计算有误：$x^2-4x+3=(x-2)^2-1$，最小值应为 $-1$。'
        '请同时更正答案和解析后重新提交。'
    ),
}
