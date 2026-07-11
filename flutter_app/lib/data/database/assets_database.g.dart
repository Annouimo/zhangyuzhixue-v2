// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assets_database.dart';

// ignore_for_file: type=lint
class $QuestionsTable extends Questions
    with TableInfo<$QuestionsTable, QuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _examTypeMeta = const VerificationMeta(
    'examType',
  );
  @override
  late final GeneratedColumn<String> examType = GeneratedColumn<String>(
    'exam_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionTypeMeta = const VerificationMeta(
    'questionType',
  );
  @override
  late final GeneratedColumn<String> questionType = GeneratedColumn<String>(
    'question_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calculationMeta = const VerificationMeta(
    'calculation',
  );
  @override
  late final GeneratedColumn<double> calculation = GeneratedColumn<double>(
    'calculation',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stemMeta = const VerificationMeta('stem');
  @override
  late final GeneratedColumn<String> stem = GeneratedColumn<String>(
    'stem',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagesMeta = const VerificationMeta('images');
  @override
  late final GeneratedColumn<String> images = GeneratedColumn<String>(
    'images',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultScoreMeta = const VerificationMeta(
    'defaultScore',
  );
  @override
  late final GeneratedColumn<double> defaultScore = GeneratedColumn<double>(
    'default_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    year,
    examType,
    region,
    number,
    questionType,
    difficulty,
    calculation,
    stem,
    images,
    defaultScore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('exam_type')) {
      context.handle(
        _examTypeMeta,
        examType.isAcceptableOrUnknown(data['exam_type']!, _examTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_examTypeMeta);
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    } else if (isInserting) {
      context.missing(_regionMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('question_type')) {
      context.handle(
        _questionTypeMeta,
        questionType.isAcceptableOrUnknown(
          data['question_type']!,
          _questionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionTypeMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('calculation')) {
      context.handle(
        _calculationMeta,
        calculation.isAcceptableOrUnknown(
          data['calculation']!,
          _calculationMeta,
        ),
      );
    }
    if (data.containsKey('stem')) {
      context.handle(
        _stemMeta,
        stem.isAcceptableOrUnknown(data['stem']!, _stemMeta),
      );
    } else if (isInserting) {
      context.missing(_stemMeta);
    }
    if (data.containsKey('images')) {
      context.handle(
        _imagesMeta,
        images.isAcceptableOrUnknown(data['images']!, _imagesMeta),
      );
    }
    if (data.containsKey('default_score')) {
      context.handle(
        _defaultScoreMeta,
        defaultScore.isAcceptableOrUnknown(
          data['default_score']!,
          _defaultScoreMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      examType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_type'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      questionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_type'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      ),
      calculation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calculation'],
      ),
      stem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stem'],
      )!,
      images: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}images'],
      ),
      defaultScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_score'],
      ),
    );
  }

  @override
  $QuestionsTable createAlias(String alias) {
    return $QuestionsTable(attachedDatabase, alias);
  }
}

class QuestionRow extends DataClass implements Insertable<QuestionRow> {
  final int id;
  final int year;
  final String examType;
  final String region;
  final String number;
  final String questionType;
  final double? difficulty;
  final double? calculation;
  final String stem;
  final String? images;
  final double? defaultScore;
  const QuestionRow({
    required this.id,
    required this.year,
    required this.examType,
    required this.region,
    required this.number,
    required this.questionType,
    this.difficulty,
    this.calculation,
    required this.stem,
    this.images,
    this.defaultScore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['year'] = Variable<int>(year);
    map['exam_type'] = Variable<String>(examType);
    map['region'] = Variable<String>(region);
    map['number'] = Variable<String>(number);
    map['question_type'] = Variable<String>(questionType);
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<double>(difficulty);
    }
    if (!nullToAbsent || calculation != null) {
      map['calculation'] = Variable<double>(calculation);
    }
    map['stem'] = Variable<String>(stem);
    if (!nullToAbsent || images != null) {
      map['images'] = Variable<String>(images);
    }
    if (!nullToAbsent || defaultScore != null) {
      map['default_score'] = Variable<double>(defaultScore);
    }
    return map;
  }

  QuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuestionsCompanion(
      id: Value(id),
      year: Value(year),
      examType: Value(examType),
      region: Value(region),
      number: Value(number),
      questionType: Value(questionType),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      calculation: calculation == null && nullToAbsent
          ? const Value.absent()
          : Value(calculation),
      stem: Value(stem),
      images: images == null && nullToAbsent
          ? const Value.absent()
          : Value(images),
      defaultScore: defaultScore == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultScore),
    );
  }

  factory QuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionRow(
      id: serializer.fromJson<int>(json['id']),
      year: serializer.fromJson<int>(json['year']),
      examType: serializer.fromJson<String>(json['examType']),
      region: serializer.fromJson<String>(json['region']),
      number: serializer.fromJson<String>(json['number']),
      questionType: serializer.fromJson<String>(json['questionType']),
      difficulty: serializer.fromJson<double?>(json['difficulty']),
      calculation: serializer.fromJson<double?>(json['calculation']),
      stem: serializer.fromJson<String>(json['stem']),
      images: serializer.fromJson<String?>(json['images']),
      defaultScore: serializer.fromJson<double?>(json['defaultScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'year': serializer.toJson<int>(year),
      'examType': serializer.toJson<String>(examType),
      'region': serializer.toJson<String>(region),
      'number': serializer.toJson<String>(number),
      'questionType': serializer.toJson<String>(questionType),
      'difficulty': serializer.toJson<double?>(difficulty),
      'calculation': serializer.toJson<double?>(calculation),
      'stem': serializer.toJson<String>(stem),
      'images': serializer.toJson<String?>(images),
      'defaultScore': serializer.toJson<double?>(defaultScore),
    };
  }

  QuestionRow copyWith({
    int? id,
    int? year,
    String? examType,
    String? region,
    String? number,
    String? questionType,
    Value<double?> difficulty = const Value.absent(),
    Value<double?> calculation = const Value.absent(),
    String? stem,
    Value<String?> images = const Value.absent(),
    Value<double?> defaultScore = const Value.absent(),
  }) => QuestionRow(
    id: id ?? this.id,
    year: year ?? this.year,
    examType: examType ?? this.examType,
    region: region ?? this.region,
    number: number ?? this.number,
    questionType: questionType ?? this.questionType,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    calculation: calculation.present ? calculation.value : this.calculation,
    stem: stem ?? this.stem,
    images: images.present ? images.value : this.images,
    defaultScore: defaultScore.present ? defaultScore.value : this.defaultScore,
  );
  QuestionRow copyWithCompanion(QuestionsCompanion data) {
    return QuestionRow(
      id: data.id.present ? data.id.value : this.id,
      year: data.year.present ? data.year.value : this.year,
      examType: data.examType.present ? data.examType.value : this.examType,
      region: data.region.present ? data.region.value : this.region,
      number: data.number.present ? data.number.value : this.number,
      questionType: data.questionType.present
          ? data.questionType.value
          : this.questionType,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      calculation: data.calculation.present
          ? data.calculation.value
          : this.calculation,
      stem: data.stem.present ? data.stem.value : this.stem,
      images: data.images.present ? data.images.value : this.images,
      defaultScore: data.defaultScore.present
          ? data.defaultScore.value
          : this.defaultScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRow(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('examType: $examType, ')
          ..write('region: $region, ')
          ..write('number: $number, ')
          ..write('questionType: $questionType, ')
          ..write('difficulty: $difficulty, ')
          ..write('calculation: $calculation, ')
          ..write('stem: $stem, ')
          ..write('images: $images, ')
          ..write('defaultScore: $defaultScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    year,
    examType,
    region,
    number,
    questionType,
    difficulty,
    calculation,
    stem,
    images,
    defaultScore,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionRow &&
          other.id == this.id &&
          other.year == this.year &&
          other.examType == this.examType &&
          other.region == this.region &&
          other.number == this.number &&
          other.questionType == this.questionType &&
          other.difficulty == this.difficulty &&
          other.calculation == this.calculation &&
          other.stem == this.stem &&
          other.images == this.images &&
          other.defaultScore == this.defaultScore);
}

class QuestionsCompanion extends UpdateCompanion<QuestionRow> {
  final Value<int> id;
  final Value<int> year;
  final Value<String> examType;
  final Value<String> region;
  final Value<String> number;
  final Value<String> questionType;
  final Value<double?> difficulty;
  final Value<double?> calculation;
  final Value<String> stem;
  final Value<String?> images;
  final Value<double?> defaultScore;
  const QuestionsCompanion({
    this.id = const Value.absent(),
    this.year = const Value.absent(),
    this.examType = const Value.absent(),
    this.region = const Value.absent(),
    this.number = const Value.absent(),
    this.questionType = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.calculation = const Value.absent(),
    this.stem = const Value.absent(),
    this.images = const Value.absent(),
    this.defaultScore = const Value.absent(),
  });
  QuestionsCompanion.insert({
    this.id = const Value.absent(),
    required int year,
    required String examType,
    required String region,
    required String number,
    required String questionType,
    this.difficulty = const Value.absent(),
    this.calculation = const Value.absent(),
    required String stem,
    this.images = const Value.absent(),
    this.defaultScore = const Value.absent(),
  }) : year = Value(year),
       examType = Value(examType),
       region = Value(region),
       number = Value(number),
       questionType = Value(questionType),
       stem = Value(stem);
  static Insertable<QuestionRow> custom({
    Expression<int>? id,
    Expression<int>? year,
    Expression<String>? examType,
    Expression<String>? region,
    Expression<String>? number,
    Expression<String>? questionType,
    Expression<double>? difficulty,
    Expression<double>? calculation,
    Expression<String>? stem,
    Expression<String>? images,
    Expression<double>? defaultScore,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (year != null) 'year': year,
      if (examType != null) 'exam_type': examType,
      if (region != null) 'region': region,
      if (number != null) 'number': number,
      if (questionType != null) 'question_type': questionType,
      if (difficulty != null) 'difficulty': difficulty,
      if (calculation != null) 'calculation': calculation,
      if (stem != null) 'stem': stem,
      if (images != null) 'images': images,
      if (defaultScore != null) 'default_score': defaultScore,
    });
  }

  QuestionsCompanion copyWith({
    Value<int>? id,
    Value<int>? year,
    Value<String>? examType,
    Value<String>? region,
    Value<String>? number,
    Value<String>? questionType,
    Value<double?>? difficulty,
    Value<double?>? calculation,
    Value<String>? stem,
    Value<String?>? images,
    Value<double?>? defaultScore,
  }) {
    return QuestionsCompanion(
      id: id ?? this.id,
      year: year ?? this.year,
      examType: examType ?? this.examType,
      region: region ?? this.region,
      number: number ?? this.number,
      questionType: questionType ?? this.questionType,
      difficulty: difficulty ?? this.difficulty,
      calculation: calculation ?? this.calculation,
      stem: stem ?? this.stem,
      images: images ?? this.images,
      defaultScore: defaultScore ?? this.defaultScore,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (examType.present) {
      map['exam_type'] = Variable<String>(examType.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (questionType.present) {
      map['question_type'] = Variable<String>(questionType.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (calculation.present) {
      map['calculation'] = Variable<double>(calculation.value);
    }
    if (stem.present) {
      map['stem'] = Variable<String>(stem.value);
    }
    if (images.present) {
      map['images'] = Variable<String>(images.value);
    }
    if (defaultScore.present) {
      map['default_score'] = Variable<double>(defaultScore.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionsCompanion(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('examType: $examType, ')
          ..write('region: $region, ')
          ..write('number: $number, ')
          ..write('questionType: $questionType, ')
          ..write('difficulty: $difficulty, ')
          ..write('calculation: $calculation, ')
          ..write('stem: $stem, ')
          ..write('images: $images, ')
          ..write('defaultScore: $defaultScore')
          ..write(')'))
        .toString();
  }
}

class $ChoiceExtTable extends ChoiceExt
    with TableInfo<$ChoiceExtTable, ChoiceExtRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChoiceExtTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<int> questionId = GeneratedColumn<int>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'options',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, questionId, options];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'choice_ext';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChoiceExtRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['options']!, _optionsMeta),
      );
    } else if (isInserting) {
      context.missing(_optionsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChoiceExtRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChoiceExtRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_id'],
      )!,
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options'],
      )!,
    );
  }

  @override
  $ChoiceExtTable createAlias(String alias) {
    return $ChoiceExtTable(attachedDatabase, alias);
  }
}

class ChoiceExtRow extends DataClass implements Insertable<ChoiceExtRow> {
  final int id;
  final int questionId;
  final String options;
  const ChoiceExtRow({
    required this.id,
    required this.questionId,
    required this.options,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<int>(questionId);
    map['options'] = Variable<String>(options);
    return map;
  }

  ChoiceExtCompanion toCompanion(bool nullToAbsent) {
    return ChoiceExtCompanion(
      id: Value(id),
      questionId: Value(questionId),
      options: Value(options),
    );
  }

  factory ChoiceExtRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChoiceExtRow(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<int>(json['questionId']),
      options: serializer.fromJson<String>(json['options']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<int>(questionId),
      'options': serializer.toJson<String>(options),
    };
  }

  ChoiceExtRow copyWith({int? id, int? questionId, String? options}) =>
      ChoiceExtRow(
        id: id ?? this.id,
        questionId: questionId ?? this.questionId,
        options: options ?? this.options,
      );
  ChoiceExtRow copyWithCompanion(ChoiceExtCompanion data) {
    return ChoiceExtRow(
      id: data.id.present ? data.id.value : this.id,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      options: data.options.present ? data.options.value : this.options,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChoiceExtRow(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('options: $options')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionId, options);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChoiceExtRow &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.options == this.options);
}

class ChoiceExtCompanion extends UpdateCompanion<ChoiceExtRow> {
  final Value<int> id;
  final Value<int> questionId;
  final Value<String> options;
  const ChoiceExtCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.options = const Value.absent(),
  });
  ChoiceExtCompanion.insert({
    this.id = const Value.absent(),
    required int questionId,
    required String options,
  }) : questionId = Value(questionId),
       options = Value(options);
  static Insertable<ChoiceExtRow> custom({
    Expression<int>? id,
    Expression<int>? questionId,
    Expression<String>? options,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (options != null) 'options': options,
    });
  }

  ChoiceExtCompanion copyWith({
    Value<int>? id,
    Value<int>? questionId,
    Value<String>? options,
  }) {
    return ChoiceExtCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      options: options ?? this.options,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChoiceExtCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('options: $options')
          ..write(')'))
        .toString();
  }
}

class $SubQuestionsTable extends SubQuestions
    with TableInfo<$SubQuestionsTable, SubQuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<int> questionId = GeneratedColumn<int>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stemMeta = const VerificationMeta('stem');
  @override
  late final GeneratedColumn<String> stem = GeneratedColumn<String>(
    'stem',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questionId,
    parentId,
    stem,
    answer,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sub_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubQuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('stem')) {
      context.handle(
        _stemMeta,
        stem.isAcceptableOrUnknown(data['stem']!, _stemMeta),
      );
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubQuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubQuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      stem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stem'],
      ),
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $SubQuestionsTable createAlias(String alias) {
    return $SubQuestionsTable(attachedDatabase, alias);
  }
}

class SubQuestionRow extends DataClass implements Insertable<SubQuestionRow> {
  final int id;
  final int questionId;
  final int? parentId;
  final String? stem;
  final String? answer;
  final int sortOrder;
  const SubQuestionRow({
    required this.id,
    required this.questionId,
    this.parentId,
    this.stem,
    this.answer,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<int>(questionId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    if (!nullToAbsent || stem != null) {
      map['stem'] = Variable<String>(stem);
    }
    if (!nullToAbsent || answer != null) {
      map['answer'] = Variable<String>(answer);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  SubQuestionsCompanion toCompanion(bool nullToAbsent) {
    return SubQuestionsCompanion(
      id: Value(id),
      questionId: Value(questionId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      stem: stem == null && nullToAbsent ? const Value.absent() : Value(stem),
      answer: answer == null && nullToAbsent
          ? const Value.absent()
          : Value(answer),
      sortOrder: Value(sortOrder),
    );
  }

  factory SubQuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubQuestionRow(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<int>(json['questionId']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      stem: serializer.fromJson<String?>(json['stem']),
      answer: serializer.fromJson<String?>(json['answer']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<int>(questionId),
      'parentId': serializer.toJson<int?>(parentId),
      'stem': serializer.toJson<String?>(stem),
      'answer': serializer.toJson<String?>(answer),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  SubQuestionRow copyWith({
    int? id,
    int? questionId,
    Value<int?> parentId = const Value.absent(),
    Value<String?> stem = const Value.absent(),
    Value<String?> answer = const Value.absent(),
    int? sortOrder,
  }) => SubQuestionRow(
    id: id ?? this.id,
    questionId: questionId ?? this.questionId,
    parentId: parentId.present ? parentId.value : this.parentId,
    stem: stem.present ? stem.value : this.stem,
    answer: answer.present ? answer.value : this.answer,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  SubQuestionRow copyWithCompanion(SubQuestionsCompanion data) {
    return SubQuestionRow(
      id: data.id.present ? data.id.value : this.id,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      stem: data.stem.present ? data.stem.value : this.stem,
      answer: data.answer.present ? data.answer.value : this.answer,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubQuestionRow(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('parentId: $parentId, ')
          ..write('stem: $stem, ')
          ..write('answer: $answer, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, questionId, parentId, stem, answer, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubQuestionRow &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.parentId == this.parentId &&
          other.stem == this.stem &&
          other.answer == this.answer &&
          other.sortOrder == this.sortOrder);
}

class SubQuestionsCompanion extends UpdateCompanion<SubQuestionRow> {
  final Value<int> id;
  final Value<int> questionId;
  final Value<int?> parentId;
  final Value<String?> stem;
  final Value<String?> answer;
  final Value<int> sortOrder;
  const SubQuestionsCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.stem = const Value.absent(),
    this.answer = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  SubQuestionsCompanion.insert({
    this.id = const Value.absent(),
    required int questionId,
    this.parentId = const Value.absent(),
    this.stem = const Value.absent(),
    this.answer = const Value.absent(),
    required int sortOrder,
  }) : questionId = Value(questionId),
       sortOrder = Value(sortOrder);
  static Insertable<SubQuestionRow> custom({
    Expression<int>? id,
    Expression<int>? questionId,
    Expression<int>? parentId,
    Expression<String>? stem,
    Expression<String>? answer,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (parentId != null) 'parent_id': parentId,
      if (stem != null) 'stem': stem,
      if (answer != null) 'answer': answer,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  SubQuestionsCompanion copyWith({
    Value<int>? id,
    Value<int>? questionId,
    Value<int?>? parentId,
    Value<String?>? stem,
    Value<String?>? answer,
    Value<int>? sortOrder,
  }) {
    return SubQuestionsCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      parentId: parentId ?? this.parentId,
      stem: stem ?? this.stem,
      answer: answer ?? this.answer,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (stem.present) {
      map['stem'] = Variable<String>(stem.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('parentId: $parentId, ')
          ..write('stem: $stem, ')
          ..write('answer: $answer, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $SolutionMethodsTable extends SolutionMethods
    with TableInfo<$SolutionMethodsTable, SolutionMethodRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SolutionMethodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _subQuestionIdMeta = const VerificationMeta(
    'subQuestionId',
  );
  @override
  late final GeneratedColumn<int> subQuestionId = GeneratedColumn<int>(
    'sub_question_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodNameMeta = const VerificationMeta(
    'methodName',
  );
  @override
  late final GeneratedColumn<String> methodName = GeneratedColumn<String>(
    'method_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subQuestionId,
    methodName,
    source,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'solution_methods';
  @override
  VerificationContext validateIntegrity(
    Insertable<SolutionMethodRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sub_question_id')) {
      context.handle(
        _subQuestionIdMeta,
        subQuestionId.isAcceptableOrUnknown(
          data['sub_question_id']!,
          _subQuestionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subQuestionIdMeta);
    }
    if (data.containsKey('method_name')) {
      context.handle(
        _methodNameMeta,
        methodName.isAcceptableOrUnknown(data['method_name']!, _methodNameMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SolutionMethodRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SolutionMethodRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subQuestionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sub_question_id'],
      )!,
      methodName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method_name'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $SolutionMethodsTable createAlias(String alias) {
    return $SolutionMethodsTable(attachedDatabase, alias);
  }
}

class SolutionMethodRow extends DataClass
    implements Insertable<SolutionMethodRow> {
  final int id;
  final int subQuestionId;
  final String? methodName;
  final String? source;
  final int sortOrder;
  const SolutionMethodRow({
    required this.id,
    required this.subQuestionId,
    this.methodName,
    this.source,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sub_question_id'] = Variable<int>(subQuestionId);
    if (!nullToAbsent || methodName != null) {
      map['method_name'] = Variable<String>(methodName);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  SolutionMethodsCompanion toCompanion(bool nullToAbsent) {
    return SolutionMethodsCompanion(
      id: Value(id),
      subQuestionId: Value(subQuestionId),
      methodName: methodName == null && nullToAbsent
          ? const Value.absent()
          : Value(methodName),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      sortOrder: Value(sortOrder),
    );
  }

  factory SolutionMethodRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SolutionMethodRow(
      id: serializer.fromJson<int>(json['id']),
      subQuestionId: serializer.fromJson<int>(json['subQuestionId']),
      methodName: serializer.fromJson<String?>(json['methodName']),
      source: serializer.fromJson<String?>(json['source']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subQuestionId': serializer.toJson<int>(subQuestionId),
      'methodName': serializer.toJson<String?>(methodName),
      'source': serializer.toJson<String?>(source),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  SolutionMethodRow copyWith({
    int? id,
    int? subQuestionId,
    Value<String?> methodName = const Value.absent(),
    Value<String?> source = const Value.absent(),
    int? sortOrder,
  }) => SolutionMethodRow(
    id: id ?? this.id,
    subQuestionId: subQuestionId ?? this.subQuestionId,
    methodName: methodName.present ? methodName.value : this.methodName,
    source: source.present ? source.value : this.source,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  SolutionMethodRow copyWithCompanion(SolutionMethodsCompanion data) {
    return SolutionMethodRow(
      id: data.id.present ? data.id.value : this.id,
      subQuestionId: data.subQuestionId.present
          ? data.subQuestionId.value
          : this.subQuestionId,
      methodName: data.methodName.present
          ? data.methodName.value
          : this.methodName,
      source: data.source.present ? data.source.value : this.source,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SolutionMethodRow(')
          ..write('id: $id, ')
          ..write('subQuestionId: $subQuestionId, ')
          ..write('methodName: $methodName, ')
          ..write('source: $source, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, subQuestionId, methodName, source, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SolutionMethodRow &&
          other.id == this.id &&
          other.subQuestionId == this.subQuestionId &&
          other.methodName == this.methodName &&
          other.source == this.source &&
          other.sortOrder == this.sortOrder);
}

class SolutionMethodsCompanion extends UpdateCompanion<SolutionMethodRow> {
  final Value<int> id;
  final Value<int> subQuestionId;
  final Value<String?> methodName;
  final Value<String?> source;
  final Value<int> sortOrder;
  const SolutionMethodsCompanion({
    this.id = const Value.absent(),
    this.subQuestionId = const Value.absent(),
    this.methodName = const Value.absent(),
    this.source = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  SolutionMethodsCompanion.insert({
    this.id = const Value.absent(),
    required int subQuestionId,
    this.methodName = const Value.absent(),
    this.source = const Value.absent(),
    required int sortOrder,
  }) : subQuestionId = Value(subQuestionId),
       sortOrder = Value(sortOrder);
  static Insertable<SolutionMethodRow> custom({
    Expression<int>? id,
    Expression<int>? subQuestionId,
    Expression<String>? methodName,
    Expression<String>? source,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subQuestionId != null) 'sub_question_id': subQuestionId,
      if (methodName != null) 'method_name': methodName,
      if (source != null) 'source': source,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  SolutionMethodsCompanion copyWith({
    Value<int>? id,
    Value<int>? subQuestionId,
    Value<String?>? methodName,
    Value<String?>? source,
    Value<int>? sortOrder,
  }) {
    return SolutionMethodsCompanion(
      id: id ?? this.id,
      subQuestionId: subQuestionId ?? this.subQuestionId,
      methodName: methodName ?? this.methodName,
      source: source ?? this.source,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subQuestionId.present) {
      map['sub_question_id'] = Variable<int>(subQuestionId.value);
    }
    if (methodName.present) {
      map['method_name'] = Variable<String>(methodName.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SolutionMethodsCompanion(')
          ..write('id: $id, ')
          ..write('subQuestionId: $subQuestionId, ')
          ..write('methodName: $methodName, ')
          ..write('source: $source, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $SolutionStepsTable extends SolutionSteps
    with TableInfo<$SolutionStepsTable, SolutionStepRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SolutionStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _methodIdMeta = const VerificationMeta(
    'methodId',
  );
  @override
  late final GeneratedColumn<int> methodId = GeneratedColumn<int>(
    'method_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepNumberMeta = const VerificationMeta(
    'stepNumber',
  );
  @override
  late final GeneratedColumn<int> stepNumber = GeneratedColumn<int>(
    'step_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardTitlesMeta = const VerificationMeta(
    'cardTitles',
  );
  @override
  late final GeneratedColumn<String> cardTitles = GeneratedColumn<String>(
    'card_titles',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    methodId,
    stepNumber,
    title,
    content,
    cardTitles,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'solution_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<SolutionStepRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('method_id')) {
      context.handle(
        _methodIdMeta,
        methodId.isAcceptableOrUnknown(data['method_id']!, _methodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_methodIdMeta);
    }
    if (data.containsKey('step_number')) {
      context.handle(
        _stepNumberMeta,
        stepNumber.isAcceptableOrUnknown(data['step_number']!, _stepNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_stepNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('card_titles')) {
      context.handle(
        _cardTitlesMeta,
        cardTitles.isAcceptableOrUnknown(data['card_titles']!, _cardTitlesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SolutionStepRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SolutionStepRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      methodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}method_id'],
      )!,
      stepNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_number'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      cardTitles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_titles'],
      ),
    );
  }

  @override
  $SolutionStepsTable createAlias(String alias) {
    return $SolutionStepsTable(attachedDatabase, alias);
  }
}

class SolutionStepRow extends DataClass implements Insertable<SolutionStepRow> {
  final int id;
  final int methodId;
  final int stepNumber;
  final String title;
  final String content;
  final String? cardTitles;
  const SolutionStepRow({
    required this.id,
    required this.methodId,
    required this.stepNumber,
    required this.title,
    required this.content,
    this.cardTitles,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['method_id'] = Variable<int>(methodId);
    map['step_number'] = Variable<int>(stepNumber);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || cardTitles != null) {
      map['card_titles'] = Variable<String>(cardTitles);
    }
    return map;
  }

  SolutionStepsCompanion toCompanion(bool nullToAbsent) {
    return SolutionStepsCompanion(
      id: Value(id),
      methodId: Value(methodId),
      stepNumber: Value(stepNumber),
      title: Value(title),
      content: Value(content),
      cardTitles: cardTitles == null && nullToAbsent
          ? const Value.absent()
          : Value(cardTitles),
    );
  }

  factory SolutionStepRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SolutionStepRow(
      id: serializer.fromJson<int>(json['id']),
      methodId: serializer.fromJson<int>(json['methodId']),
      stepNumber: serializer.fromJson<int>(json['stepNumber']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      cardTitles: serializer.fromJson<String?>(json['cardTitles']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'methodId': serializer.toJson<int>(methodId),
      'stepNumber': serializer.toJson<int>(stepNumber),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'cardTitles': serializer.toJson<String?>(cardTitles),
    };
  }

  SolutionStepRow copyWith({
    int? id,
    int? methodId,
    int? stepNumber,
    String? title,
    String? content,
    Value<String?> cardTitles = const Value.absent(),
  }) => SolutionStepRow(
    id: id ?? this.id,
    methodId: methodId ?? this.methodId,
    stepNumber: stepNumber ?? this.stepNumber,
    title: title ?? this.title,
    content: content ?? this.content,
    cardTitles: cardTitles.present ? cardTitles.value : this.cardTitles,
  );
  SolutionStepRow copyWithCompanion(SolutionStepsCompanion data) {
    return SolutionStepRow(
      id: data.id.present ? data.id.value : this.id,
      methodId: data.methodId.present ? data.methodId.value : this.methodId,
      stepNumber: data.stepNumber.present
          ? data.stepNumber.value
          : this.stepNumber,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      cardTitles: data.cardTitles.present
          ? data.cardTitles.value
          : this.cardTitles,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SolutionStepRow(')
          ..write('id: $id, ')
          ..write('methodId: $methodId, ')
          ..write('stepNumber: $stepNumber, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('cardTitles: $cardTitles')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, methodId, stepNumber, title, content, cardTitles);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SolutionStepRow &&
          other.id == this.id &&
          other.methodId == this.methodId &&
          other.stepNumber == this.stepNumber &&
          other.title == this.title &&
          other.content == this.content &&
          other.cardTitles == this.cardTitles);
}

class SolutionStepsCompanion extends UpdateCompanion<SolutionStepRow> {
  final Value<int> id;
  final Value<int> methodId;
  final Value<int> stepNumber;
  final Value<String> title;
  final Value<String> content;
  final Value<String?> cardTitles;
  const SolutionStepsCompanion({
    this.id = const Value.absent(),
    this.methodId = const Value.absent(),
    this.stepNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.cardTitles = const Value.absent(),
  });
  SolutionStepsCompanion.insert({
    this.id = const Value.absent(),
    required int methodId,
    required int stepNumber,
    required String title,
    required String content,
    this.cardTitles = const Value.absent(),
  }) : methodId = Value(methodId),
       stepNumber = Value(stepNumber),
       title = Value(title),
       content = Value(content);
  static Insertable<SolutionStepRow> custom({
    Expression<int>? id,
    Expression<int>? methodId,
    Expression<int>? stepNumber,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? cardTitles,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (methodId != null) 'method_id': methodId,
      if (stepNumber != null) 'step_number': stepNumber,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (cardTitles != null) 'card_titles': cardTitles,
    });
  }

  SolutionStepsCompanion copyWith({
    Value<int>? id,
    Value<int>? methodId,
    Value<int>? stepNumber,
    Value<String>? title,
    Value<String>? content,
    Value<String?>? cardTitles,
  }) {
    return SolutionStepsCompanion(
      id: id ?? this.id,
      methodId: methodId ?? this.methodId,
      stepNumber: stepNumber ?? this.stepNumber,
      title: title ?? this.title,
      content: content ?? this.content,
      cardTitles: cardTitles ?? this.cardTitles,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (methodId.present) {
      map['method_id'] = Variable<int>(methodId.value);
    }
    if (stepNumber.present) {
      map['step_number'] = Variable<int>(stepNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (cardTitles.present) {
      map['card_titles'] = Variable<String>(cardTitles.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SolutionStepsCompanion(')
          ..write('id: $id, ')
          ..write('methodId: $methodId, ')
          ..write('stepNumber: $stepNumber, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('cardTitles: $cardTitles')
          ..write(')'))
        .toString();
  }
}

class $ConceptTagsTable extends ConceptTags
    with TableInfo<$ConceptTagsTable, ConceptTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConceptTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, parentId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'concept_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConceptTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConceptTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConceptTagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
    );
  }

  @override
  $ConceptTagsTable createAlias(String alias) {
    return $ConceptTagsTable(attachedDatabase, alias);
  }
}

class ConceptTagRow extends DataClass implements Insertable<ConceptTagRow> {
  final int id;
  final String name;
  final int? parentId;
  const ConceptTagRow({required this.id, required this.name, this.parentId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    return map;
  }

  ConceptTagsCompanion toCompanion(bool nullToAbsent) {
    return ConceptTagsCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
    );
  }

  factory ConceptTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConceptTagRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<int?>(json['parentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<int?>(parentId),
    };
  }

  ConceptTagRow copyWith({
    int? id,
    String? name,
    Value<int?> parentId = const Value.absent(),
  }) => ConceptTagRow(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
  );
  ConceptTagRow copyWithCompanion(ConceptTagsCompanion data) {
    return ConceptTagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConceptTagRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, parentId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConceptTagRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId);
}

class ConceptTagsCompanion extends UpdateCompanion<ConceptTagRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> parentId;
  const ConceptTagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
  });
  ConceptTagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.parentId = const Value.absent(),
  }) : name = Value(name);
  static Insertable<ConceptTagRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? parentId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
    });
  }

  ConceptTagsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? parentId,
  }) {
    return ConceptTagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConceptTagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId')
          ..write(')'))
        .toString();
  }
}

class $KnowledgeCardsTable extends KnowledgeCards
    with TableInfo<$KnowledgeCardsTable, KnowledgeCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnowledgeCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, category, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'knowledge_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<KnowledgeCardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KnowledgeCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnowledgeCardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
    );
  }

  @override
  $KnowledgeCardsTable createAlias(String alias) {
    return $KnowledgeCardsTable(attachedDatabase, alias);
  }
}

class KnowledgeCardRow extends DataClass
    implements Insertable<KnowledgeCardRow> {
  final int id;
  final String title;
  final String category;
  final String content;
  const KnowledgeCardRow({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['content'] = Variable<String>(content);
    return map;
  }

  KnowledgeCardsCompanion toCompanion(bool nullToAbsent) {
    return KnowledgeCardsCompanion(
      id: Value(id),
      title: Value(title),
      category: Value(category),
      content: Value(content),
    );
  }

  factory KnowledgeCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnowledgeCardRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'content': serializer.toJson<String>(content),
    };
  }

  KnowledgeCardRow copyWith({
    int? id,
    String? title,
    String? category,
    String? content,
  }) => KnowledgeCardRow(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category ?? this.category,
    content: content ?? this.content,
  );
  KnowledgeCardRow copyWithCompanion(KnowledgeCardsCompanion data) {
    return KnowledgeCardRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeCardRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, category, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnowledgeCardRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.category == this.category &&
          other.content == this.content);
}

class KnowledgeCardsCompanion extends UpdateCompanion<KnowledgeCardRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> category;
  final Value<String> content;
  const KnowledgeCardsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.content = const Value.absent(),
  });
  KnowledgeCardsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String category,
    required String content,
  }) : title = Value(title),
       category = Value(category),
       content = Value(content);
  static Insertable<KnowledgeCardRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (content != null) 'content': content,
    });
  }

  KnowledgeCardsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? category,
    Value<String>? content,
  }) {
    return KnowledgeCardsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeCardsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

class $QuestionConceptTagsTable extends QuestionConceptTags
    with TableInfo<$QuestionConceptTagsTable, QuestionConceptTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionConceptTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<int> questionId = GeneratedColumn<int>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conceptTagIdMeta = const VerificationMeta(
    'conceptTagId',
  );
  @override
  late final GeneratedColumn<int> conceptTagId = GeneratedColumn<int>(
    'concept_tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, questionId, conceptTagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_concept_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionConceptTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('concept_tag_id')) {
      context.handle(
        _conceptTagIdMeta,
        conceptTagId.isAcceptableOrUnknown(
          data['concept_tag_id']!,
          _conceptTagIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conceptTagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionConceptTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionConceptTagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_id'],
      )!,
      conceptTagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}concept_tag_id'],
      )!,
    );
  }

  @override
  $QuestionConceptTagsTable createAlias(String alias) {
    return $QuestionConceptTagsTable(attachedDatabase, alias);
  }
}

class QuestionConceptTagRow extends DataClass
    implements Insertable<QuestionConceptTagRow> {
  final int id;
  final int questionId;
  final int conceptTagId;
  const QuestionConceptTagRow({
    required this.id,
    required this.questionId,
    required this.conceptTagId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<int>(questionId);
    map['concept_tag_id'] = Variable<int>(conceptTagId);
    return map;
  }

  QuestionConceptTagsCompanion toCompanion(bool nullToAbsent) {
    return QuestionConceptTagsCompanion(
      id: Value(id),
      questionId: Value(questionId),
      conceptTagId: Value(conceptTagId),
    );
  }

  factory QuestionConceptTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionConceptTagRow(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<int>(json['questionId']),
      conceptTagId: serializer.fromJson<int>(json['conceptTagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<int>(questionId),
      'conceptTagId': serializer.toJson<int>(conceptTagId),
    };
  }

  QuestionConceptTagRow copyWith({
    int? id,
    int? questionId,
    int? conceptTagId,
  }) => QuestionConceptTagRow(
    id: id ?? this.id,
    questionId: questionId ?? this.questionId,
    conceptTagId: conceptTagId ?? this.conceptTagId,
  );
  QuestionConceptTagRow copyWithCompanion(QuestionConceptTagsCompanion data) {
    return QuestionConceptTagRow(
      id: data.id.present ? data.id.value : this.id,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      conceptTagId: data.conceptTagId.present
          ? data.conceptTagId.value
          : this.conceptTagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionConceptTagRow(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('conceptTagId: $conceptTagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionId, conceptTagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionConceptTagRow &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.conceptTagId == this.conceptTagId);
}

class QuestionConceptTagsCompanion
    extends UpdateCompanion<QuestionConceptTagRow> {
  final Value<int> id;
  final Value<int> questionId;
  final Value<int> conceptTagId;
  const QuestionConceptTagsCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.conceptTagId = const Value.absent(),
  });
  QuestionConceptTagsCompanion.insert({
    this.id = const Value.absent(),
    required int questionId,
    required int conceptTagId,
  }) : questionId = Value(questionId),
       conceptTagId = Value(conceptTagId);
  static Insertable<QuestionConceptTagRow> custom({
    Expression<int>? id,
    Expression<int>? questionId,
    Expression<int>? conceptTagId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (conceptTagId != null) 'concept_tag_id': conceptTagId,
    });
  }

  QuestionConceptTagsCompanion copyWith({
    Value<int>? id,
    Value<int>? questionId,
    Value<int>? conceptTagId,
  }) {
    return QuestionConceptTagsCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      conceptTagId: conceptTagId ?? this.conceptTagId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (conceptTagId.present) {
      map['concept_tag_id'] = Variable<int>(conceptTagId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionConceptTagsCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('conceptTagId: $conceptTagId')
          ..write(')'))
        .toString();
  }
}

class $QuestionKnowledgeCardsTable extends QuestionKnowledgeCards
    with TableInfo<$QuestionKnowledgeCardsTable, QuestionKnowledgeCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionKnowledgeCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<int> questionId = GeneratedColumn<int>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _knowledgeCardIdMeta = const VerificationMeta(
    'knowledgeCardId',
  );
  @override
  late final GeneratedColumn<int> knowledgeCardId = GeneratedColumn<int>(
    'knowledge_card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, questionId, knowledgeCardId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_knowledge_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionKnowledgeCardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('knowledge_card_id')) {
      context.handle(
        _knowledgeCardIdMeta,
        knowledgeCardId.isAcceptableOrUnknown(
          data['knowledge_card_id']!,
          _knowledgeCardIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_knowledgeCardIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionKnowledgeCardRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionKnowledgeCardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_id'],
      )!,
      knowledgeCardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}knowledge_card_id'],
      )!,
    );
  }

  @override
  $QuestionKnowledgeCardsTable createAlias(String alias) {
    return $QuestionKnowledgeCardsTable(attachedDatabase, alias);
  }
}

class QuestionKnowledgeCardRow extends DataClass
    implements Insertable<QuestionKnowledgeCardRow> {
  final int id;
  final int questionId;
  final int knowledgeCardId;
  const QuestionKnowledgeCardRow({
    required this.id,
    required this.questionId,
    required this.knowledgeCardId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<int>(questionId);
    map['knowledge_card_id'] = Variable<int>(knowledgeCardId);
    return map;
  }

  QuestionKnowledgeCardsCompanion toCompanion(bool nullToAbsent) {
    return QuestionKnowledgeCardsCompanion(
      id: Value(id),
      questionId: Value(questionId),
      knowledgeCardId: Value(knowledgeCardId),
    );
  }

  factory QuestionKnowledgeCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionKnowledgeCardRow(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<int>(json['questionId']),
      knowledgeCardId: serializer.fromJson<int>(json['knowledgeCardId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<int>(questionId),
      'knowledgeCardId': serializer.toJson<int>(knowledgeCardId),
    };
  }

  QuestionKnowledgeCardRow copyWith({
    int? id,
    int? questionId,
    int? knowledgeCardId,
  }) => QuestionKnowledgeCardRow(
    id: id ?? this.id,
    questionId: questionId ?? this.questionId,
    knowledgeCardId: knowledgeCardId ?? this.knowledgeCardId,
  );
  QuestionKnowledgeCardRow copyWithCompanion(
    QuestionKnowledgeCardsCompanion data,
  ) {
    return QuestionKnowledgeCardRow(
      id: data.id.present ? data.id.value : this.id,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      knowledgeCardId: data.knowledgeCardId.present
          ? data.knowledgeCardId.value
          : this.knowledgeCardId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionKnowledgeCardRow(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('knowledgeCardId: $knowledgeCardId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionId, knowledgeCardId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionKnowledgeCardRow &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.knowledgeCardId == this.knowledgeCardId);
}

class QuestionKnowledgeCardsCompanion
    extends UpdateCompanion<QuestionKnowledgeCardRow> {
  final Value<int> id;
  final Value<int> questionId;
  final Value<int> knowledgeCardId;
  const QuestionKnowledgeCardsCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.knowledgeCardId = const Value.absent(),
  });
  QuestionKnowledgeCardsCompanion.insert({
    this.id = const Value.absent(),
    required int questionId,
    required int knowledgeCardId,
  }) : questionId = Value(questionId),
       knowledgeCardId = Value(knowledgeCardId);
  static Insertable<QuestionKnowledgeCardRow> custom({
    Expression<int>? id,
    Expression<int>? questionId,
    Expression<int>? knowledgeCardId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (knowledgeCardId != null) 'knowledge_card_id': knowledgeCardId,
    });
  }

  QuestionKnowledgeCardsCompanion copyWith({
    Value<int>? id,
    Value<int>? questionId,
    Value<int>? knowledgeCardId,
  }) {
    return QuestionKnowledgeCardsCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      knowledgeCardId: knowledgeCardId ?? this.knowledgeCardId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (knowledgeCardId.present) {
      map['knowledge_card_id'] = Variable<int>(knowledgeCardId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionKnowledgeCardsCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('knowledgeCardId: $knowledgeCardId')
          ..write(')'))
        .toString();
  }
}

class $CoursesTable extends Courses with TableInfo<$CoursesTable, CourseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $CoursesTable createAlias(String alias) {
    return $CoursesTable(attachedDatabase, alias);
  }
}

class CourseRow extends DataClass implements Insertable<CourseRow> {
  final int id;
  final String name;
  final String? description;
  const CourseRow({required this.id, required this.name, this.description});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory CourseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
    };
  }

  CourseRow copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
  }) => CourseRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
  );
  CourseRow copyWithCompanion(CoursesCompanion data) {
    return CourseRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description);
}

class CoursesCompanion extends UpdateCompanion<CourseRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
  });
  CoursesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CourseRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    });
  }

  CoursesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
  }) {
    return CoursesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

class $AssignmentsTable extends Assignments
    with TableInfo<$AssignmentsTable, AssignmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<int> courseId = GeneratedColumn<int>(
    'course_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, description, courseId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssignmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssignmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssignmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_id'],
      ),
    );
  }

  @override
  $AssignmentsTable createAlias(String alias) {
    return $AssignmentsTable(attachedDatabase, alias);
  }
}

class AssignmentRow extends DataClass implements Insertable<AssignmentRow> {
  final int id;
  final String title;
  final String? description;
  final int? courseId;
  const AssignmentRow({
    required this.id,
    required this.title,
    this.description,
    this.courseId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || courseId != null) {
      map['course_id'] = Variable<int>(courseId);
    }
    return map;
  }

  AssignmentsCompanion toCompanion(bool nullToAbsent) {
    return AssignmentsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      courseId: courseId == null && nullToAbsent
          ? const Value.absent()
          : Value(courseId),
    );
  }

  factory AssignmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssignmentRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      courseId: serializer.fromJson<int?>(json['courseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'courseId': serializer.toJson<int?>(courseId),
    };
  }

  AssignmentRow copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<int?> courseId = const Value.absent(),
  }) => AssignmentRow(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    courseId: courseId.present ? courseId.value : this.courseId,
  );
  AssignmentRow copyWithCompanion(AssignmentsCompanion data) {
    return AssignmentRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssignmentRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('courseId: $courseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, description, courseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssignmentRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.courseId == this.courseId);
}

class AssignmentsCompanion extends UpdateCompanion<AssignmentRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int?> courseId;
  const AssignmentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.courseId = const Value.absent(),
  });
  AssignmentsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.courseId = const Value.absent(),
  }) : title = Value(title);
  static Insertable<AssignmentRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? courseId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (courseId != null) 'course_id': courseId,
    });
  }

  AssignmentsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<int?>? courseId,
  }) {
    return AssignmentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<int>(courseId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssignmentsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('courseId: $courseId')
          ..write(')'))
        .toString();
  }
}

class $AssignmentQuestionsTable extends AssignmentQuestions
    with TableInfo<$AssignmentQuestionsTable, AssignmentQuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssignmentQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _assignmentIdMeta = const VerificationMeta(
    'assignmentId',
  );
  @override
  late final GeneratedColumn<int> assignmentId = GeneratedColumn<int>(
    'assignment_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<int> questionId = GeneratedColumn<int>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assignmentId,
    questionId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assignment_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssignmentQuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('assignment_id')) {
      context.handle(
        _assignmentIdMeta,
        assignmentId.isAcceptableOrUnknown(
          data['assignment_id']!,
          _assignmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assignmentIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssignmentQuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssignmentQuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      assignmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}assignment_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AssignmentQuestionsTable createAlias(String alias) {
    return $AssignmentQuestionsTable(attachedDatabase, alias);
  }
}

class AssignmentQuestionRow extends DataClass
    implements Insertable<AssignmentQuestionRow> {
  final int id;
  final int assignmentId;
  final int questionId;
  final int sortOrder;
  const AssignmentQuestionRow({
    required this.id,
    required this.assignmentId,
    required this.questionId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['assignment_id'] = Variable<int>(assignmentId);
    map['question_id'] = Variable<int>(questionId);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AssignmentQuestionsCompanion toCompanion(bool nullToAbsent) {
    return AssignmentQuestionsCompanion(
      id: Value(id),
      assignmentId: Value(assignmentId),
      questionId: Value(questionId),
      sortOrder: Value(sortOrder),
    );
  }

  factory AssignmentQuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssignmentQuestionRow(
      id: serializer.fromJson<int>(json['id']),
      assignmentId: serializer.fromJson<int>(json['assignmentId']),
      questionId: serializer.fromJson<int>(json['questionId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'assignmentId': serializer.toJson<int>(assignmentId),
      'questionId': serializer.toJson<int>(questionId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AssignmentQuestionRow copyWith({
    int? id,
    int? assignmentId,
    int? questionId,
    int? sortOrder,
  }) => AssignmentQuestionRow(
    id: id ?? this.id,
    assignmentId: assignmentId ?? this.assignmentId,
    questionId: questionId ?? this.questionId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AssignmentQuestionRow copyWithCompanion(AssignmentQuestionsCompanion data) {
    return AssignmentQuestionRow(
      id: data.id.present ? data.id.value : this.id,
      assignmentId: data.assignmentId.present
          ? data.assignmentId.value
          : this.assignmentId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssignmentQuestionRow(')
          ..write('id: $id, ')
          ..write('assignmentId: $assignmentId, ')
          ..write('questionId: $questionId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, assignmentId, questionId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssignmentQuestionRow &&
          other.id == this.id &&
          other.assignmentId == this.assignmentId &&
          other.questionId == this.questionId &&
          other.sortOrder == this.sortOrder);
}

class AssignmentQuestionsCompanion
    extends UpdateCompanion<AssignmentQuestionRow> {
  final Value<int> id;
  final Value<int> assignmentId;
  final Value<int> questionId;
  final Value<int> sortOrder;
  const AssignmentQuestionsCompanion({
    this.id = const Value.absent(),
    this.assignmentId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  AssignmentQuestionsCompanion.insert({
    this.id = const Value.absent(),
    required int assignmentId,
    required int questionId,
    required int sortOrder,
  }) : assignmentId = Value(assignmentId),
       questionId = Value(questionId),
       sortOrder = Value(sortOrder);
  static Insertable<AssignmentQuestionRow> custom({
    Expression<int>? id,
    Expression<int>? assignmentId,
    Expression<int>? questionId,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assignmentId != null) 'assignment_id': assignmentId,
      if (questionId != null) 'question_id': questionId,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  AssignmentQuestionsCompanion copyWith({
    Value<int>? id,
    Value<int>? assignmentId,
    Value<int>? questionId,
    Value<int>? sortOrder,
  }) {
    return AssignmentQuestionsCompanion(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      questionId: questionId ?? this.questionId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (assignmentId.present) {
      map['assignment_id'] = Variable<int>(assignmentId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssignmentQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('assignmentId: $assignmentId, ')
          ..write('questionId: $questionId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $AchievementDefsTable extends AchievementDefs
    with TableInfo<$AchievementDefsTable, AchievementDefRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementDefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconEmojiMeta = const VerificationMeta(
    'iconEmoji',
  );
  @override
  late final GeneratedColumn<String> iconEmoji = GeneratedColumn<String>(
    'icon_emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryLabelMeta = const VerificationMeta(
    'categoryLabel',
  );
  @override
  late final GeneratedColumn<String> categoryLabel = GeneratedColumn<String>(
    'category_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _triggerTypeMeta = const VerificationMeta(
    'triggerType',
  );
  @override
  late final GeneratedColumn<String> triggerType = GeneratedColumn<String>(
    'trigger_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thresholdMeta = const VerificationMeta(
    'threshold',
  );
  @override
  late final GeneratedColumn<int> threshold = GeneratedColumn<int>(
    'threshold',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    description,
    icon,
    iconEmoji,
    category,
    categoryLabel,
    displayOrder,
    triggerType,
    threshold,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievement_defs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AchievementDefRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('icon_emoji')) {
      context.handle(
        _iconEmojiMeta,
        iconEmoji.isAcceptableOrUnknown(data['icon_emoji']!, _iconEmojiMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('category_label')) {
      context.handle(
        _categoryLabelMeta,
        categoryLabel.isAcceptableOrUnknown(
          data['category_label']!,
          _categoryLabelMeta,
        ),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    }
    if (data.containsKey('trigger_type')) {
      context.handle(
        _triggerTypeMeta,
        triggerType.isAcceptableOrUnknown(
          data['trigger_type']!,
          _triggerTypeMeta,
        ),
      );
    }
    if (data.containsKey('threshold')) {
      context.handle(
        _thresholdMeta,
        threshold.isAcceptableOrUnknown(data['threshold']!, _thresholdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AchievementDefRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AchievementDefRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      iconEmoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_emoji'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      categoryLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_label'],
      ),
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      ),
      triggerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger_type'],
      ),
      threshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}threshold'],
      ),
    );
  }

  @override
  $AchievementDefsTable createAlias(String alias) {
    return $AchievementDefsTable(attachedDatabase, alias);
  }
}

class AchievementDefRow extends DataClass
    implements Insertable<AchievementDefRow> {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String? icon;
  final String? iconEmoji;
  final String category;
  final String? categoryLabel;
  final int? displayOrder;
  final String? triggerType;
  final int? threshold;
  const AchievementDefRow({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.icon,
    this.iconEmoji,
    required this.category,
    this.categoryLabel,
    this.displayOrder,
    this.triggerType,
    this.threshold,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || iconEmoji != null) {
      map['icon_emoji'] = Variable<String>(iconEmoji);
    }
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || categoryLabel != null) {
      map['category_label'] = Variable<String>(categoryLabel);
    }
    if (!nullToAbsent || displayOrder != null) {
      map['display_order'] = Variable<int>(displayOrder);
    }
    if (!nullToAbsent || triggerType != null) {
      map['trigger_type'] = Variable<String>(triggerType);
    }
    if (!nullToAbsent || threshold != null) {
      map['threshold'] = Variable<int>(threshold);
    }
    return map;
  }

  AchievementDefsCompanion toCompanion(bool nullToAbsent) {
    return AchievementDefsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      iconEmoji: iconEmoji == null && nullToAbsent
          ? const Value.absent()
          : Value(iconEmoji),
      category: Value(category),
      categoryLabel: categoryLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryLabel),
      displayOrder: displayOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(displayOrder),
      triggerType: triggerType == null && nullToAbsent
          ? const Value.absent()
          : Value(triggerType),
      threshold: threshold == null && nullToAbsent
          ? const Value.absent()
          : Value(threshold),
    );
  }

  factory AchievementDefRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AchievementDefRow(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      icon: serializer.fromJson<String?>(json['icon']),
      iconEmoji: serializer.fromJson<String?>(json['iconEmoji']),
      category: serializer.fromJson<String>(json['category']),
      categoryLabel: serializer.fromJson<String?>(json['categoryLabel']),
      displayOrder: serializer.fromJson<int?>(json['displayOrder']),
      triggerType: serializer.fromJson<String?>(json['triggerType']),
      threshold: serializer.fromJson<int?>(json['threshold']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'icon': serializer.toJson<String?>(icon),
      'iconEmoji': serializer.toJson<String?>(iconEmoji),
      'category': serializer.toJson<String>(category),
      'categoryLabel': serializer.toJson<String?>(categoryLabel),
      'displayOrder': serializer.toJson<int?>(displayOrder),
      'triggerType': serializer.toJson<String?>(triggerType),
      'threshold': serializer.toJson<int?>(threshold),
    };
  }

  AchievementDefRow copyWith({
    int? id,
    String? code,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<String?> iconEmoji = const Value.absent(),
    String? category,
    Value<String?> categoryLabel = const Value.absent(),
    Value<int?> displayOrder = const Value.absent(),
    Value<String?> triggerType = const Value.absent(),
    Value<int?> threshold = const Value.absent(),
  }) => AchievementDefRow(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    icon: icon.present ? icon.value : this.icon,
    iconEmoji: iconEmoji.present ? iconEmoji.value : this.iconEmoji,
    category: category ?? this.category,
    categoryLabel: categoryLabel.present
        ? categoryLabel.value
        : this.categoryLabel,
    displayOrder: displayOrder.present ? displayOrder.value : this.displayOrder,
    triggerType: triggerType.present ? triggerType.value : this.triggerType,
    threshold: threshold.present ? threshold.value : this.threshold,
  );
  AchievementDefRow copyWithCompanion(AchievementDefsCompanion data) {
    return AchievementDefRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      icon: data.icon.present ? data.icon.value : this.icon,
      iconEmoji: data.iconEmoji.present ? data.iconEmoji.value : this.iconEmoji,
      category: data.category.present ? data.category.value : this.category,
      categoryLabel: data.categoryLabel.present
          ? data.categoryLabel.value
          : this.categoryLabel,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      triggerType: data.triggerType.present
          ? data.triggerType.value
          : this.triggerType,
      threshold: data.threshold.present ? data.threshold.value : this.threshold,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AchievementDefRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('iconEmoji: $iconEmoji, ')
          ..write('category: $category, ')
          ..write('categoryLabel: $categoryLabel, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('triggerType: $triggerType, ')
          ..write('threshold: $threshold')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    name,
    description,
    icon,
    iconEmoji,
    category,
    categoryLabel,
    displayOrder,
    triggerType,
    threshold,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AchievementDefRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.iconEmoji == this.iconEmoji &&
          other.category == this.category &&
          other.categoryLabel == this.categoryLabel &&
          other.displayOrder == this.displayOrder &&
          other.triggerType == this.triggerType &&
          other.threshold == this.threshold);
}

class AchievementDefsCompanion extends UpdateCompanion<AchievementDefRow> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> icon;
  final Value<String?> iconEmoji;
  final Value<String> category;
  final Value<String?> categoryLabel;
  final Value<int?> displayOrder;
  final Value<String?> triggerType;
  final Value<int?> threshold;
  const AchievementDefsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.iconEmoji = const Value.absent(),
    this.category = const Value.absent(),
    this.categoryLabel = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.triggerType = const Value.absent(),
    this.threshold = const Value.absent(),
  });
  AchievementDefsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String name,
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.iconEmoji = const Value.absent(),
    required String category,
    this.categoryLabel = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.triggerType = const Value.absent(),
    this.threshold = const Value.absent(),
  }) : code = Value(code),
       name = Value(name),
       category = Value(category);
  static Insertable<AchievementDefRow> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? icon,
    Expression<String>? iconEmoji,
    Expression<String>? category,
    Expression<String>? categoryLabel,
    Expression<int>? displayOrder,
    Expression<String>? triggerType,
    Expression<int>? threshold,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (iconEmoji != null) 'icon_emoji': iconEmoji,
      if (category != null) 'category': category,
      if (categoryLabel != null) 'category_label': categoryLabel,
      if (displayOrder != null) 'display_order': displayOrder,
      if (triggerType != null) 'trigger_type': triggerType,
      if (threshold != null) 'threshold': threshold,
    });
  }

  AchievementDefsCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? icon,
    Value<String?>? iconEmoji,
    Value<String>? category,
    Value<String?>? categoryLabel,
    Value<int?>? displayOrder,
    Value<String?>? triggerType,
    Value<int?>? threshold,
  }) {
    return AchievementDefsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      category: category ?? this.category,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      displayOrder: displayOrder ?? this.displayOrder,
      triggerType: triggerType ?? this.triggerType,
      threshold: threshold ?? this.threshold,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (iconEmoji.present) {
      map['icon_emoji'] = Variable<String>(iconEmoji.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (categoryLabel.present) {
      map['category_label'] = Variable<String>(categoryLabel.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (triggerType.present) {
      map['trigger_type'] = Variable<String>(triggerType.value);
    }
    if (threshold.present) {
      map['threshold'] = Variable<int>(threshold.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementDefsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('iconEmoji: $iconEmoji, ')
          ..write('category: $category, ')
          ..write('categoryLabel: $categoryLabel, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('triggerType: $triggerType, ')
          ..write('threshold: $threshold')
          ..write(')'))
        .toString();
  }
}

class $LevelConfigsTable extends LevelConfigs
    with TableInfo<$LevelConfigsTable, LevelConfigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LevelConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minXpMeta = const VerificationMeta('minXp');
  @override
  late final GeneratedColumn<int> minXp = GeneratedColumn<int>(
    'min_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconEmojiMeta = const VerificationMeta(
    'iconEmoji',
  );
  @override
  late final GeneratedColumn<String> iconEmoji = GeneratedColumn<String>(
    'icon_emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [level, minXp, title, iconEmoji];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'level_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LevelConfigRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('min_xp')) {
      context.handle(
        _minXpMeta,
        minXp.isAcceptableOrUnknown(data['min_xp']!, _minXpMeta),
      );
    } else if (isInserting) {
      context.missing(_minXpMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('icon_emoji')) {
      context.handle(
        _iconEmojiMeta,
        iconEmoji.isAcceptableOrUnknown(data['icon_emoji']!, _iconEmojiMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {level};
  @override
  LevelConfigRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LevelConfigRow(
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      minXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_xp'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      iconEmoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_emoji'],
      ),
    );
  }

  @override
  $LevelConfigsTable createAlias(String alias) {
    return $LevelConfigsTable(attachedDatabase, alias);
  }
}

class LevelConfigRow extends DataClass implements Insertable<LevelConfigRow> {
  final int level;
  final int minXp;
  final String title;
  final String? iconEmoji;
  const LevelConfigRow({
    required this.level,
    required this.minXp,
    required this.title,
    this.iconEmoji,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['level'] = Variable<int>(level);
    map['min_xp'] = Variable<int>(minXp);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || iconEmoji != null) {
      map['icon_emoji'] = Variable<String>(iconEmoji);
    }
    return map;
  }

  LevelConfigsCompanion toCompanion(bool nullToAbsent) {
    return LevelConfigsCompanion(
      level: Value(level),
      minXp: Value(minXp),
      title: Value(title),
      iconEmoji: iconEmoji == null && nullToAbsent
          ? const Value.absent()
          : Value(iconEmoji),
    );
  }

  factory LevelConfigRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LevelConfigRow(
      level: serializer.fromJson<int>(json['level']),
      minXp: serializer.fromJson<int>(json['minXp']),
      title: serializer.fromJson<String>(json['title']),
      iconEmoji: serializer.fromJson<String?>(json['iconEmoji']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'level': serializer.toJson<int>(level),
      'minXp': serializer.toJson<int>(minXp),
      'title': serializer.toJson<String>(title),
      'iconEmoji': serializer.toJson<String?>(iconEmoji),
    };
  }

  LevelConfigRow copyWith({
    int? level,
    int? minXp,
    String? title,
    Value<String?> iconEmoji = const Value.absent(),
  }) => LevelConfigRow(
    level: level ?? this.level,
    minXp: minXp ?? this.minXp,
    title: title ?? this.title,
    iconEmoji: iconEmoji.present ? iconEmoji.value : this.iconEmoji,
  );
  LevelConfigRow copyWithCompanion(LevelConfigsCompanion data) {
    return LevelConfigRow(
      level: data.level.present ? data.level.value : this.level,
      minXp: data.minXp.present ? data.minXp.value : this.minXp,
      title: data.title.present ? data.title.value : this.title,
      iconEmoji: data.iconEmoji.present ? data.iconEmoji.value : this.iconEmoji,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LevelConfigRow(')
          ..write('level: $level, ')
          ..write('minXp: $minXp, ')
          ..write('title: $title, ')
          ..write('iconEmoji: $iconEmoji')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(level, minXp, title, iconEmoji);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LevelConfigRow &&
          other.level == this.level &&
          other.minXp == this.minXp &&
          other.title == this.title &&
          other.iconEmoji == this.iconEmoji);
}

class LevelConfigsCompanion extends UpdateCompanion<LevelConfigRow> {
  final Value<int> level;
  final Value<int> minXp;
  final Value<String> title;
  final Value<String?> iconEmoji;
  const LevelConfigsCompanion({
    this.level = const Value.absent(),
    this.minXp = const Value.absent(),
    this.title = const Value.absent(),
    this.iconEmoji = const Value.absent(),
  });
  LevelConfigsCompanion.insert({
    this.level = const Value.absent(),
    required int minXp,
    required String title,
    this.iconEmoji = const Value.absent(),
  }) : minXp = Value(minXp),
       title = Value(title);
  static Insertable<LevelConfigRow> custom({
    Expression<int>? level,
    Expression<int>? minXp,
    Expression<String>? title,
    Expression<String>? iconEmoji,
  }) {
    return RawValuesInsertable({
      if (level != null) 'level': level,
      if (minXp != null) 'min_xp': minXp,
      if (title != null) 'title': title,
      if (iconEmoji != null) 'icon_emoji': iconEmoji,
    });
  }

  LevelConfigsCompanion copyWith({
    Value<int>? level,
    Value<int>? minXp,
    Value<String>? title,
    Value<String?>? iconEmoji,
  }) {
    return LevelConfigsCompanion(
      level: level ?? this.level,
      minXp: minXp ?? this.minXp,
      title: title ?? this.title,
      iconEmoji: iconEmoji ?? this.iconEmoji,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (minXp.present) {
      map['min_xp'] = Variable<int>(minXp.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (iconEmoji.present) {
      map['icon_emoji'] = Variable<String>(iconEmoji.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LevelConfigsCompanion(')
          ..write('level: $level, ')
          ..write('minXp: $minXp, ')
          ..write('title: $title, ')
          ..write('iconEmoji: $iconEmoji')
          ..write(')'))
        .toString();
  }
}

class $SystemConfigsTable extends SystemConfigs
    with TableInfo<$SystemConfigsTable, SystemConfigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SystemConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'system_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SystemConfigRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SystemConfigRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SystemConfigRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $SystemConfigsTable createAlias(String alias) {
    return $SystemConfigsTable(attachedDatabase, alias);
  }
}

class SystemConfigRow extends DataClass implements Insertable<SystemConfigRow> {
  final String key;
  final String value;
  final String? description;
  const SystemConfigRow({
    required this.key,
    required this.value,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  SystemConfigsCompanion toCompanion(bool nullToAbsent) {
    return SystemConfigsCompanion(
      key: Value(key),
      value: Value(value),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory SystemConfigRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SystemConfigRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'description': serializer.toJson<String?>(description),
    };
  }

  SystemConfigRow copyWith({
    String? key,
    String? value,
    Value<String?> description = const Value.absent(),
  }) => SystemConfigRow(
    key: key ?? this.key,
    value: value ?? this.value,
    description: description.present ? description.value : this.description,
  );
  SystemConfigRow copyWithCompanion(SystemConfigsCompanion data) {
    return SystemConfigRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SystemConfigRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SystemConfigRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.description == this.description);
}

class SystemConfigsCompanion extends UpdateCompanion<SystemConfigRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<String?> description;
  final Value<int> rowid;
  const SystemConfigsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SystemConfigsCompanion.insert({
    required String key,
    required String value,
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SystemConfigRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SystemConfigsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<String?>? description,
    Value<int>? rowid,
  }) {
    return SystemConfigsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SystemConfigsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetaTable extends Meta with TableInfo<$MetaTable, MetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataVersionMeta = const VerificationMeta(
    'dataVersion',
  );
  @override
  late final GeneratedColumn<int> dataVersion = GeneratedColumn<int>(
    'data_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _builtAtMeta = const VerificationMeta(
    'builtAt',
  );
  @override
  late final GeneratedColumn<String> builtAt = GeneratedColumn<String>(
    'built_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    schemaVersion,
    dataVersion,
    checksum,
    builtAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('data_version')) {
      context.handle(
        _dataVersionMeta,
        dataVersion.isAcceptableOrUnknown(
          data['data_version']!,
          _dataVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataVersionMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('built_at')) {
      context.handle(
        _builtAtMeta,
        builtAt.isAcceptableOrUnknown(data['built_at']!, _builtAtMeta),
      );
    } else if (isInserting) {
      context.missing(_builtAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  MetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaRow(
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      dataVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}data_version'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      builtAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}built_at'],
      )!,
    );
  }

  @override
  $MetaTable createAlias(String alias) {
    return $MetaTable(attachedDatabase, alias);
  }
}

class MetaRow extends DataClass implements Insertable<MetaRow> {
  final int schemaVersion;
  final int dataVersion;
  final String checksum;
  final String builtAt;
  const MetaRow({
    required this.schemaVersion,
    required this.dataVersion,
    required this.checksum,
    required this.builtAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['schema_version'] = Variable<int>(schemaVersion);
    map['data_version'] = Variable<int>(dataVersion);
    map['checksum'] = Variable<String>(checksum);
    map['built_at'] = Variable<String>(builtAt);
    return map;
  }

  MetaCompanion toCompanion(bool nullToAbsent) {
    return MetaCompanion(
      schemaVersion: Value(schemaVersion),
      dataVersion: Value(dataVersion),
      checksum: Value(checksum),
      builtAt: Value(builtAt),
    );
  }

  factory MetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaRow(
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      dataVersion: serializer.fromJson<int>(json['dataVersion']),
      checksum: serializer.fromJson<String>(json['checksum']),
      builtAt: serializer.fromJson<String>(json['builtAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'dataVersion': serializer.toJson<int>(dataVersion),
      'checksum': serializer.toJson<String>(checksum),
      'builtAt': serializer.toJson<String>(builtAt),
    };
  }

  MetaRow copyWith({
    int? schemaVersion,
    int? dataVersion,
    String? checksum,
    String? builtAt,
  }) => MetaRow(
    schemaVersion: schemaVersion ?? this.schemaVersion,
    dataVersion: dataVersion ?? this.dataVersion,
    checksum: checksum ?? this.checksum,
    builtAt: builtAt ?? this.builtAt,
  );
  MetaRow copyWithCompanion(MetaCompanion data) {
    return MetaRow(
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      dataVersion: data.dataVersion.present
          ? data.dataVersion.value
          : this.dataVersion,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      builtAt: data.builtAt.present ? data.builtAt.value : this.builtAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaRow(')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('dataVersion: $dataVersion, ')
          ..write('checksum: $checksum, ')
          ..write('builtAt: $builtAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(schemaVersion, dataVersion, checksum, builtAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaRow &&
          other.schemaVersion == this.schemaVersion &&
          other.dataVersion == this.dataVersion &&
          other.checksum == this.checksum &&
          other.builtAt == this.builtAt);
}

class MetaCompanion extends UpdateCompanion<MetaRow> {
  final Value<int> schemaVersion;
  final Value<int> dataVersion;
  final Value<String> checksum;
  final Value<String> builtAt;
  final Value<int> rowid;
  const MetaCompanion({
    this.schemaVersion = const Value.absent(),
    this.dataVersion = const Value.absent(),
    this.checksum = const Value.absent(),
    this.builtAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaCompanion.insert({
    required int schemaVersion,
    required int dataVersion,
    required String checksum,
    required String builtAt,
    this.rowid = const Value.absent(),
  }) : schemaVersion = Value(schemaVersion),
       dataVersion = Value(dataVersion),
       checksum = Value(checksum),
       builtAt = Value(builtAt);
  static Insertable<MetaRow> custom({
    Expression<int>? schemaVersion,
    Expression<int>? dataVersion,
    Expression<String>? checksum,
    Expression<String>? builtAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (dataVersion != null) 'data_version': dataVersion,
      if (checksum != null) 'checksum': checksum,
      if (builtAt != null) 'built_at': builtAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaCompanion copyWith({
    Value<int>? schemaVersion,
    Value<int>? dataVersion,
    Value<String>? checksum,
    Value<String>? builtAt,
    Value<int>? rowid,
  }) {
    return MetaCompanion(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      dataVersion: dataVersion ?? this.dataVersion,
      checksum: checksum ?? this.checksum,
      builtAt: builtAt ?? this.builtAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (dataVersion.present) {
      map['data_version'] = Variable<int>(dataVersion.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (builtAt.present) {
      map['built_at'] = Variable<String>(builtAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaCompanion(')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('dataVersion: $dataVersion, ')
          ..write('checksum: $checksum, ')
          ..write('builtAt: $builtAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AssetsDatabase extends GeneratedDatabase {
  _$AssetsDatabase(QueryExecutor e) : super(e);
  $AssetsDatabaseManager get managers => $AssetsDatabaseManager(this);
  late final $QuestionsTable questions = $QuestionsTable(this);
  late final $ChoiceExtTable choiceExt = $ChoiceExtTable(this);
  late final $SubQuestionsTable subQuestions = $SubQuestionsTable(this);
  late final $SolutionMethodsTable solutionMethods = $SolutionMethodsTable(
    this,
  );
  late final $SolutionStepsTable solutionSteps = $SolutionStepsTable(this);
  late final $ConceptTagsTable conceptTags = $ConceptTagsTable(this);
  late final $KnowledgeCardsTable knowledgeCards = $KnowledgeCardsTable(this);
  late final $QuestionConceptTagsTable questionConceptTags =
      $QuestionConceptTagsTable(this);
  late final $QuestionKnowledgeCardsTable questionKnowledgeCards =
      $QuestionKnowledgeCardsTable(this);
  late final $CoursesTable courses = $CoursesTable(this);
  late final $AssignmentsTable assignments = $AssignmentsTable(this);
  late final $AssignmentQuestionsTable assignmentQuestions =
      $AssignmentQuestionsTable(this);
  late final $AchievementDefsTable achievementDefs = $AchievementDefsTable(
    this,
  );
  late final $LevelConfigsTable levelConfigs = $LevelConfigsTable(this);
  late final $SystemConfigsTable systemConfigs = $SystemConfigsTable(this);
  late final $MetaTable meta = $MetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    questions,
    choiceExt,
    subQuestions,
    solutionMethods,
    solutionSteps,
    conceptTags,
    knowledgeCards,
    questionConceptTags,
    questionKnowledgeCards,
    courses,
    assignments,
    assignmentQuestions,
    achievementDefs,
    levelConfigs,
    systemConfigs,
    meta,
  ];
}

typedef $$QuestionsTableCreateCompanionBuilder =
    QuestionsCompanion Function({
      Value<int> id,
      required int year,
      required String examType,
      required String region,
      required String number,
      required String questionType,
      Value<double?> difficulty,
      Value<double?> calculation,
      required String stem,
      Value<String?> images,
      Value<double?> defaultScore,
    });
typedef $$QuestionsTableUpdateCompanionBuilder =
    QuestionsCompanion Function({
      Value<int> id,
      Value<int> year,
      Value<String> examType,
      Value<String> region,
      Value<String> number,
      Value<String> questionType,
      Value<double?> difficulty,
      Value<double?> calculation,
      Value<String> stem,
      Value<String?> images,
      Value<double?> defaultScore,
    });

class $$QuestionsTableFilterComposer
    extends Composer<_$AssetsDatabase, $QuestionsTable> {
  $$QuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get examType => $composableBuilder(
    column: $table.examType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calculation => $composableBuilder(
    column: $table.calculation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stem => $composableBuilder(
    column: $table.stem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultScore => $composableBuilder(
    column: $table.defaultScore,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestionsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $QuestionsTable> {
  $$QuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examType => $composableBuilder(
    column: $table.examType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calculation => $composableBuilder(
    column: $table.calculation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stem => $composableBuilder(
    column: $table.stem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultScore => $composableBuilder(
    column: $table.defaultScore,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestionsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $QuestionsTable> {
  $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get examType =>
      $composableBuilder(column: $table.examType, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calculation => $composableBuilder(
    column: $table.calculation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stem =>
      $composableBuilder(column: $table.stem, builder: (column) => column);

  GeneratedColumn<String> get images =>
      $composableBuilder(column: $table.images, builder: (column) => column);

  GeneratedColumn<double> get defaultScore => $composableBuilder(
    column: $table.defaultScore,
    builder: (column) => column,
  );
}

class $$QuestionsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $QuestionsTable,
          QuestionRow,
          $$QuestionsTableFilterComposer,
          $$QuestionsTableOrderingComposer,
          $$QuestionsTableAnnotationComposer,
          $$QuestionsTableCreateCompanionBuilder,
          $$QuestionsTableUpdateCompanionBuilder,
          (
            QuestionRow,
            BaseReferences<_$AssetsDatabase, $QuestionsTable, QuestionRow>,
          ),
          QuestionRow,
          PrefetchHooks Function()
        > {
  $$QuestionsTableTableManager(_$AssetsDatabase db, $QuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<String> examType = const Value.absent(),
                Value<String> region = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String> questionType = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<double?> calculation = const Value.absent(),
                Value<String> stem = const Value.absent(),
                Value<String?> images = const Value.absent(),
                Value<double?> defaultScore = const Value.absent(),
              }) => QuestionsCompanion(
                id: id,
                year: year,
                examType: examType,
                region: region,
                number: number,
                questionType: questionType,
                difficulty: difficulty,
                calculation: calculation,
                stem: stem,
                images: images,
                defaultScore: defaultScore,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int year,
                required String examType,
                required String region,
                required String number,
                required String questionType,
                Value<double?> difficulty = const Value.absent(),
                Value<double?> calculation = const Value.absent(),
                required String stem,
                Value<String?> images = const Value.absent(),
                Value<double?> defaultScore = const Value.absent(),
              }) => QuestionsCompanion.insert(
                id: id,
                year: year,
                examType: examType,
                region: region,
                number: number,
                questionType: questionType,
                difficulty: difficulty,
                calculation: calculation,
                stem: stem,
                images: images,
                defaultScore: defaultScore,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $QuestionsTable,
      QuestionRow,
      $$QuestionsTableFilterComposer,
      $$QuestionsTableOrderingComposer,
      $$QuestionsTableAnnotationComposer,
      $$QuestionsTableCreateCompanionBuilder,
      $$QuestionsTableUpdateCompanionBuilder,
      (
        QuestionRow,
        BaseReferences<_$AssetsDatabase, $QuestionsTable, QuestionRow>,
      ),
      QuestionRow,
      PrefetchHooks Function()
    >;
typedef $$ChoiceExtTableCreateCompanionBuilder =
    ChoiceExtCompanion Function({
      Value<int> id,
      required int questionId,
      required String options,
    });
typedef $$ChoiceExtTableUpdateCompanionBuilder =
    ChoiceExtCompanion Function({
      Value<int> id,
      Value<int> questionId,
      Value<String> options,
    });

class $$ChoiceExtTableFilterComposer
    extends Composer<_$AssetsDatabase, $ChoiceExtTable> {
  $$ChoiceExtTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChoiceExtTableOrderingComposer
    extends Composer<_$AssetsDatabase, $ChoiceExtTable> {
  $$ChoiceExtTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChoiceExtTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $ChoiceExtTable> {
  $$ChoiceExtTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);
}

class $$ChoiceExtTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $ChoiceExtTable,
          ChoiceExtRow,
          $$ChoiceExtTableFilterComposer,
          $$ChoiceExtTableOrderingComposer,
          $$ChoiceExtTableAnnotationComposer,
          $$ChoiceExtTableCreateCompanionBuilder,
          $$ChoiceExtTableUpdateCompanionBuilder,
          (
            ChoiceExtRow,
            BaseReferences<_$AssetsDatabase, $ChoiceExtTable, ChoiceExtRow>,
          ),
          ChoiceExtRow,
          PrefetchHooks Function()
        > {
  $$ChoiceExtTableTableManager(_$AssetsDatabase db, $ChoiceExtTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChoiceExtTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChoiceExtTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChoiceExtTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<String> options = const Value.absent(),
              }) => ChoiceExtCompanion(
                id: id,
                questionId: questionId,
                options: options,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int questionId,
                required String options,
              }) => ChoiceExtCompanion.insert(
                id: id,
                questionId: questionId,
                options: options,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChoiceExtTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $ChoiceExtTable,
      ChoiceExtRow,
      $$ChoiceExtTableFilterComposer,
      $$ChoiceExtTableOrderingComposer,
      $$ChoiceExtTableAnnotationComposer,
      $$ChoiceExtTableCreateCompanionBuilder,
      $$ChoiceExtTableUpdateCompanionBuilder,
      (
        ChoiceExtRow,
        BaseReferences<_$AssetsDatabase, $ChoiceExtTable, ChoiceExtRow>,
      ),
      ChoiceExtRow,
      PrefetchHooks Function()
    >;
typedef $$SubQuestionsTableCreateCompanionBuilder =
    SubQuestionsCompanion Function({
      Value<int> id,
      required int questionId,
      Value<int?> parentId,
      Value<String?> stem,
      Value<String?> answer,
      required int sortOrder,
    });
typedef $$SubQuestionsTableUpdateCompanionBuilder =
    SubQuestionsCompanion Function({
      Value<int> id,
      Value<int> questionId,
      Value<int?> parentId,
      Value<String?> stem,
      Value<String?> answer,
      Value<int> sortOrder,
    });

class $$SubQuestionsTableFilterComposer
    extends Composer<_$AssetsDatabase, $SubQuestionsTable> {
  $$SubQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stem => $composableBuilder(
    column: $table.stem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubQuestionsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $SubQuestionsTable> {
  $$SubQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stem => $composableBuilder(
    column: $table.stem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubQuestionsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $SubQuestionsTable> {
  $$SubQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get stem =>
      $composableBuilder(column: $table.stem, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$SubQuestionsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $SubQuestionsTable,
          SubQuestionRow,
          $$SubQuestionsTableFilterComposer,
          $$SubQuestionsTableOrderingComposer,
          $$SubQuestionsTableAnnotationComposer,
          $$SubQuestionsTableCreateCompanionBuilder,
          $$SubQuestionsTableUpdateCompanionBuilder,
          (
            SubQuestionRow,
            BaseReferences<
              _$AssetsDatabase,
              $SubQuestionsTable,
              SubQuestionRow
            >,
          ),
          SubQuestionRow,
          PrefetchHooks Function()
        > {
  $$SubQuestionsTableTableManager(_$AssetsDatabase db, $SubQuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<String?> stem = const Value.absent(),
                Value<String?> answer = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => SubQuestionsCompanion(
                id: id,
                questionId: questionId,
                parentId: parentId,
                stem: stem,
                answer: answer,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int questionId,
                Value<int?> parentId = const Value.absent(),
                Value<String?> stem = const Value.absent(),
                Value<String?> answer = const Value.absent(),
                required int sortOrder,
              }) => SubQuestionsCompanion.insert(
                id: id,
                questionId: questionId,
                parentId: parentId,
                stem: stem,
                answer: answer,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $SubQuestionsTable,
      SubQuestionRow,
      $$SubQuestionsTableFilterComposer,
      $$SubQuestionsTableOrderingComposer,
      $$SubQuestionsTableAnnotationComposer,
      $$SubQuestionsTableCreateCompanionBuilder,
      $$SubQuestionsTableUpdateCompanionBuilder,
      (
        SubQuestionRow,
        BaseReferences<_$AssetsDatabase, $SubQuestionsTable, SubQuestionRow>,
      ),
      SubQuestionRow,
      PrefetchHooks Function()
    >;
typedef $$SolutionMethodsTableCreateCompanionBuilder =
    SolutionMethodsCompanion Function({
      Value<int> id,
      required int subQuestionId,
      Value<String?> methodName,
      Value<String?> source,
      required int sortOrder,
    });
typedef $$SolutionMethodsTableUpdateCompanionBuilder =
    SolutionMethodsCompanion Function({
      Value<int> id,
      Value<int> subQuestionId,
      Value<String?> methodName,
      Value<String?> source,
      Value<int> sortOrder,
    });

class $$SolutionMethodsTableFilterComposer
    extends Composer<_$AssetsDatabase, $SolutionMethodsTable> {
  $$SolutionMethodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subQuestionId => $composableBuilder(
    column: $table.subQuestionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get methodName => $composableBuilder(
    column: $table.methodName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SolutionMethodsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $SolutionMethodsTable> {
  $$SolutionMethodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subQuestionId => $composableBuilder(
    column: $table.subQuestionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methodName => $composableBuilder(
    column: $table.methodName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SolutionMethodsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $SolutionMethodsTable> {
  $$SolutionMethodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get subQuestionId => $composableBuilder(
    column: $table.subQuestionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get methodName => $composableBuilder(
    column: $table.methodName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$SolutionMethodsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $SolutionMethodsTable,
          SolutionMethodRow,
          $$SolutionMethodsTableFilterComposer,
          $$SolutionMethodsTableOrderingComposer,
          $$SolutionMethodsTableAnnotationComposer,
          $$SolutionMethodsTableCreateCompanionBuilder,
          $$SolutionMethodsTableUpdateCompanionBuilder,
          (
            SolutionMethodRow,
            BaseReferences<
              _$AssetsDatabase,
              $SolutionMethodsTable,
              SolutionMethodRow
            >,
          ),
          SolutionMethodRow,
          PrefetchHooks Function()
        > {
  $$SolutionMethodsTableTableManager(
    _$AssetsDatabase db,
    $SolutionMethodsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SolutionMethodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SolutionMethodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SolutionMethodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> subQuestionId = const Value.absent(),
                Value<String?> methodName = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => SolutionMethodsCompanion(
                id: id,
                subQuestionId: subQuestionId,
                methodName: methodName,
                source: source,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int subQuestionId,
                Value<String?> methodName = const Value.absent(),
                Value<String?> source = const Value.absent(),
                required int sortOrder,
              }) => SolutionMethodsCompanion.insert(
                id: id,
                subQuestionId: subQuestionId,
                methodName: methodName,
                source: source,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SolutionMethodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $SolutionMethodsTable,
      SolutionMethodRow,
      $$SolutionMethodsTableFilterComposer,
      $$SolutionMethodsTableOrderingComposer,
      $$SolutionMethodsTableAnnotationComposer,
      $$SolutionMethodsTableCreateCompanionBuilder,
      $$SolutionMethodsTableUpdateCompanionBuilder,
      (
        SolutionMethodRow,
        BaseReferences<
          _$AssetsDatabase,
          $SolutionMethodsTable,
          SolutionMethodRow
        >,
      ),
      SolutionMethodRow,
      PrefetchHooks Function()
    >;
typedef $$SolutionStepsTableCreateCompanionBuilder =
    SolutionStepsCompanion Function({
      Value<int> id,
      required int methodId,
      required int stepNumber,
      required String title,
      required String content,
      Value<String?> cardTitles,
    });
typedef $$SolutionStepsTableUpdateCompanionBuilder =
    SolutionStepsCompanion Function({
      Value<int> id,
      Value<int> methodId,
      Value<int> stepNumber,
      Value<String> title,
      Value<String> content,
      Value<String?> cardTitles,
    });

class $$SolutionStepsTableFilterComposer
    extends Composer<_$AssetsDatabase, $SolutionStepsTable> {
  $$SolutionStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get methodId => $composableBuilder(
    column: $table.methodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardTitles => $composableBuilder(
    column: $table.cardTitles,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SolutionStepsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $SolutionStepsTable> {
  $$SolutionStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get methodId => $composableBuilder(
    column: $table.methodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardTitles => $composableBuilder(
    column: $table.cardTitles,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SolutionStepsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $SolutionStepsTable> {
  $$SolutionStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get methodId =>
      $composableBuilder(column: $table.methodId, builder: (column) => column);

  GeneratedColumn<int> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get cardTitles => $composableBuilder(
    column: $table.cardTitles,
    builder: (column) => column,
  );
}

class $$SolutionStepsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $SolutionStepsTable,
          SolutionStepRow,
          $$SolutionStepsTableFilterComposer,
          $$SolutionStepsTableOrderingComposer,
          $$SolutionStepsTableAnnotationComposer,
          $$SolutionStepsTableCreateCompanionBuilder,
          $$SolutionStepsTableUpdateCompanionBuilder,
          (
            SolutionStepRow,
            BaseReferences<
              _$AssetsDatabase,
              $SolutionStepsTable,
              SolutionStepRow
            >,
          ),
          SolutionStepRow,
          PrefetchHooks Function()
        > {
  $$SolutionStepsTableTableManager(
    _$AssetsDatabase db,
    $SolutionStepsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SolutionStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SolutionStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SolutionStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> methodId = const Value.absent(),
                Value<int> stepNumber = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> cardTitles = const Value.absent(),
              }) => SolutionStepsCompanion(
                id: id,
                methodId: methodId,
                stepNumber: stepNumber,
                title: title,
                content: content,
                cardTitles: cardTitles,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int methodId,
                required int stepNumber,
                required String title,
                required String content,
                Value<String?> cardTitles = const Value.absent(),
              }) => SolutionStepsCompanion.insert(
                id: id,
                methodId: methodId,
                stepNumber: stepNumber,
                title: title,
                content: content,
                cardTitles: cardTitles,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SolutionStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $SolutionStepsTable,
      SolutionStepRow,
      $$SolutionStepsTableFilterComposer,
      $$SolutionStepsTableOrderingComposer,
      $$SolutionStepsTableAnnotationComposer,
      $$SolutionStepsTableCreateCompanionBuilder,
      $$SolutionStepsTableUpdateCompanionBuilder,
      (
        SolutionStepRow,
        BaseReferences<_$AssetsDatabase, $SolutionStepsTable, SolutionStepRow>,
      ),
      SolutionStepRow,
      PrefetchHooks Function()
    >;
typedef $$ConceptTagsTableCreateCompanionBuilder =
    ConceptTagsCompanion Function({
      Value<int> id,
      required String name,
      Value<int?> parentId,
    });
typedef $$ConceptTagsTableUpdateCompanionBuilder =
    ConceptTagsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int?> parentId,
    });

class $$ConceptTagsTableFilterComposer
    extends Composer<_$AssetsDatabase, $ConceptTagsTable> {
  $$ConceptTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConceptTagsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $ConceptTagsTable> {
  $$ConceptTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConceptTagsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $ConceptTagsTable> {
  $$ConceptTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);
}

class $$ConceptTagsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $ConceptTagsTable,
          ConceptTagRow,
          $$ConceptTagsTableFilterComposer,
          $$ConceptTagsTableOrderingComposer,
          $$ConceptTagsTableAnnotationComposer,
          $$ConceptTagsTableCreateCompanionBuilder,
          $$ConceptTagsTableUpdateCompanionBuilder,
          (
            ConceptTagRow,
            BaseReferences<_$AssetsDatabase, $ConceptTagsTable, ConceptTagRow>,
          ),
          ConceptTagRow,
          PrefetchHooks Function()
        > {
  $$ConceptTagsTableTableManager(_$AssetsDatabase db, $ConceptTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConceptTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConceptTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConceptTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
              }) =>
                  ConceptTagsCompanion(id: id, name: name, parentId: parentId),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> parentId = const Value.absent(),
              }) => ConceptTagsCompanion.insert(
                id: id,
                name: name,
                parentId: parentId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConceptTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $ConceptTagsTable,
      ConceptTagRow,
      $$ConceptTagsTableFilterComposer,
      $$ConceptTagsTableOrderingComposer,
      $$ConceptTagsTableAnnotationComposer,
      $$ConceptTagsTableCreateCompanionBuilder,
      $$ConceptTagsTableUpdateCompanionBuilder,
      (
        ConceptTagRow,
        BaseReferences<_$AssetsDatabase, $ConceptTagsTable, ConceptTagRow>,
      ),
      ConceptTagRow,
      PrefetchHooks Function()
    >;
typedef $$KnowledgeCardsTableCreateCompanionBuilder =
    KnowledgeCardsCompanion Function({
      Value<int> id,
      required String title,
      required String category,
      required String content,
    });
typedef $$KnowledgeCardsTableUpdateCompanionBuilder =
    KnowledgeCardsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> category,
      Value<String> content,
    });

class $$KnowledgeCardsTableFilterComposer
    extends Composer<_$AssetsDatabase, $KnowledgeCardsTable> {
  $$KnowledgeCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KnowledgeCardsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $KnowledgeCardsTable> {
  $$KnowledgeCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KnowledgeCardsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $KnowledgeCardsTable> {
  $$KnowledgeCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$KnowledgeCardsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $KnowledgeCardsTable,
          KnowledgeCardRow,
          $$KnowledgeCardsTableFilterComposer,
          $$KnowledgeCardsTableOrderingComposer,
          $$KnowledgeCardsTableAnnotationComposer,
          $$KnowledgeCardsTableCreateCompanionBuilder,
          $$KnowledgeCardsTableUpdateCompanionBuilder,
          (
            KnowledgeCardRow,
            BaseReferences<
              _$AssetsDatabase,
              $KnowledgeCardsTable,
              KnowledgeCardRow
            >,
          ),
          KnowledgeCardRow,
          PrefetchHooks Function()
        > {
  $$KnowledgeCardsTableTableManager(
    _$AssetsDatabase db,
    $KnowledgeCardsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnowledgeCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnowledgeCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnowledgeCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> content = const Value.absent(),
              }) => KnowledgeCardsCompanion(
                id: id,
                title: title,
                category: category,
                content: content,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String category,
                required String content,
              }) => KnowledgeCardsCompanion.insert(
                id: id,
                title: title,
                category: category,
                content: content,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KnowledgeCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $KnowledgeCardsTable,
      KnowledgeCardRow,
      $$KnowledgeCardsTableFilterComposer,
      $$KnowledgeCardsTableOrderingComposer,
      $$KnowledgeCardsTableAnnotationComposer,
      $$KnowledgeCardsTableCreateCompanionBuilder,
      $$KnowledgeCardsTableUpdateCompanionBuilder,
      (
        KnowledgeCardRow,
        BaseReferences<
          _$AssetsDatabase,
          $KnowledgeCardsTable,
          KnowledgeCardRow
        >,
      ),
      KnowledgeCardRow,
      PrefetchHooks Function()
    >;
typedef $$QuestionConceptTagsTableCreateCompanionBuilder =
    QuestionConceptTagsCompanion Function({
      Value<int> id,
      required int questionId,
      required int conceptTagId,
    });
typedef $$QuestionConceptTagsTableUpdateCompanionBuilder =
    QuestionConceptTagsCompanion Function({
      Value<int> id,
      Value<int> questionId,
      Value<int> conceptTagId,
    });

class $$QuestionConceptTagsTableFilterComposer
    extends Composer<_$AssetsDatabase, $QuestionConceptTagsTable> {
  $$QuestionConceptTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get conceptTagId => $composableBuilder(
    column: $table.conceptTagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestionConceptTagsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $QuestionConceptTagsTable> {
  $$QuestionConceptTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get conceptTagId => $composableBuilder(
    column: $table.conceptTagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestionConceptTagsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $QuestionConceptTagsTable> {
  $$QuestionConceptTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get conceptTagId => $composableBuilder(
    column: $table.conceptTagId,
    builder: (column) => column,
  );
}

class $$QuestionConceptTagsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $QuestionConceptTagsTable,
          QuestionConceptTagRow,
          $$QuestionConceptTagsTableFilterComposer,
          $$QuestionConceptTagsTableOrderingComposer,
          $$QuestionConceptTagsTableAnnotationComposer,
          $$QuestionConceptTagsTableCreateCompanionBuilder,
          $$QuestionConceptTagsTableUpdateCompanionBuilder,
          (
            QuestionConceptTagRow,
            BaseReferences<
              _$AssetsDatabase,
              $QuestionConceptTagsTable,
              QuestionConceptTagRow
            >,
          ),
          QuestionConceptTagRow,
          PrefetchHooks Function()
        > {
  $$QuestionConceptTagsTableTableManager(
    _$AssetsDatabase db,
    $QuestionConceptTagsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionConceptTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionConceptTagsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$QuestionConceptTagsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<int> conceptTagId = const Value.absent(),
              }) => QuestionConceptTagsCompanion(
                id: id,
                questionId: questionId,
                conceptTagId: conceptTagId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int questionId,
                required int conceptTagId,
              }) => QuestionConceptTagsCompanion.insert(
                id: id,
                questionId: questionId,
                conceptTagId: conceptTagId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestionConceptTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $QuestionConceptTagsTable,
      QuestionConceptTagRow,
      $$QuestionConceptTagsTableFilterComposer,
      $$QuestionConceptTagsTableOrderingComposer,
      $$QuestionConceptTagsTableAnnotationComposer,
      $$QuestionConceptTagsTableCreateCompanionBuilder,
      $$QuestionConceptTagsTableUpdateCompanionBuilder,
      (
        QuestionConceptTagRow,
        BaseReferences<
          _$AssetsDatabase,
          $QuestionConceptTagsTable,
          QuestionConceptTagRow
        >,
      ),
      QuestionConceptTagRow,
      PrefetchHooks Function()
    >;
typedef $$QuestionKnowledgeCardsTableCreateCompanionBuilder =
    QuestionKnowledgeCardsCompanion Function({
      Value<int> id,
      required int questionId,
      required int knowledgeCardId,
    });
typedef $$QuestionKnowledgeCardsTableUpdateCompanionBuilder =
    QuestionKnowledgeCardsCompanion Function({
      Value<int> id,
      Value<int> questionId,
      Value<int> knowledgeCardId,
    });

class $$QuestionKnowledgeCardsTableFilterComposer
    extends Composer<_$AssetsDatabase, $QuestionKnowledgeCardsTable> {
  $$QuestionKnowledgeCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get knowledgeCardId => $composableBuilder(
    column: $table.knowledgeCardId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestionKnowledgeCardsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $QuestionKnowledgeCardsTable> {
  $$QuestionKnowledgeCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get knowledgeCardId => $composableBuilder(
    column: $table.knowledgeCardId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestionKnowledgeCardsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $QuestionKnowledgeCardsTable> {
  $$QuestionKnowledgeCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get knowledgeCardId => $composableBuilder(
    column: $table.knowledgeCardId,
    builder: (column) => column,
  );
}

class $$QuestionKnowledgeCardsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $QuestionKnowledgeCardsTable,
          QuestionKnowledgeCardRow,
          $$QuestionKnowledgeCardsTableFilterComposer,
          $$QuestionKnowledgeCardsTableOrderingComposer,
          $$QuestionKnowledgeCardsTableAnnotationComposer,
          $$QuestionKnowledgeCardsTableCreateCompanionBuilder,
          $$QuestionKnowledgeCardsTableUpdateCompanionBuilder,
          (
            QuestionKnowledgeCardRow,
            BaseReferences<
              _$AssetsDatabase,
              $QuestionKnowledgeCardsTable,
              QuestionKnowledgeCardRow
            >,
          ),
          QuestionKnowledgeCardRow,
          PrefetchHooks Function()
        > {
  $$QuestionKnowledgeCardsTableTableManager(
    _$AssetsDatabase db,
    $QuestionKnowledgeCardsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionKnowledgeCardsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$QuestionKnowledgeCardsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$QuestionKnowledgeCardsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<int> knowledgeCardId = const Value.absent(),
              }) => QuestionKnowledgeCardsCompanion(
                id: id,
                questionId: questionId,
                knowledgeCardId: knowledgeCardId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int questionId,
                required int knowledgeCardId,
              }) => QuestionKnowledgeCardsCompanion.insert(
                id: id,
                questionId: questionId,
                knowledgeCardId: knowledgeCardId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestionKnowledgeCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $QuestionKnowledgeCardsTable,
      QuestionKnowledgeCardRow,
      $$QuestionKnowledgeCardsTableFilterComposer,
      $$QuestionKnowledgeCardsTableOrderingComposer,
      $$QuestionKnowledgeCardsTableAnnotationComposer,
      $$QuestionKnowledgeCardsTableCreateCompanionBuilder,
      $$QuestionKnowledgeCardsTableUpdateCompanionBuilder,
      (
        QuestionKnowledgeCardRow,
        BaseReferences<
          _$AssetsDatabase,
          $QuestionKnowledgeCardsTable,
          QuestionKnowledgeCardRow
        >,
      ),
      QuestionKnowledgeCardRow,
      PrefetchHooks Function()
    >;
typedef $$CoursesTableCreateCompanionBuilder =
    CoursesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
    });
typedef $$CoursesTableUpdateCompanionBuilder =
    CoursesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
    });

class $$CoursesTableFilterComposer
    extends Composer<_$AssetsDatabase, $CoursesTable> {
  $$CoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoursesTableOrderingComposer
    extends Composer<_$AssetsDatabase, $CoursesTable> {
  $$CoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoursesTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $CoursesTable> {
  $$CoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$CoursesTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $CoursesTable,
          CourseRow,
          $$CoursesTableFilterComposer,
          $$CoursesTableOrderingComposer,
          $$CoursesTableAnnotationComposer,
          $$CoursesTableCreateCompanionBuilder,
          $$CoursesTableUpdateCompanionBuilder,
          (
            CourseRow,
            BaseReferences<_$AssetsDatabase, $CoursesTable, CourseRow>,
          ),
          CourseRow,
          PrefetchHooks Function()
        > {
  $$CoursesTableTableManager(_$AssetsDatabase db, $CoursesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
              }) => CoursesCompanion(
                id: id,
                name: name,
                description: description,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
              }) => CoursesCompanion.insert(
                id: id,
                name: name,
                description: description,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $CoursesTable,
      CourseRow,
      $$CoursesTableFilterComposer,
      $$CoursesTableOrderingComposer,
      $$CoursesTableAnnotationComposer,
      $$CoursesTableCreateCompanionBuilder,
      $$CoursesTableUpdateCompanionBuilder,
      (CourseRow, BaseReferences<_$AssetsDatabase, $CoursesTable, CourseRow>),
      CourseRow,
      PrefetchHooks Function()
    >;
typedef $$AssignmentsTableCreateCompanionBuilder =
    AssignmentsCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
      Value<int?> courseId,
    });
typedef $$AssignmentsTableUpdateCompanionBuilder =
    AssignmentsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> description,
      Value<int?> courseId,
    });

class $$AssignmentsTableFilterComposer
    extends Composer<_$AssetsDatabase, $AssignmentsTable> {
  $$AssignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssignmentsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $AssignmentsTable> {
  $$AssignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssignmentsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $AssignmentsTable> {
  $$AssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);
}

class $$AssignmentsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $AssignmentsTable,
          AssignmentRow,
          $$AssignmentsTableFilterComposer,
          $$AssignmentsTableOrderingComposer,
          $$AssignmentsTableAnnotationComposer,
          $$AssignmentsTableCreateCompanionBuilder,
          $$AssignmentsTableUpdateCompanionBuilder,
          (
            AssignmentRow,
            BaseReferences<_$AssetsDatabase, $AssignmentsTable, AssignmentRow>,
          ),
          AssignmentRow,
          PrefetchHooks Function()
        > {
  $$AssignmentsTableTableManager(_$AssetsDatabase db, $AssignmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssignmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssignmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> courseId = const Value.absent(),
              }) => AssignmentsCompanion(
                id: id,
                title: title,
                description: description,
                courseId: courseId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<int?> courseId = const Value.absent(),
              }) => AssignmentsCompanion.insert(
                id: id,
                title: title,
                description: description,
                courseId: courseId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssignmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $AssignmentsTable,
      AssignmentRow,
      $$AssignmentsTableFilterComposer,
      $$AssignmentsTableOrderingComposer,
      $$AssignmentsTableAnnotationComposer,
      $$AssignmentsTableCreateCompanionBuilder,
      $$AssignmentsTableUpdateCompanionBuilder,
      (
        AssignmentRow,
        BaseReferences<_$AssetsDatabase, $AssignmentsTable, AssignmentRow>,
      ),
      AssignmentRow,
      PrefetchHooks Function()
    >;
typedef $$AssignmentQuestionsTableCreateCompanionBuilder =
    AssignmentQuestionsCompanion Function({
      Value<int> id,
      required int assignmentId,
      required int questionId,
      required int sortOrder,
    });
typedef $$AssignmentQuestionsTableUpdateCompanionBuilder =
    AssignmentQuestionsCompanion Function({
      Value<int> id,
      Value<int> assignmentId,
      Value<int> questionId,
      Value<int> sortOrder,
    });

class $$AssignmentQuestionsTableFilterComposer
    extends Composer<_$AssetsDatabase, $AssignmentQuestionsTable> {
  $$AssignmentQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssignmentQuestionsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $AssignmentQuestionsTable> {
  $$AssignmentQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssignmentQuestionsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $AssignmentQuestionsTable> {
  $$AssignmentQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$AssignmentQuestionsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $AssignmentQuestionsTable,
          AssignmentQuestionRow,
          $$AssignmentQuestionsTableFilterComposer,
          $$AssignmentQuestionsTableOrderingComposer,
          $$AssignmentQuestionsTableAnnotationComposer,
          $$AssignmentQuestionsTableCreateCompanionBuilder,
          $$AssignmentQuestionsTableUpdateCompanionBuilder,
          (
            AssignmentQuestionRow,
            BaseReferences<
              _$AssetsDatabase,
              $AssignmentQuestionsTable,
              AssignmentQuestionRow
            >,
          ),
          AssignmentQuestionRow,
          PrefetchHooks Function()
        > {
  $$AssignmentQuestionsTableTableManager(
    _$AssetsDatabase db,
    $AssignmentQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssignmentQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssignmentQuestionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AssignmentQuestionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> assignmentId = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => AssignmentQuestionsCompanion(
                id: id,
                assignmentId: assignmentId,
                questionId: questionId,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int assignmentId,
                required int questionId,
                required int sortOrder,
              }) => AssignmentQuestionsCompanion.insert(
                id: id,
                assignmentId: assignmentId,
                questionId: questionId,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssignmentQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $AssignmentQuestionsTable,
      AssignmentQuestionRow,
      $$AssignmentQuestionsTableFilterComposer,
      $$AssignmentQuestionsTableOrderingComposer,
      $$AssignmentQuestionsTableAnnotationComposer,
      $$AssignmentQuestionsTableCreateCompanionBuilder,
      $$AssignmentQuestionsTableUpdateCompanionBuilder,
      (
        AssignmentQuestionRow,
        BaseReferences<
          _$AssetsDatabase,
          $AssignmentQuestionsTable,
          AssignmentQuestionRow
        >,
      ),
      AssignmentQuestionRow,
      PrefetchHooks Function()
    >;
typedef $$AchievementDefsTableCreateCompanionBuilder =
    AchievementDefsCompanion Function({
      Value<int> id,
      required String code,
      required String name,
      Value<String?> description,
      Value<String?> icon,
      Value<String?> iconEmoji,
      required String category,
      Value<String?> categoryLabel,
      Value<int?> displayOrder,
      Value<String?> triggerType,
      Value<int?> threshold,
    });
typedef $$AchievementDefsTableUpdateCompanionBuilder =
    AchievementDefsCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String> name,
      Value<String?> description,
      Value<String?> icon,
      Value<String?> iconEmoji,
      Value<String> category,
      Value<String?> categoryLabel,
      Value<int?> displayOrder,
      Value<String?> triggerType,
      Value<int?> threshold,
    });

class $$AchievementDefsTableFilterComposer
    extends Composer<_$AssetsDatabase, $AchievementDefsTable> {
  $$AchievementDefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconEmoji => $composableBuilder(
    column: $table.iconEmoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryLabel => $composableBuilder(
    column: $table.categoryLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get triggerType => $composableBuilder(
    column: $table.triggerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get threshold => $composableBuilder(
    column: $table.threshold,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AchievementDefsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $AchievementDefsTable> {
  $$AchievementDefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconEmoji => $composableBuilder(
    column: $table.iconEmoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryLabel => $composableBuilder(
    column: $table.categoryLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get triggerType => $composableBuilder(
    column: $table.triggerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get threshold => $composableBuilder(
    column: $table.threshold,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AchievementDefsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $AchievementDefsTable> {
  $$AchievementDefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get iconEmoji =>
      $composableBuilder(column: $table.iconEmoji, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get categoryLabel => $composableBuilder(
    column: $table.categoryLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get triggerType => $composableBuilder(
    column: $table.triggerType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get threshold =>
      $composableBuilder(column: $table.threshold, builder: (column) => column);
}

class $$AchievementDefsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $AchievementDefsTable,
          AchievementDefRow,
          $$AchievementDefsTableFilterComposer,
          $$AchievementDefsTableOrderingComposer,
          $$AchievementDefsTableAnnotationComposer,
          $$AchievementDefsTableCreateCompanionBuilder,
          $$AchievementDefsTableUpdateCompanionBuilder,
          (
            AchievementDefRow,
            BaseReferences<
              _$AssetsDatabase,
              $AchievementDefsTable,
              AchievementDefRow
            >,
          ),
          AchievementDefRow,
          PrefetchHooks Function()
        > {
  $$AchievementDefsTableTableManager(
    _$AssetsDatabase db,
    $AchievementDefsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementDefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementDefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementDefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> iconEmoji = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> categoryLabel = const Value.absent(),
                Value<int?> displayOrder = const Value.absent(),
                Value<String?> triggerType = const Value.absent(),
                Value<int?> threshold = const Value.absent(),
              }) => AchievementDefsCompanion(
                id: id,
                code: code,
                name: name,
                description: description,
                icon: icon,
                iconEmoji: iconEmoji,
                category: category,
                categoryLabel: categoryLabel,
                displayOrder: displayOrder,
                triggerType: triggerType,
                threshold: threshold,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> iconEmoji = const Value.absent(),
                required String category,
                Value<String?> categoryLabel = const Value.absent(),
                Value<int?> displayOrder = const Value.absent(),
                Value<String?> triggerType = const Value.absent(),
                Value<int?> threshold = const Value.absent(),
              }) => AchievementDefsCompanion.insert(
                id: id,
                code: code,
                name: name,
                description: description,
                icon: icon,
                iconEmoji: iconEmoji,
                category: category,
                categoryLabel: categoryLabel,
                displayOrder: displayOrder,
                triggerType: triggerType,
                threshold: threshold,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AchievementDefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $AchievementDefsTable,
      AchievementDefRow,
      $$AchievementDefsTableFilterComposer,
      $$AchievementDefsTableOrderingComposer,
      $$AchievementDefsTableAnnotationComposer,
      $$AchievementDefsTableCreateCompanionBuilder,
      $$AchievementDefsTableUpdateCompanionBuilder,
      (
        AchievementDefRow,
        BaseReferences<
          _$AssetsDatabase,
          $AchievementDefsTable,
          AchievementDefRow
        >,
      ),
      AchievementDefRow,
      PrefetchHooks Function()
    >;
typedef $$LevelConfigsTableCreateCompanionBuilder =
    LevelConfigsCompanion Function({
      Value<int> level,
      required int minXp,
      required String title,
      Value<String?> iconEmoji,
    });
typedef $$LevelConfigsTableUpdateCompanionBuilder =
    LevelConfigsCompanion Function({
      Value<int> level,
      Value<int> minXp,
      Value<String> title,
      Value<String?> iconEmoji,
    });

class $$LevelConfigsTableFilterComposer
    extends Composer<_$AssetsDatabase, $LevelConfigsTable> {
  $$LevelConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minXp => $composableBuilder(
    column: $table.minXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconEmoji => $composableBuilder(
    column: $table.iconEmoji,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LevelConfigsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $LevelConfigsTable> {
  $$LevelConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minXp => $composableBuilder(
    column: $table.minXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconEmoji => $composableBuilder(
    column: $table.iconEmoji,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LevelConfigsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $LevelConfigsTable> {
  $$LevelConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get minXp =>
      $composableBuilder(column: $table.minXp, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get iconEmoji =>
      $composableBuilder(column: $table.iconEmoji, builder: (column) => column);
}

class $$LevelConfigsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $LevelConfigsTable,
          LevelConfigRow,
          $$LevelConfigsTableFilterComposer,
          $$LevelConfigsTableOrderingComposer,
          $$LevelConfigsTableAnnotationComposer,
          $$LevelConfigsTableCreateCompanionBuilder,
          $$LevelConfigsTableUpdateCompanionBuilder,
          (
            LevelConfigRow,
            BaseReferences<
              _$AssetsDatabase,
              $LevelConfigsTable,
              LevelConfigRow
            >,
          ),
          LevelConfigRow,
          PrefetchHooks Function()
        > {
  $$LevelConfigsTableTableManager(_$AssetsDatabase db, $LevelConfigsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LevelConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LevelConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LevelConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> level = const Value.absent(),
                Value<int> minXp = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> iconEmoji = const Value.absent(),
              }) => LevelConfigsCompanion(
                level: level,
                minXp: minXp,
                title: title,
                iconEmoji: iconEmoji,
              ),
          createCompanionCallback:
              ({
                Value<int> level = const Value.absent(),
                required int minXp,
                required String title,
                Value<String?> iconEmoji = const Value.absent(),
              }) => LevelConfigsCompanion.insert(
                level: level,
                minXp: minXp,
                title: title,
                iconEmoji: iconEmoji,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LevelConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $LevelConfigsTable,
      LevelConfigRow,
      $$LevelConfigsTableFilterComposer,
      $$LevelConfigsTableOrderingComposer,
      $$LevelConfigsTableAnnotationComposer,
      $$LevelConfigsTableCreateCompanionBuilder,
      $$LevelConfigsTableUpdateCompanionBuilder,
      (
        LevelConfigRow,
        BaseReferences<_$AssetsDatabase, $LevelConfigsTable, LevelConfigRow>,
      ),
      LevelConfigRow,
      PrefetchHooks Function()
    >;
typedef $$SystemConfigsTableCreateCompanionBuilder =
    SystemConfigsCompanion Function({
      required String key,
      required String value,
      Value<String?> description,
      Value<int> rowid,
    });
typedef $$SystemConfigsTableUpdateCompanionBuilder =
    SystemConfigsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<String?> description,
      Value<int> rowid,
    });

class $$SystemConfigsTableFilterComposer
    extends Composer<_$AssetsDatabase, $SystemConfigsTable> {
  $$SystemConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SystemConfigsTableOrderingComposer
    extends Composer<_$AssetsDatabase, $SystemConfigsTable> {
  $$SystemConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SystemConfigsTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $SystemConfigsTable> {
  $$SystemConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$SystemConfigsTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $SystemConfigsTable,
          SystemConfigRow,
          $$SystemConfigsTableFilterComposer,
          $$SystemConfigsTableOrderingComposer,
          $$SystemConfigsTableAnnotationComposer,
          $$SystemConfigsTableCreateCompanionBuilder,
          $$SystemConfigsTableUpdateCompanionBuilder,
          (
            SystemConfigRow,
            BaseReferences<
              _$AssetsDatabase,
              $SystemConfigsTable,
              SystemConfigRow
            >,
          ),
          SystemConfigRow,
          PrefetchHooks Function()
        > {
  $$SystemConfigsTableTableManager(
    _$AssetsDatabase db,
    $SystemConfigsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SystemConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SystemConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SystemConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SystemConfigsCompanion(
                key: key,
                value: value,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SystemConfigsCompanion.insert(
                key: key,
                value: value,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SystemConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $SystemConfigsTable,
      SystemConfigRow,
      $$SystemConfigsTableFilterComposer,
      $$SystemConfigsTableOrderingComposer,
      $$SystemConfigsTableAnnotationComposer,
      $$SystemConfigsTableCreateCompanionBuilder,
      $$SystemConfigsTableUpdateCompanionBuilder,
      (
        SystemConfigRow,
        BaseReferences<_$AssetsDatabase, $SystemConfigsTable, SystemConfigRow>,
      ),
      SystemConfigRow,
      PrefetchHooks Function()
    >;
typedef $$MetaTableCreateCompanionBuilder =
    MetaCompanion Function({
      required int schemaVersion,
      required int dataVersion,
      required String checksum,
      required String builtAt,
      Value<int> rowid,
    });
typedef $$MetaTableUpdateCompanionBuilder =
    MetaCompanion Function({
      Value<int> schemaVersion,
      Value<int> dataVersion,
      Value<String> checksum,
      Value<String> builtAt,
      Value<int> rowid,
    });

class $$MetaTableFilterComposer extends Composer<_$AssetsDatabase, $MetaTable> {
  $$MetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dataVersion => $composableBuilder(
    column: $table.dataVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get builtAt => $composableBuilder(
    column: $table.builtAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetaTableOrderingComposer
    extends Composer<_$AssetsDatabase, $MetaTable> {
  $$MetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dataVersion => $composableBuilder(
    column: $table.dataVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get builtAt => $composableBuilder(
    column: $table.builtAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetaTableAnnotationComposer
    extends Composer<_$AssetsDatabase, $MetaTable> {
  $$MetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dataVersion => $composableBuilder(
    column: $table.dataVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<String> get builtAt =>
      $composableBuilder(column: $table.builtAt, builder: (column) => column);
}

class $$MetaTableTableManager
    extends
        RootTableManager<
          _$AssetsDatabase,
          $MetaTable,
          MetaRow,
          $$MetaTableFilterComposer,
          $$MetaTableOrderingComposer,
          $$MetaTableAnnotationComposer,
          $$MetaTableCreateCompanionBuilder,
          $$MetaTableUpdateCompanionBuilder,
          (MetaRow, BaseReferences<_$AssetsDatabase, $MetaTable, MetaRow>),
          MetaRow,
          PrefetchHooks Function()
        > {
  $$MetaTableTableManager(_$AssetsDatabase db, $MetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> schemaVersion = const Value.absent(),
                Value<int> dataVersion = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<String> builtAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetaCompanion(
                schemaVersion: schemaVersion,
                dataVersion: dataVersion,
                checksum: checksum,
                builtAt: builtAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int schemaVersion,
                required int dataVersion,
                required String checksum,
                required String builtAt,
                Value<int> rowid = const Value.absent(),
              }) => MetaCompanion.insert(
                schemaVersion: schemaVersion,
                dataVersion: dataVersion,
                checksum: checksum,
                builtAt: builtAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AssetsDatabase,
      $MetaTable,
      MetaRow,
      $$MetaTableFilterComposer,
      $$MetaTableOrderingComposer,
      $$MetaTableAnnotationComposer,
      $$MetaTableCreateCompanionBuilder,
      $$MetaTableUpdateCompanionBuilder,
      (MetaRow, BaseReferences<_$AssetsDatabase, $MetaTable, MetaRow>),
      MetaRow,
      PrefetchHooks Function()
    >;

class $AssetsDatabaseManager {
  final _$AssetsDatabase _db;
  $AssetsDatabaseManager(this._db);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db, _db.questions);
  $$ChoiceExtTableTableManager get choiceExt =>
      $$ChoiceExtTableTableManager(_db, _db.choiceExt);
  $$SubQuestionsTableTableManager get subQuestions =>
      $$SubQuestionsTableTableManager(_db, _db.subQuestions);
  $$SolutionMethodsTableTableManager get solutionMethods =>
      $$SolutionMethodsTableTableManager(_db, _db.solutionMethods);
  $$SolutionStepsTableTableManager get solutionSteps =>
      $$SolutionStepsTableTableManager(_db, _db.solutionSteps);
  $$ConceptTagsTableTableManager get conceptTags =>
      $$ConceptTagsTableTableManager(_db, _db.conceptTags);
  $$KnowledgeCardsTableTableManager get knowledgeCards =>
      $$KnowledgeCardsTableTableManager(_db, _db.knowledgeCards);
  $$QuestionConceptTagsTableTableManager get questionConceptTags =>
      $$QuestionConceptTagsTableTableManager(_db, _db.questionConceptTags);
  $$QuestionKnowledgeCardsTableTableManager get questionKnowledgeCards =>
      $$QuestionKnowledgeCardsTableTableManager(
        _db,
        _db.questionKnowledgeCards,
      );
  $$CoursesTableTableManager get courses =>
      $$CoursesTableTableManager(_db, _db.courses);
  $$AssignmentsTableTableManager get assignments =>
      $$AssignmentsTableTableManager(_db, _db.assignments);
  $$AssignmentQuestionsTableTableManager get assignmentQuestions =>
      $$AssignmentQuestionsTableTableManager(_db, _db.assignmentQuestions);
  $$AchievementDefsTableTableManager get achievementDefs =>
      $$AchievementDefsTableTableManager(_db, _db.achievementDefs);
  $$LevelConfigsTableTableManager get levelConfigs =>
      $$LevelConfigsTableTableManager(_db, _db.levelConfigs);
  $$SystemConfigsTableTableManager get systemConfigs =>
      $$SystemConfigsTableTableManager(_db, _db.systemConfigs);
  $$MetaTableTableManager get meta => $$MetaTableTableManager(_db, _db.meta);
}
