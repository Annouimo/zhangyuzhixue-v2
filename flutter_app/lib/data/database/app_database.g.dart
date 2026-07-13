// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _realNameMeta = const VerificationMeta(
    'realName',
  );
  @override
  late final GeneratedColumn<String> realName = GeneratedColumn<String>(
    'real_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schoolMeta = const VerificationMeta('school');
  @override
  late final GeneratedColumn<String> school = GeneratedColumn<String>(
    'school',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gaokaoYearMeta = const VerificationMeta(
    'gaokaoYear',
  );
  @override
  late final GeneratedColumn<String> gaokaoYear = GeneratedColumn<String>(
    'gaokao_year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _classGroupIdMeta = const VerificationMeta(
    'classGroupId',
  );
  @override
  late final GeneratedColumn<int> classGroupId = GeneratedColumn<int>(
    'class_group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    realName,
    studentId,
    avatar,
    school,
    gaokaoYear,
    classGroupId,
    phone,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileRow> instance, {
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
    if (data.containsKey('real_name')) {
      context.handle(
        _realNameMeta,
        realName.isAcceptableOrUnknown(data['real_name']!, _realNameMeta),
      );
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('school')) {
      context.handle(
        _schoolMeta,
        school.isAcceptableOrUnknown(data['school']!, _schoolMeta),
      );
    }
    if (data.containsKey('gaokao_year')) {
      context.handle(
        _gaokaoYearMeta,
        gaokaoYear.isAcceptableOrUnknown(data['gaokao_year']!, _gaokaoYearMeta),
      );
    }
    if (data.containsKey('class_group_id')) {
      context.handle(
        _classGroupIdMeta,
        classGroupId.isAcceptableOrUnknown(
          data['class_group_id']!,
          _classGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      realName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}real_name'],
      ),
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      ),
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      ),
      school: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school'],
      ),
      gaokaoYear: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gaokao_year'],
      ),
      classGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}class_group_id'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  final int id;
  final String name;
  final String? realName;
  final String? studentId;
  final String? avatar;
  final String? school;
  final String? gaokaoYear;
  final int? classGroupId;
  final String? phone;
  final String? updatedAt;
  const UserProfileRow({
    required this.id,
    required this.name,
    this.realName,
    this.studentId,
    this.avatar,
    this.school,
    this.gaokaoYear,
    this.classGroupId,
    this.phone,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || realName != null) {
      map['real_name'] = Variable<String>(realName);
    }
    if (!nullToAbsent || studentId != null) {
      map['student_id'] = Variable<String>(studentId);
    }
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    if (!nullToAbsent || school != null) {
      map['school'] = Variable<String>(school);
    }
    if (!nullToAbsent || gaokaoYear != null) {
      map['gaokao_year'] = Variable<String>(gaokaoYear);
    }
    if (!nullToAbsent || classGroupId != null) {
      map['class_group_id'] = Variable<int>(classGroupId);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      name: Value(name),
      realName: realName == null && nullToAbsent
          ? const Value.absent()
          : Value(realName),
      studentId: studentId == null && nullToAbsent
          ? const Value.absent()
          : Value(studentId),
      avatar: avatar == null && nullToAbsent
          ? const Value.absent()
          : Value(avatar),
      school: school == null && nullToAbsent
          ? const Value.absent()
          : Value(school),
      gaokaoYear: gaokaoYear == null && nullToAbsent
          ? const Value.absent()
          : Value(gaokaoYear),
      classGroupId: classGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(classGroupId),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory UserProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      realName: serializer.fromJson<String?>(json['realName']),
      studentId: serializer.fromJson<String?>(json['studentId']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      school: serializer.fromJson<String?>(json['school']),
      gaokaoYear: serializer.fromJson<String?>(json['gaokaoYear']),
      classGroupId: serializer.fromJson<int?>(json['classGroupId']),
      phone: serializer.fromJson<String?>(json['phone']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'realName': serializer.toJson<String?>(realName),
      'studentId': serializer.toJson<String?>(studentId),
      'avatar': serializer.toJson<String?>(avatar),
      'school': serializer.toJson<String?>(school),
      'gaokaoYear': serializer.toJson<String?>(gaokaoYear),
      'classGroupId': serializer.toJson<int?>(classGroupId),
      'phone': serializer.toJson<String?>(phone),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  UserProfileRow copyWith({
    int? id,
    String? name,
    Value<String?> realName = const Value.absent(),
    Value<String?> studentId = const Value.absent(),
    Value<String?> avatar = const Value.absent(),
    Value<String?> school = const Value.absent(),
    Value<String?> gaokaoYear = const Value.absent(),
    Value<int?> classGroupId = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => UserProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    realName: realName.present ? realName.value : this.realName,
    studentId: studentId.present ? studentId.value : this.studentId,
    avatar: avatar.present ? avatar.value : this.avatar,
    school: school.present ? school.value : this.school,
    gaokaoYear: gaokaoYear.present ? gaokaoYear.value : this.gaokaoYear,
    classGroupId: classGroupId.present ? classGroupId.value : this.classGroupId,
    phone: phone.present ? phone.value : this.phone,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  UserProfileRow copyWithCompanion(UserProfilesCompanion data) {
    return UserProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      realName: data.realName.present ? data.realName.value : this.realName,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      school: data.school.present ? data.school.value : this.school,
      gaokaoYear: data.gaokaoYear.present
          ? data.gaokaoYear.value
          : this.gaokaoYear,
      classGroupId: data.classGroupId.present
          ? data.classGroupId.value
          : this.classGroupId,
      phone: data.phone.present ? data.phone.value : this.phone,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('realName: $realName, ')
          ..write('studentId: $studentId, ')
          ..write('avatar: $avatar, ')
          ..write('school: $school, ')
          ..write('gaokaoYear: $gaokaoYear, ')
          ..write('classGroupId: $classGroupId, ')
          ..write('phone: $phone, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    realName,
    studentId,
    avatar,
    school,
    gaokaoYear,
    classGroupId,
    phone,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.realName == this.realName &&
          other.studentId == this.studentId &&
          other.avatar == this.avatar &&
          other.school == this.school &&
          other.gaokaoYear == this.gaokaoYear &&
          other.classGroupId == this.classGroupId &&
          other.phone == this.phone &&
          other.updatedAt == this.updatedAt);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> realName;
  final Value<String?> studentId;
  final Value<String?> avatar;
  final Value<String?> school;
  final Value<String?> gaokaoYear;
  final Value<int?> classGroupId;
  final Value<String?> phone;
  final Value<String?> updatedAt;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.realName = const Value.absent(),
    this.studentId = const Value.absent(),
    this.avatar = const Value.absent(),
    this.school = const Value.absent(),
    this.gaokaoYear = const Value.absent(),
    this.classGroupId = const Value.absent(),
    this.phone = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.realName = const Value.absent(),
    this.studentId = const Value.absent(),
    this.avatar = const Value.absent(),
    this.school = const Value.absent(),
    this.gaokaoYear = const Value.absent(),
    this.classGroupId = const Value.absent(),
    this.phone = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<UserProfileRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? realName,
    Expression<String>? studentId,
    Expression<String>? avatar,
    Expression<String>? school,
    Expression<String>? gaokaoYear,
    Expression<int>? classGroupId,
    Expression<String>? phone,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (realName != null) 'real_name': realName,
      if (studentId != null) 'student_id': studentId,
      if (avatar != null) 'avatar': avatar,
      if (school != null) 'school': school,
      if (gaokaoYear != null) 'gaokao_year': gaokaoYear,
      if (classGroupId != null) 'class_group_id': classGroupId,
      if (phone != null) 'phone': phone,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UserProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? realName,
    Value<String?>? studentId,
    Value<String?>? avatar,
    Value<String?>? school,
    Value<String?>? gaokaoYear,
    Value<int?>? classGroupId,
    Value<String?>? phone,
    Value<String?>? updatedAt,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      realName: realName ?? this.realName,
      studentId: studentId ?? this.studentId,
      avatar: avatar ?? this.avatar,
      school: school ?? this.school,
      gaokaoYear: gaokaoYear ?? this.gaokaoYear,
      classGroupId: classGroupId ?? this.classGroupId,
      phone: phone ?? this.phone,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (realName.present) {
      map['real_name'] = Variable<String>(realName.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (school.present) {
      map['school'] = Variable<String>(school.value);
    }
    if (gaokaoYear.present) {
      map['gaokao_year'] = Variable<String>(gaokaoYear.value);
    }
    if (classGroupId.present) {
      map['class_group_id'] = Variable<int>(classGroupId.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('realName: $realName, ')
          ..write('studentId: $studentId, ')
          ..write('avatar: $avatar, ')
          ..write('school: $school, ')
          ..write('gaokaoYear: $gaokaoYear, ')
          ..write('classGroupId: $classGroupId, ')
          ..write('phone: $phone, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $UserLoginLogsTable extends UserLoginLogs
    with TableInfo<$UserLoginLogsTable, UserLoginLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserLoginLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _loginDateMeta = const VerificationMeta(
    'loginDate',
  );
  @override
  late final GeneratedColumn<String> loginDate = GeneratedColumn<String>(
    'login_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, loginDate, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_login_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserLoginLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('login_date')) {
      context.handle(
        _loginDateMeta,
        loginDate.isAcceptableOrUnknown(data['login_date']!, _loginDateMeta),
      );
    } else if (isInserting) {
      context.missing(_loginDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserLoginLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserLoginLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      loginDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}login_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserLoginLogsTable createAlias(String alias) {
    return $UserLoginLogsTable(attachedDatabase, alias);
  }
}

class UserLoginLogRow extends DataClass implements Insertable<UserLoginLogRow> {
  final int id;
  final String loginDate;
  final String createdAt;
  const UserLoginLogRow({
    required this.id,
    required this.loginDate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['login_date'] = Variable<String>(loginDate);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  UserLoginLogsCompanion toCompanion(bool nullToAbsent) {
    return UserLoginLogsCompanion(
      id: Value(id),
      loginDate: Value(loginDate),
      createdAt: Value(createdAt),
    );
  }

  factory UserLoginLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserLoginLogRow(
      id: serializer.fromJson<int>(json['id']),
      loginDate: serializer.fromJson<String>(json['loginDate']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'loginDate': serializer.toJson<String>(loginDate),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  UserLoginLogRow copyWith({int? id, String? loginDate, String? createdAt}) =>
      UserLoginLogRow(
        id: id ?? this.id,
        loginDate: loginDate ?? this.loginDate,
        createdAt: createdAt ?? this.createdAt,
      );
  UserLoginLogRow copyWithCompanion(UserLoginLogsCompanion data) {
    return UserLoginLogRow(
      id: data.id.present ? data.id.value : this.id,
      loginDate: data.loginDate.present ? data.loginDate.value : this.loginDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserLoginLogRow(')
          ..write('id: $id, ')
          ..write('loginDate: $loginDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, loginDate, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserLoginLogRow &&
          other.id == this.id &&
          other.loginDate == this.loginDate &&
          other.createdAt == this.createdAt);
}

class UserLoginLogsCompanion extends UpdateCompanion<UserLoginLogRow> {
  final Value<int> id;
  final Value<String> loginDate;
  final Value<String> createdAt;
  const UserLoginLogsCompanion({
    this.id = const Value.absent(),
    this.loginDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserLoginLogsCompanion.insert({
    this.id = const Value.absent(),
    required String loginDate,
    required String createdAt,
  }) : loginDate = Value(loginDate),
       createdAt = Value(createdAt);
  static Insertable<UserLoginLogRow> custom({
    Expression<int>? id,
    Expression<String>? loginDate,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loginDate != null) 'login_date': loginDate,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserLoginLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? loginDate,
    Value<String>? createdAt,
  }) {
    return UserLoginLogsCompanion(
      id: id ?? this.id,
      loginDate: loginDate ?? this.loginDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (loginDate.present) {
      map['login_date'] = Variable<String>(loginDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserLoginLogsCompanion(')
          ..write('id: $id, ')
          ..write('loginDate: $loginDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PointsTransactionsTable extends PointsTransactions
    with TableInfo<$PointsTransactionsTable, PointsTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PointsTransactionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceObjectIdMeta = const VerificationMeta(
    'sourceObjectId',
  );
  @override
  late final GeneratedColumn<int> sourceObjectId = GeneratedColumn<int>(
    'source_object_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amount,
    transactionType,
    source,
    sourceObjectId,
    description,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'points_transaction';
  @override
  VerificationContext validateIntegrity(
    Insertable<PointsTransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_object_id')) {
      context.handle(
        _sourceObjectIdMeta,
        sourceObjectId.isAcceptableOrUnknown(
          data['source_object_id']!,
          _sourceObjectIdMeta,
        ),
      );
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PointsTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PointsTransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceObjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_object_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PointsTransactionsTable createAlias(String alias) {
    return $PointsTransactionsTable(attachedDatabase, alias);
  }
}

class PointsTransactionRow extends DataClass
    implements Insertable<PointsTransactionRow> {
  final int id;
  final int amount;
  final String transactionType;
  final String source;
  final int? sourceObjectId;
  final String? description;
  final String createdAt;
  const PointsTransactionRow({
    required this.id,
    required this.amount,
    required this.transactionType,
    required this.source,
    this.sourceObjectId,
    this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount'] = Variable<int>(amount);
    map['transaction_type'] = Variable<String>(transactionType);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceObjectId != null) {
      map['source_object_id'] = Variable<int>(sourceObjectId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  PointsTransactionsCompanion toCompanion(bool nullToAbsent) {
    return PointsTransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      transactionType: Value(transactionType),
      source: Value(source),
      sourceObjectId: sourceObjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceObjectId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory PointsTransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PointsTransactionRow(
      id: serializer.fromJson<int>(json['id']),
      amount: serializer.fromJson<int>(json['amount']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      source: serializer.fromJson<String>(json['source']),
      sourceObjectId: serializer.fromJson<int?>(json['sourceObjectId']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amount': serializer.toJson<int>(amount),
      'transactionType': serializer.toJson<String>(transactionType),
      'source': serializer.toJson<String>(source),
      'sourceObjectId': serializer.toJson<int?>(sourceObjectId),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  PointsTransactionRow copyWith({
    int? id,
    int? amount,
    String? transactionType,
    String? source,
    Value<int?> sourceObjectId = const Value.absent(),
    Value<String?> description = const Value.absent(),
    String? createdAt,
  }) => PointsTransactionRow(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    transactionType: transactionType ?? this.transactionType,
    source: source ?? this.source,
    sourceObjectId: sourceObjectId.present
        ? sourceObjectId.value
        : this.sourceObjectId,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  PointsTransactionRow copyWithCompanion(PointsTransactionsCompanion data) {
    return PointsTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      source: data.source.present ? data.source.value : this.source,
      sourceObjectId: data.sourceObjectId.present
          ? data.sourceObjectId.value
          : this.sourceObjectId,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PointsTransactionRow(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('transactionType: $transactionType, ')
          ..write('source: $source, ')
          ..write('sourceObjectId: $sourceObjectId, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amount,
    transactionType,
    source,
    sourceObjectId,
    description,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PointsTransactionRow &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.transactionType == this.transactionType &&
          other.source == this.source &&
          other.sourceObjectId == this.sourceObjectId &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class PointsTransactionsCompanion
    extends UpdateCompanion<PointsTransactionRow> {
  final Value<int> id;
  final Value<int> amount;
  final Value<String> transactionType;
  final Value<String> source;
  final Value<int?> sourceObjectId;
  final Value<String?> description;
  final Value<String> createdAt;
  const PointsTransactionsCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceObjectId = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PointsTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int amount,
    required String transactionType,
    required String source,
    this.sourceObjectId = const Value.absent(),
    this.description = const Value.absent(),
    required String createdAt,
  }) : amount = Value(amount),
       transactionType = Value(transactionType),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<PointsTransactionRow> custom({
    Expression<int>? id,
    Expression<int>? amount,
    Expression<String>? transactionType,
    Expression<String>? source,
    Expression<int>? sourceObjectId,
    Expression<String>? description,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (transactionType != null) 'transaction_type': transactionType,
      if (source != null) 'source': source,
      if (sourceObjectId != null) 'source_object_id': sourceObjectId,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PointsTransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? amount,
    Value<String>? transactionType,
    Value<String>? source,
    Value<int?>? sourceObjectId,
    Value<String?>? description,
    Value<String>? createdAt,
  }) {
    return PointsTransactionsCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      source: source ?? this.source,
      sourceObjectId: sourceObjectId ?? this.sourceObjectId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceObjectId.present) {
      map['source_object_id'] = Variable<int>(sourceObjectId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PointsTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('transactionType: $transactionType, ')
          ..write('source: $source, ')
          ..write('sourceObjectId: $sourceObjectId, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StudentAchievementsTable extends StudentAchievements
    with TableInfo<$StudentAchievementsTable, StudentAchievementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentAchievementsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _achievementCodeMeta = const VerificationMeta(
    'achievementCode',
  );
  @override
  late final GeneratedColumn<String> achievementCode = GeneratedColumn<String>(
    'achievement_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isUnlockedMeta = const VerificationMeta(
    'isUnlocked',
  );
  @override
  late final GeneratedColumn<int> isUnlocked = GeneratedColumn<int>(
    'is_unlocked',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<String> unlockedAt = GeneratedColumn<String>(
    'unlocked_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    achievementCode,
    progress,
    isUnlocked,
    unlockedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'student_achievement';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudentAchievementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('achievement_code')) {
      context.handle(
        _achievementCodeMeta,
        achievementCode.isAcceptableOrUnknown(
          data['achievement_code']!,
          _achievementCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_achievementCodeMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('is_unlocked')) {
      context.handle(
        _isUnlockedMeta,
        isUnlocked.isAcceptableOrUnknown(data['is_unlocked']!, _isUnlockedMeta),
      );
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentAchievementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentAchievementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      achievementCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}achievement_code'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress'],
      )!,
      isUnlocked: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_unlocked'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unlocked_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $StudentAchievementsTable createAlias(String alias) {
    return $StudentAchievementsTable(attachedDatabase, alias);
  }
}

class StudentAchievementRow extends DataClass
    implements Insertable<StudentAchievementRow> {
  final int id;
  final String achievementCode;
  final int progress;
  final int isUnlocked;
  final String? unlockedAt;
  final String? updatedAt;
  const StudentAchievementRow({
    required this.id,
    required this.achievementCode,
    required this.progress,
    required this.isUnlocked,
    this.unlockedAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['achievement_code'] = Variable<String>(achievementCode);
    map['progress'] = Variable<int>(progress);
    map['is_unlocked'] = Variable<int>(isUnlocked);
    if (!nullToAbsent || unlockedAt != null) {
      map['unlocked_at'] = Variable<String>(unlockedAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  StudentAchievementsCompanion toCompanion(bool nullToAbsent) {
    return StudentAchievementsCompanion(
      id: Value(id),
      achievementCode: Value(achievementCode),
      progress: Value(progress),
      isUnlocked: Value(isUnlocked),
      unlockedAt: unlockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(unlockedAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory StudentAchievementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentAchievementRow(
      id: serializer.fromJson<int>(json['id']),
      achievementCode: serializer.fromJson<String>(json['achievementCode']),
      progress: serializer.fromJson<int>(json['progress']),
      isUnlocked: serializer.fromJson<int>(json['isUnlocked']),
      unlockedAt: serializer.fromJson<String?>(json['unlockedAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'achievementCode': serializer.toJson<String>(achievementCode),
      'progress': serializer.toJson<int>(progress),
      'isUnlocked': serializer.toJson<int>(isUnlocked),
      'unlockedAt': serializer.toJson<String?>(unlockedAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  StudentAchievementRow copyWith({
    int? id,
    String? achievementCode,
    int? progress,
    int? isUnlocked,
    Value<String?> unlockedAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => StudentAchievementRow(
    id: id ?? this.id,
    achievementCode: achievementCode ?? this.achievementCode,
    progress: progress ?? this.progress,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    unlockedAt: unlockedAt.present ? unlockedAt.value : this.unlockedAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  StudentAchievementRow copyWithCompanion(StudentAchievementsCompanion data) {
    return StudentAchievementRow(
      id: data.id.present ? data.id.value : this.id,
      achievementCode: data.achievementCode.present
          ? data.achievementCode.value
          : this.achievementCode,
      progress: data.progress.present ? data.progress.value : this.progress,
      isUnlocked: data.isUnlocked.present
          ? data.isUnlocked.value
          : this.isUnlocked,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentAchievementRow(')
          ..write('id: $id, ')
          ..write('achievementCode: $achievementCode, ')
          ..write('progress: $progress, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    achievementCode,
    progress,
    isUnlocked,
    unlockedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentAchievementRow &&
          other.id == this.id &&
          other.achievementCode == this.achievementCode &&
          other.progress == this.progress &&
          other.isUnlocked == this.isUnlocked &&
          other.unlockedAt == this.unlockedAt &&
          other.updatedAt == this.updatedAt);
}

class StudentAchievementsCompanion
    extends UpdateCompanion<StudentAchievementRow> {
  final Value<int> id;
  final Value<String> achievementCode;
  final Value<int> progress;
  final Value<int> isUnlocked;
  final Value<String?> unlockedAt;
  final Value<String?> updatedAt;
  const StudentAchievementsCompanion({
    this.id = const Value.absent(),
    this.achievementCode = const Value.absent(),
    this.progress = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StudentAchievementsCompanion.insert({
    this.id = const Value.absent(),
    required String achievementCode,
    this.progress = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : achievementCode = Value(achievementCode);
  static Insertable<StudentAchievementRow> custom({
    Expression<int>? id,
    Expression<String>? achievementCode,
    Expression<int>? progress,
    Expression<int>? isUnlocked,
    Expression<String>? unlockedAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (achievementCode != null) 'achievement_code': achievementCode,
      if (progress != null) 'progress': progress,
      if (isUnlocked != null) 'is_unlocked': isUnlocked,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StudentAchievementsCompanion copyWith({
    Value<int>? id,
    Value<String>? achievementCode,
    Value<int>? progress,
    Value<int>? isUnlocked,
    Value<String?>? unlockedAt,
    Value<String?>? updatedAt,
  }) {
    return StudentAchievementsCompanion(
      id: id ?? this.id,
      achievementCode: achievementCode ?? this.achievementCode,
      progress: progress ?? this.progress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (achievementCode.present) {
      map['achievement_code'] = Variable<String>(achievementCode.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (isUnlocked.present) {
      map['is_unlocked'] = Variable<int>(isUnlocked.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<String>(unlockedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentAchievementsCompanion(')
          ..write('id: $id, ')
          ..write('achievementCode: $achievementCode, ')
          ..write('progress: $progress, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SubmissionsTable extends Submissions
    with TableInfo<$SubmissionsTable, SubmissionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubmissionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<int> studentId = GeneratedColumn<int>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assignmentIdMeta = const VerificationMeta(
    'assignmentId',
  );
  @override
  late final GeneratedColumn<int> assignmentId = GeneratedColumn<int>(
    'assignment_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    studentId,
    assignmentId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'submission';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubmissionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('assignment_id')) {
      context.handle(
        _assignmentIdMeta,
        assignmentId.isAcceptableOrUnknown(
          data['assignment_id']!,
          _assignmentIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubmissionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubmissionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_id'],
      )!,
      assignmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}assignment_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SubmissionsTable createAlias(String alias) {
    return $SubmissionsTable(attachedDatabase, alias);
  }
}

class SubmissionRow extends DataClass implements Insertable<SubmissionRow> {
  final int id;
  final int? serverId;
  final int studentId;
  final int? assignmentId;
  final String createdAt;
  final String updatedAt;
  const SubmissionRow({
    required this.id,
    this.serverId,
    required this.studentId,
    this.assignmentId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['student_id'] = Variable<int>(studentId);
    if (!nullToAbsent || assignmentId != null) {
      map['assignment_id'] = Variable<int>(assignmentId);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  SubmissionsCompanion toCompanion(bool nullToAbsent) {
    return SubmissionsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      studentId: Value(studentId),
      assignmentId: assignmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignmentId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SubmissionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubmissionRow(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      studentId: serializer.fromJson<int>(json['studentId']),
      assignmentId: serializer.fromJson<int?>(json['assignmentId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'studentId': serializer.toJson<int>(studentId),
      'assignmentId': serializer.toJson<int?>(assignmentId),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  SubmissionRow copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    int? studentId,
    Value<int?> assignmentId = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => SubmissionRow(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    studentId: studentId ?? this.studentId,
    assignmentId: assignmentId.present ? assignmentId.value : this.assignmentId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SubmissionRow copyWithCompanion(SubmissionsCompanion data) {
    return SubmissionRow(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      assignmentId: data.assignmentId.present
          ? data.assignmentId.value
          : this.assignmentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubmissionRow(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('studentId: $studentId, ')
          ..write('assignmentId: $assignmentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, serverId, studentId, assignmentId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubmissionRow &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.studentId == this.studentId &&
          other.assignmentId == this.assignmentId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubmissionsCompanion extends UpdateCompanion<SubmissionRow> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> studentId;
  final Value<int?> assignmentId;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  const SubmissionsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.assignmentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SubmissionsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int studentId,
    this.assignmentId = const Value.absent(),
    required String createdAt,
    required String updatedAt,
  }) : studentId = Value(studentId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SubmissionRow> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? studentId,
    Expression<int>? assignmentId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (studentId != null) 'student_id': studentId,
      if (assignmentId != null) 'assignment_id': assignmentId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SubmissionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<int>? studentId,
    Value<int?>? assignmentId,
    Value<String>? createdAt,
    Value<String>? updatedAt,
  }) {
    return SubmissionsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      studentId: studentId ?? this.studentId,
      assignmentId: assignmentId ?? this.assignmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<int>(studentId.value);
    }
    if (assignmentId.present) {
      map['assignment_id'] = Variable<int>(assignmentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubmissionsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('studentId: $studentId, ')
          ..write('assignmentId: $assignmentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SubmissionDetailsTable extends SubmissionDetails
    with TableInfo<$SubmissionDetailsTable, SubmissionDetailRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubmissionDetailsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submissionIdMeta = const VerificationMeta(
    'submissionId',
  );
  @override
  late final GeneratedColumn<int> submissionId = GeneratedColumn<int>(
    'submission_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _attemptNumberMeta = const VerificationMeta(
    'attemptNumber',
  );
  @override
  late final GeneratedColumn<int> attemptNumber = GeneratedColumn<int>(
    'attempt_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('in_progress'),
  );
  static const VerificationMeta _answerTextMeta = const VerificationMeta(
    'answerText',
  );
  @override
  late final GeneratedColumn<String> answerText = GeneratedColumn<String>(
    'answer_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCorrectMeta = const VerificationMeta(
    'isCorrect',
  );
  @override
  late final GeneratedColumn<int> isCorrect = GeneratedColumn<int>(
    'is_correct',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    submissionId,
    questionId,
    attemptNumber,
    status,
    answerText,
    isCorrect,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'submission_detail';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubmissionDetailRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('submission_id')) {
      context.handle(
        _submissionIdMeta,
        submissionId.isAcceptableOrUnknown(
          data['submission_id']!,
          _submissionIdMeta,
        ),
      );
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('attempt_number')) {
      context.handle(
        _attemptNumberMeta,
        attemptNumber.isAcceptableOrUnknown(
          data['attempt_number']!,
          _attemptNumberMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('answer_text')) {
      context.handle(
        _answerTextMeta,
        answerText.isAcceptableOrUnknown(data['answer_text']!, _answerTextMeta),
      );
    }
    if (data.containsKey('is_correct')) {
      context.handle(
        _isCorrectMeta,
        isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubmissionDetailRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubmissionDetailRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      submissionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}submission_id'],
      ),
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_id'],
      )!,
      attemptNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_number'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      answerText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_text'],
      ),
      isCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_correct'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SubmissionDetailsTable createAlias(String alias) {
    return $SubmissionDetailsTable(attachedDatabase, alias);
  }
}

class SubmissionDetailRow extends DataClass
    implements Insertable<SubmissionDetailRow> {
  final int id;
  final int? serverId;
  final int? submissionId;
  final int questionId;
  final int attemptNumber;
  final String status;
  final String? answerText;
  final int? isCorrect;
  final String createdAt;
  final String updatedAt;
  const SubmissionDetailRow({
    required this.id,
    this.serverId,
    this.submissionId,
    required this.questionId,
    required this.attemptNumber,
    required this.status,
    this.answerText,
    this.isCorrect,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || submissionId != null) {
      map['submission_id'] = Variable<int>(submissionId);
    }
    map['question_id'] = Variable<int>(questionId);
    map['attempt_number'] = Variable<int>(attemptNumber);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || answerText != null) {
      map['answer_text'] = Variable<String>(answerText);
    }
    if (!nullToAbsent || isCorrect != null) {
      map['is_correct'] = Variable<int>(isCorrect);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  SubmissionDetailsCompanion toCompanion(bool nullToAbsent) {
    return SubmissionDetailsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      submissionId: submissionId == null && nullToAbsent
          ? const Value.absent()
          : Value(submissionId),
      questionId: Value(questionId),
      attemptNumber: Value(attemptNumber),
      status: Value(status),
      answerText: answerText == null && nullToAbsent
          ? const Value.absent()
          : Value(answerText),
      isCorrect: isCorrect == null && nullToAbsent
          ? const Value.absent()
          : Value(isCorrect),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SubmissionDetailRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubmissionDetailRow(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      submissionId: serializer.fromJson<int?>(json['submissionId']),
      questionId: serializer.fromJson<int>(json['questionId']),
      attemptNumber: serializer.fromJson<int>(json['attemptNumber']),
      status: serializer.fromJson<String>(json['status']),
      answerText: serializer.fromJson<String?>(json['answerText']),
      isCorrect: serializer.fromJson<int?>(json['isCorrect']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'submissionId': serializer.toJson<int?>(submissionId),
      'questionId': serializer.toJson<int>(questionId),
      'attemptNumber': serializer.toJson<int>(attemptNumber),
      'status': serializer.toJson<String>(status),
      'answerText': serializer.toJson<String?>(answerText),
      'isCorrect': serializer.toJson<int?>(isCorrect),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  SubmissionDetailRow copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    Value<int?> submissionId = const Value.absent(),
    int? questionId,
    int? attemptNumber,
    String? status,
    Value<String?> answerText = const Value.absent(),
    Value<int?> isCorrect = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => SubmissionDetailRow(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    submissionId: submissionId.present ? submissionId.value : this.submissionId,
    questionId: questionId ?? this.questionId,
    attemptNumber: attemptNumber ?? this.attemptNumber,
    status: status ?? this.status,
    answerText: answerText.present ? answerText.value : this.answerText,
    isCorrect: isCorrect.present ? isCorrect.value : this.isCorrect,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SubmissionDetailRow copyWithCompanion(SubmissionDetailsCompanion data) {
    return SubmissionDetailRow(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      submissionId: data.submissionId.present
          ? data.submissionId.value
          : this.submissionId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      attemptNumber: data.attemptNumber.present
          ? data.attemptNumber.value
          : this.attemptNumber,
      status: data.status.present ? data.status.value : this.status,
      answerText: data.answerText.present
          ? data.answerText.value
          : this.answerText,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubmissionDetailRow(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('submissionId: $submissionId, ')
          ..write('questionId: $questionId, ')
          ..write('attemptNumber: $attemptNumber, ')
          ..write('status: $status, ')
          ..write('answerText: $answerText, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    submissionId,
    questionId,
    attemptNumber,
    status,
    answerText,
    isCorrect,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubmissionDetailRow &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.submissionId == this.submissionId &&
          other.questionId == this.questionId &&
          other.attemptNumber == this.attemptNumber &&
          other.status == this.status &&
          other.answerText == this.answerText &&
          other.isCorrect == this.isCorrect &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubmissionDetailsCompanion extends UpdateCompanion<SubmissionDetailRow> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int?> submissionId;
  final Value<int> questionId;
  final Value<int> attemptNumber;
  final Value<String> status;
  final Value<String?> answerText;
  final Value<int?> isCorrect;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  const SubmissionDetailsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.submissionId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.attemptNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.answerText = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SubmissionDetailsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.submissionId = const Value.absent(),
    required int questionId,
    this.attemptNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.answerText = const Value.absent(),
    this.isCorrect = const Value.absent(),
    required String createdAt,
    required String updatedAt,
  }) : questionId = Value(questionId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SubmissionDetailRow> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? submissionId,
    Expression<int>? questionId,
    Expression<int>? attemptNumber,
    Expression<String>? status,
    Expression<String>? answerText,
    Expression<int>? isCorrect,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (submissionId != null) 'submission_id': submissionId,
      if (questionId != null) 'question_id': questionId,
      if (attemptNumber != null) 'attempt_number': attemptNumber,
      if (status != null) 'status': status,
      if (answerText != null) 'answer_text': answerText,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SubmissionDetailsCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<int?>? submissionId,
    Value<int>? questionId,
    Value<int>? attemptNumber,
    Value<String>? status,
    Value<String?>? answerText,
    Value<int?>? isCorrect,
    Value<String>? createdAt,
    Value<String>? updatedAt,
  }) {
    return SubmissionDetailsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      submissionId: submissionId ?? this.submissionId,
      questionId: questionId ?? this.questionId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      status: status ?? this.status,
      answerText: answerText ?? this.answerText,
      isCorrect: isCorrect ?? this.isCorrect,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (submissionId.present) {
      map['submission_id'] = Variable<int>(submissionId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (attemptNumber.present) {
      map['attempt_number'] = Variable<int>(attemptNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (answerText.present) {
      map['answer_text'] = Variable<String>(answerText.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<int>(isCorrect.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubmissionDetailsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('submissionId: $submissionId, ')
          ..write('questionId: $questionId, ')
          ..write('attemptNumber: $attemptNumber, ')
          ..write('status: $status, ')
          ..write('answerText: $answerText, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StepFeedbacksTable extends StepFeedbacks
    with TableInfo<$StepFeedbacksTable, StepFeedbackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StepFeedbacksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submissionDetailIdMeta =
      const VerificationMeta('submissionDetailId');
  @override
  late final GeneratedColumn<int> submissionDetailId = GeneratedColumn<int>(
    'submission_detail_id',
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
  static const VerificationMeta _subQuestionIndexMeta = const VerificationMeta(
    'subQuestionIndex',
  );
  @override
  late final GeneratedColumn<int> subQuestionIndex = GeneratedColumn<int>(
    'sub_question_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _methodIdMeta = const VerificationMeta(
    'methodId',
  );
  @override
  late final GeneratedColumn<int> methodId = GeneratedColumn<int>(
    'method_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    submissionDetailId,
    questionId,
    subQuestionIndex,
    methodId,
    stepNumber,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'step_feedback';
  @override
  VerificationContext validateIntegrity(
    Insertable<StepFeedbackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('submission_detail_id')) {
      context.handle(
        _submissionDetailIdMeta,
        submissionDetailId.isAcceptableOrUnknown(
          data['submission_detail_id']!,
          _submissionDetailIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_submissionDetailIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('sub_question_index')) {
      context.handle(
        _subQuestionIndexMeta,
        subQuestionIndex.isAcceptableOrUnknown(
          data['sub_question_index']!,
          _subQuestionIndexMeta,
        ),
      );
    }
    if (data.containsKey('method_id')) {
      context.handle(
        _methodIdMeta,
        methodId.isAcceptableOrUnknown(data['method_id']!, _methodIdMeta),
      );
    }
    if (data.containsKey('step_number')) {
      context.handle(
        _stepNumberMeta,
        stepNumber.isAcceptableOrUnknown(data['step_number']!, _stepNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_stepNumberMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StepFeedbackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StepFeedbackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      submissionDetailId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}submission_detail_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_id'],
      )!,
      subQuestionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sub_question_index'],
      ),
      methodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}method_id'],
      ),
      stepNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_number'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StepFeedbacksTable createAlias(String alias) {
    return $StepFeedbacksTable(attachedDatabase, alias);
  }
}

class StepFeedbackRow extends DataClass implements Insertable<StepFeedbackRow> {
  final int id;
  final int? serverId;
  final int submissionDetailId;
  final int questionId;
  final int? subQuestionIndex;
  final int? methodId;
  final int stepNumber;
  final String status;
  final String createdAt;
  const StepFeedbackRow({
    required this.id,
    this.serverId,
    required this.submissionDetailId,
    required this.questionId,
    this.subQuestionIndex,
    this.methodId,
    required this.stepNumber,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['submission_detail_id'] = Variable<int>(submissionDetailId);
    map['question_id'] = Variable<int>(questionId);
    if (!nullToAbsent || subQuestionIndex != null) {
      map['sub_question_index'] = Variable<int>(subQuestionIndex);
    }
    if (!nullToAbsent || methodId != null) {
      map['method_id'] = Variable<int>(methodId);
    }
    map['step_number'] = Variable<int>(stepNumber);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  StepFeedbacksCompanion toCompanion(bool nullToAbsent) {
    return StepFeedbacksCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      submissionDetailId: Value(submissionDetailId),
      questionId: Value(questionId),
      subQuestionIndex: subQuestionIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(subQuestionIndex),
      methodId: methodId == null && nullToAbsent
          ? const Value.absent()
          : Value(methodId),
      stepNumber: Value(stepNumber),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory StepFeedbackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StepFeedbackRow(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      submissionDetailId: serializer.fromJson<int>(json['submissionDetailId']),
      questionId: serializer.fromJson<int>(json['questionId']),
      subQuestionIndex: serializer.fromJson<int?>(json['subQuestionIndex']),
      methodId: serializer.fromJson<int?>(json['methodId']),
      stepNumber: serializer.fromJson<int>(json['stepNumber']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'submissionDetailId': serializer.toJson<int>(submissionDetailId),
      'questionId': serializer.toJson<int>(questionId),
      'subQuestionIndex': serializer.toJson<int?>(subQuestionIndex),
      'methodId': serializer.toJson<int?>(methodId),
      'stepNumber': serializer.toJson<int>(stepNumber),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  StepFeedbackRow copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    int? submissionDetailId,
    int? questionId,
    Value<int?> subQuestionIndex = const Value.absent(),
    Value<int?> methodId = const Value.absent(),
    int? stepNumber,
    String? status,
    String? createdAt,
  }) => StepFeedbackRow(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    submissionDetailId: submissionDetailId ?? this.submissionDetailId,
    questionId: questionId ?? this.questionId,
    subQuestionIndex: subQuestionIndex.present
        ? subQuestionIndex.value
        : this.subQuestionIndex,
    methodId: methodId.present ? methodId.value : this.methodId,
    stepNumber: stepNumber ?? this.stepNumber,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  StepFeedbackRow copyWithCompanion(StepFeedbacksCompanion data) {
    return StepFeedbackRow(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      submissionDetailId: data.submissionDetailId.present
          ? data.submissionDetailId.value
          : this.submissionDetailId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      subQuestionIndex: data.subQuestionIndex.present
          ? data.subQuestionIndex.value
          : this.subQuestionIndex,
      methodId: data.methodId.present ? data.methodId.value : this.methodId,
      stepNumber: data.stepNumber.present
          ? data.stepNumber.value
          : this.stepNumber,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StepFeedbackRow(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('submissionDetailId: $submissionDetailId, ')
          ..write('questionId: $questionId, ')
          ..write('subQuestionIndex: $subQuestionIndex, ')
          ..write('methodId: $methodId, ')
          ..write('stepNumber: $stepNumber, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    submissionDetailId,
    questionId,
    subQuestionIndex,
    methodId,
    stepNumber,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StepFeedbackRow &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.submissionDetailId == this.submissionDetailId &&
          other.questionId == this.questionId &&
          other.subQuestionIndex == this.subQuestionIndex &&
          other.methodId == this.methodId &&
          other.stepNumber == this.stepNumber &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class StepFeedbacksCompanion extends UpdateCompanion<StepFeedbackRow> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> submissionDetailId;
  final Value<int> questionId;
  final Value<int?> subQuestionIndex;
  final Value<int?> methodId;
  final Value<int> stepNumber;
  final Value<String> status;
  final Value<String> createdAt;
  const StepFeedbacksCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.submissionDetailId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.subQuestionIndex = const Value.absent(),
    this.methodId = const Value.absent(),
    this.stepNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StepFeedbacksCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int submissionDetailId,
    required int questionId,
    this.subQuestionIndex = const Value.absent(),
    this.methodId = const Value.absent(),
    required int stepNumber,
    required String status,
    required String createdAt,
  }) : submissionDetailId = Value(submissionDetailId),
       questionId = Value(questionId),
       stepNumber = Value(stepNumber),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<StepFeedbackRow> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? submissionDetailId,
    Expression<int>? questionId,
    Expression<int>? subQuestionIndex,
    Expression<int>? methodId,
    Expression<int>? stepNumber,
    Expression<String>? status,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (submissionDetailId != null)
        'submission_detail_id': submissionDetailId,
      if (questionId != null) 'question_id': questionId,
      if (subQuestionIndex != null) 'sub_question_index': subQuestionIndex,
      if (methodId != null) 'method_id': methodId,
      if (stepNumber != null) 'step_number': stepNumber,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StepFeedbacksCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<int>? submissionDetailId,
    Value<int>? questionId,
    Value<int?>? subQuestionIndex,
    Value<int?>? methodId,
    Value<int>? stepNumber,
    Value<String>? status,
    Value<String>? createdAt,
  }) {
    return StepFeedbacksCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      submissionDetailId: submissionDetailId ?? this.submissionDetailId,
      questionId: questionId ?? this.questionId,
      subQuestionIndex: subQuestionIndex ?? this.subQuestionIndex,
      methodId: methodId ?? this.methodId,
      stepNumber: stepNumber ?? this.stepNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (submissionDetailId.present) {
      map['submission_detail_id'] = Variable<int>(submissionDetailId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (subQuestionIndex.present) {
      map['sub_question_index'] = Variable<int>(subQuestionIndex.value);
    }
    if (methodId.present) {
      map['method_id'] = Variable<int>(methodId.value);
    }
    if (stepNumber.present) {
      map['step_number'] = Variable<int>(stepNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepFeedbacksCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('submissionDetailId: $submissionDetailId, ')
          ..write('questionId: $questionId, ')
          ..write('subQuestionIndex: $subQuestionIndex, ')
          ..write('methodId: $methodId, ')
          ..write('stepNumber: $stepNumber, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CardFeedbacksTable extends CardFeedbacks
    with TableInfo<$CardFeedbacksTable, CardFeedbackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardFeedbacksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submissionDetailIdMeta =
      const VerificationMeta('submissionDetailId');
  @override
  late final GeneratedColumn<int> submissionDetailId = GeneratedColumn<int>(
    'submission_detail_id',
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
  static const VerificationMeta _cardTitleMeta = const VerificationMeta(
    'cardTitle',
  );
  @override
  late final GeneratedColumn<String> cardTitle = GeneratedColumn<String>(
    'card_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardStatusMeta = const VerificationMeta(
    'cardStatus',
  );
  @override
  late final GeneratedColumn<String> cardStatus = GeneratedColumn<String>(
    'card_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    submissionDetailId,
    questionId,
    cardTitle,
    cardStatus,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_feedback';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardFeedbackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('submission_detail_id')) {
      context.handle(
        _submissionDetailIdMeta,
        submissionDetailId.isAcceptableOrUnknown(
          data['submission_detail_id']!,
          _submissionDetailIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_submissionDetailIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('card_title')) {
      context.handle(
        _cardTitleMeta,
        cardTitle.isAcceptableOrUnknown(data['card_title']!, _cardTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_cardTitleMeta);
    }
    if (data.containsKey('card_status')) {
      context.handle(
        _cardStatusMeta,
        cardStatus.isAcceptableOrUnknown(data['card_status']!, _cardStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_cardStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardFeedbackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardFeedbackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      submissionDetailId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}submission_detail_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_id'],
      )!,
      cardTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_title'],
      )!,
      cardStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CardFeedbacksTable createAlias(String alias) {
    return $CardFeedbacksTable(attachedDatabase, alias);
  }
}

class CardFeedbackRow extends DataClass implements Insertable<CardFeedbackRow> {
  final int id;
  final int? serverId;
  final int submissionDetailId;
  final int questionId;
  final String cardTitle;
  final String cardStatus;
  final String createdAt;
  const CardFeedbackRow({
    required this.id,
    this.serverId,
    required this.submissionDetailId,
    required this.questionId,
    required this.cardTitle,
    required this.cardStatus,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['submission_detail_id'] = Variable<int>(submissionDetailId);
    map['question_id'] = Variable<int>(questionId);
    map['card_title'] = Variable<String>(cardTitle);
    map['card_status'] = Variable<String>(cardStatus);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  CardFeedbacksCompanion toCompanion(bool nullToAbsent) {
    return CardFeedbacksCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      submissionDetailId: Value(submissionDetailId),
      questionId: Value(questionId),
      cardTitle: Value(cardTitle),
      cardStatus: Value(cardStatus),
      createdAt: Value(createdAt),
    );
  }

  factory CardFeedbackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardFeedbackRow(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      submissionDetailId: serializer.fromJson<int>(json['submissionDetailId']),
      questionId: serializer.fromJson<int>(json['questionId']),
      cardTitle: serializer.fromJson<String>(json['cardTitle']),
      cardStatus: serializer.fromJson<String>(json['cardStatus']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'submissionDetailId': serializer.toJson<int>(submissionDetailId),
      'questionId': serializer.toJson<int>(questionId),
      'cardTitle': serializer.toJson<String>(cardTitle),
      'cardStatus': serializer.toJson<String>(cardStatus),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  CardFeedbackRow copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    int? submissionDetailId,
    int? questionId,
    String? cardTitle,
    String? cardStatus,
    String? createdAt,
  }) => CardFeedbackRow(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    submissionDetailId: submissionDetailId ?? this.submissionDetailId,
    questionId: questionId ?? this.questionId,
    cardTitle: cardTitle ?? this.cardTitle,
    cardStatus: cardStatus ?? this.cardStatus,
    createdAt: createdAt ?? this.createdAt,
  );
  CardFeedbackRow copyWithCompanion(CardFeedbacksCompanion data) {
    return CardFeedbackRow(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      submissionDetailId: data.submissionDetailId.present
          ? data.submissionDetailId.value
          : this.submissionDetailId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      cardTitle: data.cardTitle.present ? data.cardTitle.value : this.cardTitle,
      cardStatus: data.cardStatus.present
          ? data.cardStatus.value
          : this.cardStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardFeedbackRow(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('submissionDetailId: $submissionDetailId, ')
          ..write('questionId: $questionId, ')
          ..write('cardTitle: $cardTitle, ')
          ..write('cardStatus: $cardStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    submissionDetailId,
    questionId,
    cardTitle,
    cardStatus,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardFeedbackRow &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.submissionDetailId == this.submissionDetailId &&
          other.questionId == this.questionId &&
          other.cardTitle == this.cardTitle &&
          other.cardStatus == this.cardStatus &&
          other.createdAt == this.createdAt);
}

class CardFeedbacksCompanion extends UpdateCompanion<CardFeedbackRow> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> submissionDetailId;
  final Value<int> questionId;
  final Value<String> cardTitle;
  final Value<String> cardStatus;
  final Value<String> createdAt;
  const CardFeedbacksCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.submissionDetailId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.cardTitle = const Value.absent(),
    this.cardStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CardFeedbacksCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int submissionDetailId,
    required int questionId,
    required String cardTitle,
    required String cardStatus,
    required String createdAt,
  }) : submissionDetailId = Value(submissionDetailId),
       questionId = Value(questionId),
       cardTitle = Value(cardTitle),
       cardStatus = Value(cardStatus),
       createdAt = Value(createdAt);
  static Insertable<CardFeedbackRow> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? submissionDetailId,
    Expression<int>? questionId,
    Expression<String>? cardTitle,
    Expression<String>? cardStatus,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (submissionDetailId != null)
        'submission_detail_id': submissionDetailId,
      if (questionId != null) 'question_id': questionId,
      if (cardTitle != null) 'card_title': cardTitle,
      if (cardStatus != null) 'card_status': cardStatus,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CardFeedbacksCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<int>? submissionDetailId,
    Value<int>? questionId,
    Value<String>? cardTitle,
    Value<String>? cardStatus,
    Value<String>? createdAt,
  }) {
    return CardFeedbacksCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      submissionDetailId: submissionDetailId ?? this.submissionDetailId,
      questionId: questionId ?? this.questionId,
      cardTitle: cardTitle ?? this.cardTitle,
      cardStatus: cardStatus ?? this.cardStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (submissionDetailId.present) {
      map['submission_detail_id'] = Variable<int>(submissionDetailId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (cardTitle.present) {
      map['card_title'] = Variable<String>(cardTitle.value);
    }
    if (cardStatus.present) {
      map['card_status'] = Variable<String>(cardStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardFeedbacksCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('submissionDetailId: $submissionDetailId, ')
          ..write('questionId: $questionId, ')
          ..write('cardTitle: $cardTitle, ')
          ..write('cardStatus: $cardStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $QuestionRatingsTable extends QuestionRatings
    with TableInfo<$QuestionRatingsTable, QuestionRatingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionRatingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _difficultyScoreMeta = const VerificationMeta(
    'difficultyScore',
  );
  @override
  late final GeneratedColumn<int> difficultyScore = GeneratedColumn<int>(
    'difficulty_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calculationScoreMeta = const VerificationMeta(
    'calculationScore',
  );
  @override
  late final GeneratedColumn<int> calculationScore = GeneratedColumn<int>(
    'calculation_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eleganceScoreMeta = const VerificationMeta(
    'eleganceScore',
  );
  @override
  late final GeneratedColumn<int> eleganceScore = GeneratedColumn<int>(
    'elegance_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    questionId,
    difficultyScore,
    calculationScore,
    eleganceScore,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_rating';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionRatingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('difficulty_score')) {
      context.handle(
        _difficultyScoreMeta,
        difficultyScore.isAcceptableOrUnknown(
          data['difficulty_score']!,
          _difficultyScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_difficultyScoreMeta);
    }
    if (data.containsKey('calculation_score')) {
      context.handle(
        _calculationScoreMeta,
        calculationScore.isAcceptableOrUnknown(
          data['calculation_score']!,
          _calculationScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calculationScoreMeta);
    }
    if (data.containsKey('elegance_score')) {
      context.handle(
        _eleganceScoreMeta,
        eleganceScore.isAcceptableOrUnknown(
          data['elegance_score']!,
          _eleganceScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eleganceScoreMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionRatingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionRatingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_id'],
      )!,
      difficultyScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty_score'],
      )!,
      calculationScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calculation_score'],
      )!,
      eleganceScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elegance_score'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QuestionRatingsTable createAlias(String alias) {
    return $QuestionRatingsTable(attachedDatabase, alias);
  }
}

class QuestionRatingRow extends DataClass
    implements Insertable<QuestionRatingRow> {
  final int id;
  final int? serverId;
  final int questionId;
  final int difficultyScore;
  final int calculationScore;
  final int eleganceScore;
  final String createdAt;
  const QuestionRatingRow({
    required this.id,
    this.serverId,
    required this.questionId,
    required this.difficultyScore,
    required this.calculationScore,
    required this.eleganceScore,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['question_id'] = Variable<int>(questionId);
    map['difficulty_score'] = Variable<int>(difficultyScore);
    map['calculation_score'] = Variable<int>(calculationScore);
    map['elegance_score'] = Variable<int>(eleganceScore);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  QuestionRatingsCompanion toCompanion(bool nullToAbsent) {
    return QuestionRatingsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      questionId: Value(questionId),
      difficultyScore: Value(difficultyScore),
      calculationScore: Value(calculationScore),
      eleganceScore: Value(eleganceScore),
      createdAt: Value(createdAt),
    );
  }

  factory QuestionRatingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionRatingRow(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      questionId: serializer.fromJson<int>(json['questionId']),
      difficultyScore: serializer.fromJson<int>(json['difficultyScore']),
      calculationScore: serializer.fromJson<int>(json['calculationScore']),
      eleganceScore: serializer.fromJson<int>(json['eleganceScore']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'questionId': serializer.toJson<int>(questionId),
      'difficultyScore': serializer.toJson<int>(difficultyScore),
      'calculationScore': serializer.toJson<int>(calculationScore),
      'eleganceScore': serializer.toJson<int>(eleganceScore),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  QuestionRatingRow copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    int? questionId,
    int? difficultyScore,
    int? calculationScore,
    int? eleganceScore,
    String? createdAt,
  }) => QuestionRatingRow(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    questionId: questionId ?? this.questionId,
    difficultyScore: difficultyScore ?? this.difficultyScore,
    calculationScore: calculationScore ?? this.calculationScore,
    eleganceScore: eleganceScore ?? this.eleganceScore,
    createdAt: createdAt ?? this.createdAt,
  );
  QuestionRatingRow copyWithCompanion(QuestionRatingsCompanion data) {
    return QuestionRatingRow(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      difficultyScore: data.difficultyScore.present
          ? data.difficultyScore.value
          : this.difficultyScore,
      calculationScore: data.calculationScore.present
          ? data.calculationScore.value
          : this.calculationScore,
      eleganceScore: data.eleganceScore.present
          ? data.eleganceScore.value
          : this.eleganceScore,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRatingRow(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('questionId: $questionId, ')
          ..write('difficultyScore: $difficultyScore, ')
          ..write('calculationScore: $calculationScore, ')
          ..write('eleganceScore: $eleganceScore, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    questionId,
    difficultyScore,
    calculationScore,
    eleganceScore,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionRatingRow &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.questionId == this.questionId &&
          other.difficultyScore == this.difficultyScore &&
          other.calculationScore == this.calculationScore &&
          other.eleganceScore == this.eleganceScore &&
          other.createdAt == this.createdAt);
}

class QuestionRatingsCompanion extends UpdateCompanion<QuestionRatingRow> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> questionId;
  final Value<int> difficultyScore;
  final Value<int> calculationScore;
  final Value<int> eleganceScore;
  final Value<String> createdAt;
  const QuestionRatingsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.difficultyScore = const Value.absent(),
    this.calculationScore = const Value.absent(),
    this.eleganceScore = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  QuestionRatingsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int questionId,
    required int difficultyScore,
    required int calculationScore,
    required int eleganceScore,
    required String createdAt,
  }) : questionId = Value(questionId),
       difficultyScore = Value(difficultyScore),
       calculationScore = Value(calculationScore),
       eleganceScore = Value(eleganceScore),
       createdAt = Value(createdAt);
  static Insertable<QuestionRatingRow> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? questionId,
    Expression<int>? difficultyScore,
    Expression<int>? calculationScore,
    Expression<int>? eleganceScore,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (questionId != null) 'question_id': questionId,
      if (difficultyScore != null) 'difficulty_score': difficultyScore,
      if (calculationScore != null) 'calculation_score': calculationScore,
      if (eleganceScore != null) 'elegance_score': eleganceScore,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  QuestionRatingsCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<int>? questionId,
    Value<int>? difficultyScore,
    Value<int>? calculationScore,
    Value<int>? eleganceScore,
    Value<String>? createdAt,
  }) {
    return QuestionRatingsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      questionId: questionId ?? this.questionId,
      difficultyScore: difficultyScore ?? this.difficultyScore,
      calculationScore: calculationScore ?? this.calculationScore,
      eleganceScore: eleganceScore ?? this.eleganceScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (difficultyScore.present) {
      map['difficulty_score'] = Variable<int>(difficultyScore.value);
    }
    if (calculationScore.present) {
      map['calculation_score'] = Variable<int>(calculationScore.value);
    }
    if (eleganceScore.present) {
      map['elegance_score'] = Variable<int>(eleganceScore.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRatingsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('questionId: $questionId, ')
          ..write('difficultyScore: $difficultyScore, ')
          ..write('calculationScore: $calculationScore, ')
          ..write('eleganceScore: $eleganceScore, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CustomPapersTable extends CustomPapers
    with TableInfo<$CustomPapersTable, CustomPaperRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomPapersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _filterSnapshotMeta = const VerificationMeta(
    'filterSnapshot',
  );
  @override
  late final GeneratedColumn<String> filterSnapshot = GeneratedColumn<String>(
    'filter_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPublicMeta = const VerificationMeta(
    'isPublic',
  );
  @override
  late final GeneratedColumn<int> isPublic = GeneratedColumn<int>(
    'is_public',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _viewCountMeta = const VerificationMeta(
    'viewCount',
  );
  @override
  late final GeneratedColumn<int> viewCount = GeneratedColumn<int>(
    'view_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    title,
    description,
    filterSnapshot,
    isPublic,
    viewCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_paper';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomPaperRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
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
    if (data.containsKey('filter_snapshot')) {
      context.handle(
        _filterSnapshotMeta,
        filterSnapshot.isAcceptableOrUnknown(
          data['filter_snapshot']!,
          _filterSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('is_public')) {
      context.handle(
        _isPublicMeta,
        isPublic.isAcceptableOrUnknown(data['is_public']!, _isPublicMeta),
      );
    }
    if (data.containsKey('view_count')) {
      context.handle(
        _viewCountMeta,
        viewCount.isAcceptableOrUnknown(data['view_count']!, _viewCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomPaperRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomPaperRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      filterSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_snapshot'],
      ),
      isPublic: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_public'],
      )!,
      viewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}view_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomPapersTable createAlias(String alias) {
    return $CustomPapersTable(attachedDatabase, alias);
  }
}

class CustomPaperRow extends DataClass implements Insertable<CustomPaperRow> {
  final int id;
  final int? serverId;
  final String title;
  final String? description;
  final String? filterSnapshot;
  final int isPublic;
  final int viewCount;
  final String createdAt;
  final String updatedAt;
  const CustomPaperRow({
    required this.id,
    this.serverId,
    required this.title,
    this.description,
    this.filterSnapshot,
    required this.isPublic,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || filterSnapshot != null) {
      map['filter_snapshot'] = Variable<String>(filterSnapshot);
    }
    map['is_public'] = Variable<int>(isPublic);
    map['view_count'] = Variable<int>(viewCount);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  CustomPapersCompanion toCompanion(bool nullToAbsent) {
    return CustomPapersCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      filterSnapshot: filterSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(filterSnapshot),
      isPublic: Value(isPublic),
      viewCount: Value(viewCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomPaperRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomPaperRow(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      filterSnapshot: serializer.fromJson<String?>(json['filterSnapshot']),
      isPublic: serializer.fromJson<int>(json['isPublic']),
      viewCount: serializer.fromJson<int>(json['viewCount']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'filterSnapshot': serializer.toJson<String?>(filterSnapshot),
      'isPublic': serializer.toJson<int>(isPublic),
      'viewCount': serializer.toJson<int>(viewCount),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  CustomPaperRow copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> filterSnapshot = const Value.absent(),
    int? isPublic,
    int? viewCount,
    String? createdAt,
    String? updatedAt,
  }) => CustomPaperRow(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    filterSnapshot: filterSnapshot.present
        ? filterSnapshot.value
        : this.filterSnapshot,
    isPublic: isPublic ?? this.isPublic,
    viewCount: viewCount ?? this.viewCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomPaperRow copyWithCompanion(CustomPapersCompanion data) {
    return CustomPaperRow(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      filterSnapshot: data.filterSnapshot.present
          ? data.filterSnapshot.value
          : this.filterSnapshot,
      isPublic: data.isPublic.present ? data.isPublic.value : this.isPublic,
      viewCount: data.viewCount.present ? data.viewCount.value : this.viewCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomPaperRow(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('filterSnapshot: $filterSnapshot, ')
          ..write('isPublic: $isPublic, ')
          ..write('viewCount: $viewCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    title,
    description,
    filterSnapshot,
    isPublic,
    viewCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomPaperRow &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.title == this.title &&
          other.description == this.description &&
          other.filterSnapshot == this.filterSnapshot &&
          other.isPublic == this.isPublic &&
          other.viewCount == this.viewCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomPapersCompanion extends UpdateCompanion<CustomPaperRow> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> filterSnapshot;
  final Value<int> isPublic;
  final Value<int> viewCount;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  const CustomPapersCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.filterSnapshot = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.viewCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CustomPapersCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.filterSnapshot = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.viewCount = const Value.absent(),
    required String createdAt,
    required String updatedAt,
  }) : title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CustomPaperRow> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? filterSnapshot,
    Expression<int>? isPublic,
    Expression<int>? viewCount,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (filterSnapshot != null) 'filter_snapshot': filterSnapshot,
      if (isPublic != null) 'is_public': isPublic,
      if (viewCount != null) 'view_count': viewCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CustomPapersCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? filterSnapshot,
    Value<int>? isPublic,
    Value<int>? viewCount,
    Value<String>? createdAt,
    Value<String>? updatedAt,
  }) {
    return CustomPapersCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      description: description ?? this.description,
      filterSnapshot: filterSnapshot ?? this.filterSnapshot,
      isPublic: isPublic ?? this.isPublic,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (filterSnapshot.present) {
      map['filter_snapshot'] = Variable<String>(filterSnapshot.value);
    }
    if (isPublic.present) {
      map['is_public'] = Variable<int>(isPublic.value);
    }
    if (viewCount.present) {
      map['view_count'] = Variable<int>(viewCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomPapersCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('filterSnapshot: $filterSnapshot, ')
          ..write('isPublic: $isPublic, ')
          ..write('viewCount: $viewCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CustomPaperQuestionsTable extends CustomPaperQuestions
    with TableInfo<$CustomPaperQuestionsTable, CustomPaperQuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomPaperQuestionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _paperIdMeta = const VerificationMeta(
    'paperId',
  );
  @override
  late final GeneratedColumn<int> paperId = GeneratedColumn<int>(
    'paper_id',
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
  List<GeneratedColumn> get $columns => [id, paperId, questionId, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_paper_question';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomPaperQuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('paper_id')) {
      context.handle(
        _paperIdMeta,
        paperId.isAcceptableOrUnknown(data['paper_id']!, _paperIdMeta),
      );
    } else if (isInserting) {
      context.missing(_paperIdMeta);
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
  CustomPaperQuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomPaperQuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      paperId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paper_id'],
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
  $CustomPaperQuestionsTable createAlias(String alias) {
    return $CustomPaperQuestionsTable(attachedDatabase, alias);
  }
}

class CustomPaperQuestionRow extends DataClass
    implements Insertable<CustomPaperQuestionRow> {
  final int id;
  final int paperId;
  final int questionId;
  final int sortOrder;
  const CustomPaperQuestionRow({
    required this.id,
    required this.paperId,
    required this.questionId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['paper_id'] = Variable<int>(paperId);
    map['question_id'] = Variable<int>(questionId);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CustomPaperQuestionsCompanion toCompanion(bool nullToAbsent) {
    return CustomPaperQuestionsCompanion(
      id: Value(id),
      paperId: Value(paperId),
      questionId: Value(questionId),
      sortOrder: Value(sortOrder),
    );
  }

  factory CustomPaperQuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomPaperQuestionRow(
      id: serializer.fromJson<int>(json['id']),
      paperId: serializer.fromJson<int>(json['paperId']),
      questionId: serializer.fromJson<int>(json['questionId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'paperId': serializer.toJson<int>(paperId),
      'questionId': serializer.toJson<int>(questionId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CustomPaperQuestionRow copyWith({
    int? id,
    int? paperId,
    int? questionId,
    int? sortOrder,
  }) => CustomPaperQuestionRow(
    id: id ?? this.id,
    paperId: paperId ?? this.paperId,
    questionId: questionId ?? this.questionId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CustomPaperQuestionRow copyWithCompanion(CustomPaperQuestionsCompanion data) {
    return CustomPaperQuestionRow(
      id: data.id.present ? data.id.value : this.id,
      paperId: data.paperId.present ? data.paperId.value : this.paperId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomPaperQuestionRow(')
          ..write('id: $id, ')
          ..write('paperId: $paperId, ')
          ..write('questionId: $questionId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, paperId, questionId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomPaperQuestionRow &&
          other.id == this.id &&
          other.paperId == this.paperId &&
          other.questionId == this.questionId &&
          other.sortOrder == this.sortOrder);
}

class CustomPaperQuestionsCompanion
    extends UpdateCompanion<CustomPaperQuestionRow> {
  final Value<int> id;
  final Value<int> paperId;
  final Value<int> questionId;
  final Value<int> sortOrder;
  const CustomPaperQuestionsCompanion({
    this.id = const Value.absent(),
    this.paperId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CustomPaperQuestionsCompanion.insert({
    this.id = const Value.absent(),
    required int paperId,
    required int questionId,
    required int sortOrder,
  }) : paperId = Value(paperId),
       questionId = Value(questionId),
       sortOrder = Value(sortOrder);
  static Insertable<CustomPaperQuestionRow> custom({
    Expression<int>? id,
    Expression<int>? paperId,
    Expression<int>? questionId,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (paperId != null) 'paper_id': paperId,
      if (questionId != null) 'question_id': questionId,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CustomPaperQuestionsCompanion copyWith({
    Value<int>? id,
    Value<int>? paperId,
    Value<int>? questionId,
    Value<int>? sortOrder,
  }) {
    return CustomPaperQuestionsCompanion(
      id: id ?? this.id,
      paperId: paperId ?? this.paperId,
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
    if (paperId.present) {
      map['paper_id'] = Variable<int>(paperId.value);
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
    return (StringBuffer('CustomPaperQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('paperId: $paperId, ')
          ..write('questionId: $questionId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $PaperLikesTable extends PaperLikes
    with TableInfo<$PaperLikesTable, PaperLikeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaperLikesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _paperIdMeta = const VerificationMeta(
    'paperId',
  );
  @override
  late final GeneratedColumn<int> paperId = GeneratedColumn<int>(
    'paper_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [paperId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paper_like';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaperLikeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('paper_id')) {
      context.handle(
        _paperIdMeta,
        paperId.isAcceptableOrUnknown(data['paper_id']!, _paperIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {paperId};
  @override
  PaperLikeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaperLikeRow(
      paperId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paper_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PaperLikesTable createAlias(String alias) {
    return $PaperLikesTable(attachedDatabase, alias);
  }
}

class PaperLikeRow extends DataClass implements Insertable<PaperLikeRow> {
  final int paperId;
  final String createdAt;
  const PaperLikeRow({required this.paperId, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['paper_id'] = Variable<int>(paperId);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  PaperLikesCompanion toCompanion(bool nullToAbsent) {
    return PaperLikesCompanion(
      paperId: Value(paperId),
      createdAt: Value(createdAt),
    );
  }

  factory PaperLikeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaperLikeRow(
      paperId: serializer.fromJson<int>(json['paperId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'paperId': serializer.toJson<int>(paperId),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  PaperLikeRow copyWith({int? paperId, String? createdAt}) => PaperLikeRow(
    paperId: paperId ?? this.paperId,
    createdAt: createdAt ?? this.createdAt,
  );
  PaperLikeRow copyWithCompanion(PaperLikesCompanion data) {
    return PaperLikeRow(
      paperId: data.paperId.present ? data.paperId.value : this.paperId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaperLikeRow(')
          ..write('paperId: $paperId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(paperId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaperLikeRow &&
          other.paperId == this.paperId &&
          other.createdAt == this.createdAt);
}

class PaperLikesCompanion extends UpdateCompanion<PaperLikeRow> {
  final Value<int> paperId;
  final Value<String> createdAt;
  const PaperLikesCompanion({
    this.paperId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PaperLikesCompanion.insert({
    this.paperId = const Value.absent(),
    required String createdAt,
  }) : createdAt = Value(createdAt);
  static Insertable<PaperLikeRow> custom({
    Expression<int>? paperId,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (paperId != null) 'paper_id': paperId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PaperLikesCompanion copyWith({
    Value<int>? paperId,
    Value<String>? createdAt,
  }) {
    return PaperLikesCompanion(
      paperId: paperId ?? this.paperId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (paperId.present) {
      map['paper_id'] = Variable<int>(paperId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaperLikesCompanion(')
          ..write('paperId: $paperId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PaperCollectsTable extends PaperCollects
    with TableInfo<$PaperCollectsTable, PaperCollectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaperCollectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _paperIdMeta = const VerificationMeta(
    'paperId',
  );
  @override
  late final GeneratedColumn<int> paperId = GeneratedColumn<int>(
    'paper_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [paperId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paper_collect';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaperCollectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('paper_id')) {
      context.handle(
        _paperIdMeta,
        paperId.isAcceptableOrUnknown(data['paper_id']!, _paperIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {paperId};
  @override
  PaperCollectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaperCollectRow(
      paperId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paper_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PaperCollectsTable createAlias(String alias) {
    return $PaperCollectsTable(attachedDatabase, alias);
  }
}

class PaperCollectRow extends DataClass implements Insertable<PaperCollectRow> {
  final int paperId;
  final String createdAt;
  const PaperCollectRow({required this.paperId, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['paper_id'] = Variable<int>(paperId);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  PaperCollectsCompanion toCompanion(bool nullToAbsent) {
    return PaperCollectsCompanion(
      paperId: Value(paperId),
      createdAt: Value(createdAt),
    );
  }

  factory PaperCollectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaperCollectRow(
      paperId: serializer.fromJson<int>(json['paperId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'paperId': serializer.toJson<int>(paperId),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  PaperCollectRow copyWith({int? paperId, String? createdAt}) =>
      PaperCollectRow(
        paperId: paperId ?? this.paperId,
        createdAt: createdAt ?? this.createdAt,
      );
  PaperCollectRow copyWithCompanion(PaperCollectsCompanion data) {
    return PaperCollectRow(
      paperId: data.paperId.present ? data.paperId.value : this.paperId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaperCollectRow(')
          ..write('paperId: $paperId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(paperId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaperCollectRow &&
          other.paperId == this.paperId &&
          other.createdAt == this.createdAt);
}

class PaperCollectsCompanion extends UpdateCompanion<PaperCollectRow> {
  final Value<int> paperId;
  final Value<String> createdAt;
  const PaperCollectsCompanion({
    this.paperId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PaperCollectsCompanion.insert({
    this.paperId = const Value.absent(),
    required String createdAt,
  }) : createdAt = Value(createdAt);
  static Insertable<PaperCollectRow> custom({
    Expression<int>? paperId,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (paperId != null) 'paper_id': paperId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PaperCollectsCompanion copyWith({
    Value<int>? paperId,
    Value<String>? createdAt,
  }) {
    return PaperCollectsCompanion(
      paperId: paperId ?? this.paperId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (paperId.present) {
      map['paper_id'] = Variable<int>(paperId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaperCollectsCompanion(')
          ..write('paperId: $paperId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PreferenceFiltersTable extends PreferenceFilters
    with TableInfo<$PreferenceFiltersTable, PreferenceFilterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferenceFiltersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _yearsMeta = const VerificationMeta('years');
  @override
  late final GeneratedColumn<String> years = GeneratedColumn<String>(
    'years',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionsMeta = const VerificationMeta(
    'regions',
  );
  @override
  late final GeneratedColumn<String> regions = GeneratedColumn<String>(
    'regions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conceptTagsMeta = const VerificationMeta(
    'conceptTags',
  );
  @override
  late final GeneratedColumn<String> conceptTags = GeneratedColumn<String>(
    'concept_tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typesMeta = const VerificationMeta('types');
  @override
  late final GeneratedColumn<String> types = GeneratedColumn<String>(
    'types',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _knowledgeCardsMeta = const VerificationMeta(
    'knowledgeCards',
  );
  @override
  late final GeneratedColumn<String> knowledgeCards = GeneratedColumn<String>(
    'knowledge_cards',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _questionTypesMeta = const VerificationMeta(
    'questionTypes',
  );
  @override
  late final GeneratedColumn<String> questionTypes = GeneratedColumn<String>(
    'question_types',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diffMinMeta = const VerificationMeta(
    'diffMin',
  );
  @override
  late final GeneratedColumn<double> diffMin = GeneratedColumn<double>(
    'diff_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diffMaxMeta = const VerificationMeta(
    'diffMax',
  );
  @override
  late final GeneratedColumn<double> diffMax = GeneratedColumn<double>(
    'diff_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calcMinMeta = const VerificationMeta(
    'calcMin',
  );
  @override
  late final GeneratedColumn<double> calcMin = GeneratedColumn<double>(
    'calc_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calcMaxMeta = const VerificationMeta(
    'calcMax',
  );
  @override
  late final GeneratedColumn<double> calcMax = GeneratedColumn<double>(
    'calc_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    years,
    regions,
    conceptTags,
    types,
    knowledgeCards,
    questionTypes,
    diffMin,
    diffMax,
    calcMin,
    calcMax,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preference_filter';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferenceFilterRow> instance, {
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
    if (data.containsKey('years')) {
      context.handle(
        _yearsMeta,
        years.isAcceptableOrUnknown(data['years']!, _yearsMeta),
      );
    } else if (isInserting) {
      context.missing(_yearsMeta);
    }
    if (data.containsKey('regions')) {
      context.handle(
        _regionsMeta,
        regions.isAcceptableOrUnknown(data['regions']!, _regionsMeta),
      );
    } else if (isInserting) {
      context.missing(_regionsMeta);
    }
    if (data.containsKey('concept_tags')) {
      context.handle(
        _conceptTagsMeta,
        conceptTags.isAcceptableOrUnknown(
          data['concept_tags']!,
          _conceptTagsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conceptTagsMeta);
    }
    if (data.containsKey('types')) {
      context.handle(
        _typesMeta,
        types.isAcceptableOrUnknown(data['types']!, _typesMeta),
      );
    }
    if (data.containsKey('knowledge_cards')) {
      context.handle(
        _knowledgeCardsMeta,
        knowledgeCards.isAcceptableOrUnknown(
          data['knowledge_cards']!,
          _knowledgeCardsMeta,
        ),
      );
    }
    if (data.containsKey('question_types')) {
      context.handle(
        _questionTypesMeta,
        questionTypes.isAcceptableOrUnknown(
          data['question_types']!,
          _questionTypesMeta,
        ),
      );
    }
    if (data.containsKey('diff_min')) {
      context.handle(
        _diffMinMeta,
        diffMin.isAcceptableOrUnknown(data['diff_min']!, _diffMinMeta),
      );
    }
    if (data.containsKey('diff_max')) {
      context.handle(
        _diffMaxMeta,
        diffMax.isAcceptableOrUnknown(data['diff_max']!, _diffMaxMeta),
      );
    }
    if (data.containsKey('calc_min')) {
      context.handle(
        _calcMinMeta,
        calcMin.isAcceptableOrUnknown(data['calc_min']!, _calcMinMeta),
      );
    }
    if (data.containsKey('calc_max')) {
      context.handle(
        _calcMaxMeta,
        calcMax.isAcceptableOrUnknown(data['calc_max']!, _calcMaxMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PreferenceFilterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferenceFilterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      years: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}years'],
      )!,
      regions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}regions'],
      )!,
      conceptTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concept_tags'],
      )!,
      types: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}types'],
      ),
      knowledgeCards: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}knowledge_cards'],
      ),
      questionTypes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_types'],
      ),
      diffMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}diff_min'],
      ),
      diffMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}diff_max'],
      ),
      calcMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calc_min'],
      ),
      calcMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calc_max'],
      ),
    );
  }

  @override
  $PreferenceFiltersTable createAlias(String alias) {
    return $PreferenceFiltersTable(attachedDatabase, alias);
  }
}

class PreferenceFilterRow extends DataClass
    implements Insertable<PreferenceFilterRow> {
  final int id;
  final String name;
  final String years;
  final String regions;
  final String conceptTags;
  final String? types;
  final String? knowledgeCards;
  final String? questionTypes;
  final double? diffMin;
  final double? diffMax;
  final double? calcMin;
  final double? calcMax;
  const PreferenceFilterRow({
    required this.id,
    required this.name,
    required this.years,
    required this.regions,
    required this.conceptTags,
    this.types,
    this.knowledgeCards,
    this.questionTypes,
    this.diffMin,
    this.diffMax,
    this.calcMin,
    this.calcMax,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['years'] = Variable<String>(years);
    map['regions'] = Variable<String>(regions);
    map['concept_tags'] = Variable<String>(conceptTags);
    if (!nullToAbsent || types != null) {
      map['types'] = Variable<String>(types);
    }
    if (!nullToAbsent || knowledgeCards != null) {
      map['knowledge_cards'] = Variable<String>(knowledgeCards);
    }
    if (!nullToAbsent || questionTypes != null) {
      map['question_types'] = Variable<String>(questionTypes);
    }
    if (!nullToAbsent || diffMin != null) {
      map['diff_min'] = Variable<double>(diffMin);
    }
    if (!nullToAbsent || diffMax != null) {
      map['diff_max'] = Variable<double>(diffMax);
    }
    if (!nullToAbsent || calcMin != null) {
      map['calc_min'] = Variable<double>(calcMin);
    }
    if (!nullToAbsent || calcMax != null) {
      map['calc_max'] = Variable<double>(calcMax);
    }
    return map;
  }

  PreferenceFiltersCompanion toCompanion(bool nullToAbsent) {
    return PreferenceFiltersCompanion(
      id: Value(id),
      name: Value(name),
      years: Value(years),
      regions: Value(regions),
      conceptTags: Value(conceptTags),
      types: types == null && nullToAbsent
          ? const Value.absent()
          : Value(types),
      knowledgeCards: knowledgeCards == null && nullToAbsent
          ? const Value.absent()
          : Value(knowledgeCards),
      questionTypes: questionTypes == null && nullToAbsent
          ? const Value.absent()
          : Value(questionTypes),
      diffMin: diffMin == null && nullToAbsent
          ? const Value.absent()
          : Value(diffMin),
      diffMax: diffMax == null && nullToAbsent
          ? const Value.absent()
          : Value(diffMax),
      calcMin: calcMin == null && nullToAbsent
          ? const Value.absent()
          : Value(calcMin),
      calcMax: calcMax == null && nullToAbsent
          ? const Value.absent()
          : Value(calcMax),
    );
  }

  factory PreferenceFilterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferenceFilterRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      years: serializer.fromJson<String>(json['years']),
      regions: serializer.fromJson<String>(json['regions']),
      conceptTags: serializer.fromJson<String>(json['conceptTags']),
      types: serializer.fromJson<String?>(json['types']),
      knowledgeCards: serializer.fromJson<String?>(json['knowledgeCards']),
      questionTypes: serializer.fromJson<String?>(json['questionTypes']),
      diffMin: serializer.fromJson<double?>(json['diffMin']),
      diffMax: serializer.fromJson<double?>(json['diffMax']),
      calcMin: serializer.fromJson<double?>(json['calcMin']),
      calcMax: serializer.fromJson<double?>(json['calcMax']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'years': serializer.toJson<String>(years),
      'regions': serializer.toJson<String>(regions),
      'conceptTags': serializer.toJson<String>(conceptTags),
      'types': serializer.toJson<String?>(types),
      'knowledgeCards': serializer.toJson<String?>(knowledgeCards),
      'questionTypes': serializer.toJson<String?>(questionTypes),
      'diffMin': serializer.toJson<double?>(diffMin),
      'diffMax': serializer.toJson<double?>(diffMax),
      'calcMin': serializer.toJson<double?>(calcMin),
      'calcMax': serializer.toJson<double?>(calcMax),
    };
  }

  PreferenceFilterRow copyWith({
    int? id,
    String? name,
    String? years,
    String? regions,
    String? conceptTags,
    Value<String?> types = const Value.absent(),
    Value<String?> knowledgeCards = const Value.absent(),
    Value<String?> questionTypes = const Value.absent(),
    Value<double?> diffMin = const Value.absent(),
    Value<double?> diffMax = const Value.absent(),
    Value<double?> calcMin = const Value.absent(),
    Value<double?> calcMax = const Value.absent(),
  }) => PreferenceFilterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    years: years ?? this.years,
    regions: regions ?? this.regions,
    conceptTags: conceptTags ?? this.conceptTags,
    types: types.present ? types.value : this.types,
    knowledgeCards: knowledgeCards.present
        ? knowledgeCards.value
        : this.knowledgeCards,
    questionTypes: questionTypes.present
        ? questionTypes.value
        : this.questionTypes,
    diffMin: diffMin.present ? diffMin.value : this.diffMin,
    diffMax: diffMax.present ? diffMax.value : this.diffMax,
    calcMin: calcMin.present ? calcMin.value : this.calcMin,
    calcMax: calcMax.present ? calcMax.value : this.calcMax,
  );
  PreferenceFilterRow copyWithCompanion(PreferenceFiltersCompanion data) {
    return PreferenceFilterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      years: data.years.present ? data.years.value : this.years,
      regions: data.regions.present ? data.regions.value : this.regions,
      conceptTags: data.conceptTags.present
          ? data.conceptTags.value
          : this.conceptTags,
      types: data.types.present ? data.types.value : this.types,
      knowledgeCards: data.knowledgeCards.present
          ? data.knowledgeCards.value
          : this.knowledgeCards,
      questionTypes: data.questionTypes.present
          ? data.questionTypes.value
          : this.questionTypes,
      diffMin: data.diffMin.present ? data.diffMin.value : this.diffMin,
      diffMax: data.diffMax.present ? data.diffMax.value : this.diffMax,
      calcMin: data.calcMin.present ? data.calcMin.value : this.calcMin,
      calcMax: data.calcMax.present ? data.calcMax.value : this.calcMax,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceFilterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('years: $years, ')
          ..write('regions: $regions, ')
          ..write('conceptTags: $conceptTags, ')
          ..write('types: $types, ')
          ..write('knowledgeCards: $knowledgeCards, ')
          ..write('questionTypes: $questionTypes, ')
          ..write('diffMin: $diffMin, ')
          ..write('diffMax: $diffMax, ')
          ..write('calcMin: $calcMin, ')
          ..write('calcMax: $calcMax')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    years,
    regions,
    conceptTags,
    types,
    knowledgeCards,
    questionTypes,
    diffMin,
    diffMax,
    calcMin,
    calcMax,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferenceFilterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.years == this.years &&
          other.regions == this.regions &&
          other.conceptTags == this.conceptTags &&
          other.types == this.types &&
          other.knowledgeCards == this.knowledgeCards &&
          other.questionTypes == this.questionTypes &&
          other.diffMin == this.diffMin &&
          other.diffMax == this.diffMax &&
          other.calcMin == this.calcMin &&
          other.calcMax == this.calcMax);
}

class PreferenceFiltersCompanion extends UpdateCompanion<PreferenceFilterRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> years;
  final Value<String> regions;
  final Value<String> conceptTags;
  final Value<String?> types;
  final Value<String?> knowledgeCards;
  final Value<String?> questionTypes;
  final Value<double?> diffMin;
  final Value<double?> diffMax;
  final Value<double?> calcMin;
  final Value<double?> calcMax;
  const PreferenceFiltersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.years = const Value.absent(),
    this.regions = const Value.absent(),
    this.conceptTags = const Value.absent(),
    this.types = const Value.absent(),
    this.knowledgeCards = const Value.absent(),
    this.questionTypes = const Value.absent(),
    this.diffMin = const Value.absent(),
    this.diffMax = const Value.absent(),
    this.calcMin = const Value.absent(),
    this.calcMax = const Value.absent(),
  });
  PreferenceFiltersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String years,
    required String regions,
    required String conceptTags,
    this.types = const Value.absent(),
    this.knowledgeCards = const Value.absent(),
    this.questionTypes = const Value.absent(),
    this.diffMin = const Value.absent(),
    this.diffMax = const Value.absent(),
    this.calcMin = const Value.absent(),
    this.calcMax = const Value.absent(),
  }) : name = Value(name),
       years = Value(years),
       regions = Value(regions),
       conceptTags = Value(conceptTags);
  static Insertable<PreferenceFilterRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? years,
    Expression<String>? regions,
    Expression<String>? conceptTags,
    Expression<String>? types,
    Expression<String>? knowledgeCards,
    Expression<String>? questionTypes,
    Expression<double>? diffMin,
    Expression<double>? diffMax,
    Expression<double>? calcMin,
    Expression<double>? calcMax,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (years != null) 'years': years,
      if (regions != null) 'regions': regions,
      if (conceptTags != null) 'concept_tags': conceptTags,
      if (types != null) 'types': types,
      if (knowledgeCards != null) 'knowledge_cards': knowledgeCards,
      if (questionTypes != null) 'question_types': questionTypes,
      if (diffMin != null) 'diff_min': diffMin,
      if (diffMax != null) 'diff_max': diffMax,
      if (calcMin != null) 'calc_min': calcMin,
      if (calcMax != null) 'calc_max': calcMax,
    });
  }

  PreferenceFiltersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? years,
    Value<String>? regions,
    Value<String>? conceptTags,
    Value<String?>? types,
    Value<String?>? knowledgeCards,
    Value<String?>? questionTypes,
    Value<double?>? diffMin,
    Value<double?>? diffMax,
    Value<double?>? calcMin,
    Value<double?>? calcMax,
  }) {
    return PreferenceFiltersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      years: years ?? this.years,
      regions: regions ?? this.regions,
      conceptTags: conceptTags ?? this.conceptTags,
      types: types ?? this.types,
      knowledgeCards: knowledgeCards ?? this.knowledgeCards,
      questionTypes: questionTypes ?? this.questionTypes,
      diffMin: diffMin ?? this.diffMin,
      diffMax: diffMax ?? this.diffMax,
      calcMin: calcMin ?? this.calcMin,
      calcMax: calcMax ?? this.calcMax,
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
    if (years.present) {
      map['years'] = Variable<String>(years.value);
    }
    if (regions.present) {
      map['regions'] = Variable<String>(regions.value);
    }
    if (conceptTags.present) {
      map['concept_tags'] = Variable<String>(conceptTags.value);
    }
    if (types.present) {
      map['types'] = Variable<String>(types.value);
    }
    if (knowledgeCards.present) {
      map['knowledge_cards'] = Variable<String>(knowledgeCards.value);
    }
    if (questionTypes.present) {
      map['question_types'] = Variable<String>(questionTypes.value);
    }
    if (diffMin.present) {
      map['diff_min'] = Variable<double>(diffMin.value);
    }
    if (diffMax.present) {
      map['diff_max'] = Variable<double>(diffMax.value);
    }
    if (calcMin.present) {
      map['calc_min'] = Variable<double>(calcMin.value);
    }
    if (calcMax.present) {
      map['calc_max'] = Variable<double>(calcMax.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceFiltersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('years: $years, ')
          ..write('regions: $regions, ')
          ..write('conceptTags: $conceptTags, ')
          ..write('types: $types, ')
          ..write('knowledgeCards: $knowledgeCards, ')
          ..write('questionTypes: $questionTypes, ')
          ..write('diffMin: $diffMin, ')
          ..write('diffMax: $diffMax, ')
          ..write('calcMin: $calcMin, ')
          ..write('calcMax: $calcMax')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    operationType,
    entityId,
    serverId,
    payload,
    status,
    retryCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entity_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueRow extends DataClass implements Insertable<SyncQueueRow> {
  final int id;
  final String entityType;
  final String operationType;
  final int entityId;
  final int? serverId;
  final String payload;
  final String status;
  final int retryCount;
  final String createdAt;
  final String? updatedAt;
  const SyncQueueRow({
    required this.id,
    required this.entityType,
    required this.operationType,
    required this.entityId,
    this.serverId,
    required this.payload,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['operation_type'] = Variable<String>(operationType);
    map['entity_id'] = Variable<int>(entityId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      operationType: Value(operationType),
      entityId: Value(entityId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      payload: Value(payload),
      status: Value(status),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory SyncQueueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueRow(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      operationType: serializer.fromJson<String>(json['operationType']),
      entityId: serializer.fromJson<int>(json['entityId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'operationType': serializer.toJson<String>(operationType),
      'entityId': serializer.toJson<int>(entityId),
      'serverId': serializer.toJson<int?>(serverId),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  SyncQueueRow copyWith({
    int? id,
    String? entityType,
    String? operationType,
    int? entityId,
    Value<int?> serverId = const Value.absent(),
    String? payload,
    String? status,
    int? retryCount,
    String? createdAt,
    Value<String?> updatedAt = const Value.absent(),
  }) => SyncQueueRow(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    operationType: operationType ?? this.operationType,
    entityId: entityId ?? this.entityId,
    serverId: serverId.present ? serverId.value : this.serverId,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  SyncQueueRow copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueRow(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueRow(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('operationType: $operationType, ')
          ..write('entityId: $entityId, ')
          ..write('serverId: $serverId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    operationType,
    entityId,
    serverId,
    payload,
    status,
    retryCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueRow &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.operationType == this.operationType &&
          other.entityId == this.entityId &&
          other.serverId == this.serverId &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueRow> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> operationType;
  final Value<int> entityId;
  final Value<int?> serverId;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String> createdAt;
  final Value<String?> updatedAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.operationType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String operationType,
    required int entityId,
    this.serverId = const Value.absent(),
    required String payload,
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    required String createdAt,
    this.updatedAt = const Value.absent(),
  }) : entityType = Value(entityType),
       operationType = Value(operationType),
       entityId = Value(entityId),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueRow> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? operationType,
    Expression<int>? entityId,
    Expression<int>? serverId,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (operationType != null) 'operation_type': operationType,
      if (entityId != null) 'entity_id': entityId,
      if (serverId != null) 'server_id': serverId,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<String>? operationType,
    Value<int>? entityId,
    Value<int?>? serverId,
    Value<String>? payload,
    Value<String>? status,
    Value<int>? retryCount,
    Value<String>? createdAt,
    Value<String?>? updatedAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      operationType: operationType ?? this.operationType,
      entityId: entityId ?? this.entityId,
      serverId: serverId ?? this.serverId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('operationType: $operationType, ')
          ..write('entityId: $entityId, ')
          ..write('serverId: $serverId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $UserLoginLogsTable userLoginLogs = $UserLoginLogsTable(this);
  late final $PointsTransactionsTable pointsTransactions =
      $PointsTransactionsTable(this);
  late final $StudentAchievementsTable studentAchievements =
      $StudentAchievementsTable(this);
  late final $SubmissionsTable submissions = $SubmissionsTable(this);
  late final $SubmissionDetailsTable submissionDetails =
      $SubmissionDetailsTable(this);
  late final $StepFeedbacksTable stepFeedbacks = $StepFeedbacksTable(this);
  late final $CardFeedbacksTable cardFeedbacks = $CardFeedbacksTable(this);
  late final $QuestionRatingsTable questionRatings = $QuestionRatingsTable(
    this,
  );
  late final $CustomPapersTable customPapers = $CustomPapersTable(this);
  late final $CustomPaperQuestionsTable customPaperQuestions =
      $CustomPaperQuestionsTable(this);
  late final $PaperLikesTable paperLikes = $PaperLikesTable(this);
  late final $PaperCollectsTable paperCollects = $PaperCollectsTable(this);
  late final $PreferenceFiltersTable preferenceFilters =
      $PreferenceFiltersTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userProfiles,
    userLoginLogs,
    pointsTransactions,
    studentAchievements,
    submissions,
    submissionDetails,
    stepFeedbacks,
    cardFeedbacks,
    questionRatings,
    customPapers,
    customPaperQuestions,
    paperLikes,
    paperCollects,
    preferenceFilters,
    syncQueue,
  ];
}

typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> realName,
      Value<String?> studentId,
      Value<String?> avatar,
      Value<String?> school,
      Value<String?> gaokaoYear,
      Value<int?> classGroupId,
      Value<String?> phone,
      Value<String?> updatedAt,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> realName,
      Value<String?> studentId,
      Value<String?> avatar,
      Value<String?> school,
      Value<String?> gaokaoYear,
      Value<int?> classGroupId,
      Value<String?> phone,
      Value<String?> updatedAt,
    });

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
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

  ColumnFilters<String> get realName => $composableBuilder(
    column: $table.realName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get school => $composableBuilder(
    column: $table.school,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gaokaoYear => $composableBuilder(
    column: $table.gaokaoYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get classGroupId => $composableBuilder(
    column: $table.classGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get realName => $composableBuilder(
    column: $table.realName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get school => $composableBuilder(
    column: $table.school,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gaokaoYear => $composableBuilder(
    column: $table.gaokaoYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get classGroupId => $composableBuilder(
    column: $table.classGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
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

  GeneratedColumn<String> get realName =>
      $composableBuilder(column: $table.realName, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get school =>
      $composableBuilder(column: $table.school, builder: (column) => column);

  GeneratedColumn<String> get gaokaoYear => $composableBuilder(
    column: $table.gaokaoYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get classGroupId => $composableBuilder(
    column: $table.classGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTable,
          UserProfileRow,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (
            UserProfileRow,
            BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow>,
          ),
          UserProfileRow,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> realName = const Value.absent(),
                Value<String?> studentId = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> school = const Value.absent(),
                Value<String?> gaokaoYear = const Value.absent(),
                Value<int?> classGroupId = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                name: name,
                realName: realName,
                studentId: studentId,
                avatar: avatar,
                school: school,
                gaokaoYear: gaokaoYear,
                classGroupId: classGroupId,
                phone: phone,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> realName = const Value.absent(),
                Value<String?> studentId = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> school = const Value.absent(),
                Value<String?> gaokaoYear = const Value.absent(),
                Value<int?> classGroupId = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                name: name,
                realName: realName,
                studentId: studentId,
                avatar: avatar,
                school: school,
                gaokaoYear: gaokaoYear,
                classGroupId: classGroupId,
                phone: phone,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTable,
      UserProfileRow,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (
        UserProfileRow,
        BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow>,
      ),
      UserProfileRow,
      PrefetchHooks Function()
    >;
typedef $$UserLoginLogsTableCreateCompanionBuilder =
    UserLoginLogsCompanion Function({
      Value<int> id,
      required String loginDate,
      required String createdAt,
    });
typedef $$UserLoginLogsTableUpdateCompanionBuilder =
    UserLoginLogsCompanion Function({
      Value<int> id,
      Value<String> loginDate,
      Value<String> createdAt,
    });

class $$UserLoginLogsTableFilterComposer
    extends Composer<_$AppDatabase, $UserLoginLogsTable> {
  $$UserLoginLogsTableFilterComposer({
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

  ColumnFilters<String> get loginDate => $composableBuilder(
    column: $table.loginDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserLoginLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserLoginLogsTable> {
  $$UserLoginLogsTableOrderingComposer({
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

  ColumnOrderings<String> get loginDate => $composableBuilder(
    column: $table.loginDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserLoginLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserLoginLogsTable> {
  $$UserLoginLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get loginDate =>
      $composableBuilder(column: $table.loginDate, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserLoginLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserLoginLogsTable,
          UserLoginLogRow,
          $$UserLoginLogsTableFilterComposer,
          $$UserLoginLogsTableOrderingComposer,
          $$UserLoginLogsTableAnnotationComposer,
          $$UserLoginLogsTableCreateCompanionBuilder,
          $$UserLoginLogsTableUpdateCompanionBuilder,
          (
            UserLoginLogRow,
            BaseReferences<_$AppDatabase, $UserLoginLogsTable, UserLoginLogRow>,
          ),
          UserLoginLogRow,
          PrefetchHooks Function()
        > {
  $$UserLoginLogsTableTableManager(_$AppDatabase db, $UserLoginLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserLoginLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserLoginLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserLoginLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> loginDate = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => UserLoginLogsCompanion(
                id: id,
                loginDate: loginDate,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String loginDate,
                required String createdAt,
              }) => UserLoginLogsCompanion.insert(
                id: id,
                loginDate: loginDate,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserLoginLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserLoginLogsTable,
      UserLoginLogRow,
      $$UserLoginLogsTableFilterComposer,
      $$UserLoginLogsTableOrderingComposer,
      $$UserLoginLogsTableAnnotationComposer,
      $$UserLoginLogsTableCreateCompanionBuilder,
      $$UserLoginLogsTableUpdateCompanionBuilder,
      (
        UserLoginLogRow,
        BaseReferences<_$AppDatabase, $UserLoginLogsTable, UserLoginLogRow>,
      ),
      UserLoginLogRow,
      PrefetchHooks Function()
    >;
typedef $$PointsTransactionsTableCreateCompanionBuilder =
    PointsTransactionsCompanion Function({
      Value<int> id,
      required int amount,
      required String transactionType,
      required String source,
      Value<int?> sourceObjectId,
      Value<String?> description,
      required String createdAt,
    });
typedef $$PointsTransactionsTableUpdateCompanionBuilder =
    PointsTransactionsCompanion Function({
      Value<int> id,
      Value<int> amount,
      Value<String> transactionType,
      Value<String> source,
      Value<int?> sourceObjectId,
      Value<String?> description,
      Value<String> createdAt,
    });

class $$PointsTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $PointsTransactionsTable> {
  $$PointsTransactionsTableFilterComposer({
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

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceObjectId => $composableBuilder(
    column: $table.sourceObjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PointsTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PointsTransactionsTable> {
  $$PointsTransactionsTableOrderingComposer({
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

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceObjectId => $composableBuilder(
    column: $table.sourceObjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PointsTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PointsTransactionsTable> {
  $$PointsTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get sourceObjectId => $composableBuilder(
    column: $table.sourceObjectId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PointsTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PointsTransactionsTable,
          PointsTransactionRow,
          $$PointsTransactionsTableFilterComposer,
          $$PointsTransactionsTableOrderingComposer,
          $$PointsTransactionsTableAnnotationComposer,
          $$PointsTransactionsTableCreateCompanionBuilder,
          $$PointsTransactionsTableUpdateCompanionBuilder,
          (
            PointsTransactionRow,
            BaseReferences<
              _$AppDatabase,
              $PointsTransactionsTable,
              PointsTransactionRow
            >,
          ),
          PointsTransactionRow,
          PrefetchHooks Function()
        > {
  $$PointsTransactionsTableTableManager(
    _$AppDatabase db,
    $PointsTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PointsTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PointsTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PointsTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int?> sourceObjectId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => PointsTransactionsCompanion(
                id: id,
                amount: amount,
                transactionType: transactionType,
                source: source,
                sourceObjectId: sourceObjectId,
                description: description,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int amount,
                required String transactionType,
                required String source,
                Value<int?> sourceObjectId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required String createdAt,
              }) => PointsTransactionsCompanion.insert(
                id: id,
                amount: amount,
                transactionType: transactionType,
                source: source,
                sourceObjectId: sourceObjectId,
                description: description,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PointsTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PointsTransactionsTable,
      PointsTransactionRow,
      $$PointsTransactionsTableFilterComposer,
      $$PointsTransactionsTableOrderingComposer,
      $$PointsTransactionsTableAnnotationComposer,
      $$PointsTransactionsTableCreateCompanionBuilder,
      $$PointsTransactionsTableUpdateCompanionBuilder,
      (
        PointsTransactionRow,
        BaseReferences<
          _$AppDatabase,
          $PointsTransactionsTable,
          PointsTransactionRow
        >,
      ),
      PointsTransactionRow,
      PrefetchHooks Function()
    >;
typedef $$StudentAchievementsTableCreateCompanionBuilder =
    StudentAchievementsCompanion Function({
      Value<int> id,
      required String achievementCode,
      Value<int> progress,
      Value<int> isUnlocked,
      Value<String?> unlockedAt,
      Value<String?> updatedAt,
    });
typedef $$StudentAchievementsTableUpdateCompanionBuilder =
    StudentAchievementsCompanion Function({
      Value<int> id,
      Value<String> achievementCode,
      Value<int> progress,
      Value<int> isUnlocked,
      Value<String?> unlockedAt,
      Value<String?> updatedAt,
    });

class $$StudentAchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $StudentAchievementsTable> {
  $$StudentAchievementsTableFilterComposer({
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

  ColumnFilters<String> get achievementCode => $composableBuilder(
    column: $table.achievementCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudentAchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentAchievementsTable> {
  $$StudentAchievementsTableOrderingComposer({
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

  ColumnOrderings<String> get achievementCode => $composableBuilder(
    column: $table.achievementCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudentAchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentAchievementsTable> {
  $$StudentAchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get achievementCode => $composableBuilder(
    column: $table.achievementCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StudentAchievementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudentAchievementsTable,
          StudentAchievementRow,
          $$StudentAchievementsTableFilterComposer,
          $$StudentAchievementsTableOrderingComposer,
          $$StudentAchievementsTableAnnotationComposer,
          $$StudentAchievementsTableCreateCompanionBuilder,
          $$StudentAchievementsTableUpdateCompanionBuilder,
          (
            StudentAchievementRow,
            BaseReferences<
              _$AppDatabase,
              $StudentAchievementsTable,
              StudentAchievementRow
            >,
          ),
          StudentAchievementRow,
          PrefetchHooks Function()
        > {
  $$StudentAchievementsTableTableManager(
    _$AppDatabase db,
    $StudentAchievementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentAchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentAchievementsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StudentAchievementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> achievementCode = const Value.absent(),
                Value<int> progress = const Value.absent(),
                Value<int> isUnlocked = const Value.absent(),
                Value<String?> unlockedAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => StudentAchievementsCompanion(
                id: id,
                achievementCode: achievementCode,
                progress: progress,
                isUnlocked: isUnlocked,
                unlockedAt: unlockedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String achievementCode,
                Value<int> progress = const Value.absent(),
                Value<int> isUnlocked = const Value.absent(),
                Value<String?> unlockedAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => StudentAchievementsCompanion.insert(
                id: id,
                achievementCode: achievementCode,
                progress: progress,
                isUnlocked: isUnlocked,
                unlockedAt: unlockedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudentAchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudentAchievementsTable,
      StudentAchievementRow,
      $$StudentAchievementsTableFilterComposer,
      $$StudentAchievementsTableOrderingComposer,
      $$StudentAchievementsTableAnnotationComposer,
      $$StudentAchievementsTableCreateCompanionBuilder,
      $$StudentAchievementsTableUpdateCompanionBuilder,
      (
        StudentAchievementRow,
        BaseReferences<
          _$AppDatabase,
          $StudentAchievementsTable,
          StudentAchievementRow
        >,
      ),
      StudentAchievementRow,
      PrefetchHooks Function()
    >;
typedef $$SubmissionsTableCreateCompanionBuilder =
    SubmissionsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required int studentId,
      Value<int?> assignmentId,
      required String createdAt,
      required String updatedAt,
    });
typedef $$SubmissionsTableUpdateCompanionBuilder =
    SubmissionsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int> studentId,
      Value<int?> assignmentId,
      Value<String> createdAt,
      Value<String> updatedAt,
    });

class $$SubmissionsTableFilterComposer
    extends Composer<_$AppDatabase, $SubmissionsTable> {
  $$SubmissionsTableFilterComposer({
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

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubmissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubmissionsTable> {
  $$SubmissionsTableOrderingComposer({
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

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubmissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubmissionsTable> {
  $$SubmissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<int> get assignmentId => $composableBuilder(
    column: $table.assignmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SubmissionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubmissionsTable,
          SubmissionRow,
          $$SubmissionsTableFilterComposer,
          $$SubmissionsTableOrderingComposer,
          $$SubmissionsTableAnnotationComposer,
          $$SubmissionsTableCreateCompanionBuilder,
          $$SubmissionsTableUpdateCompanionBuilder,
          (
            SubmissionRow,
            BaseReferences<_$AppDatabase, $SubmissionsTable, SubmissionRow>,
          ),
          SubmissionRow,
          PrefetchHooks Function()
        > {
  $$SubmissionsTableTableManager(_$AppDatabase db, $SubmissionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubmissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubmissionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubmissionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> studentId = const Value.absent(),
                Value<int?> assignmentId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
              }) => SubmissionsCompanion(
                id: id,
                serverId: serverId,
                studentId: studentId,
                assignmentId: assignmentId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required int studentId,
                Value<int?> assignmentId = const Value.absent(),
                required String createdAt,
                required String updatedAt,
              }) => SubmissionsCompanion.insert(
                id: id,
                serverId: serverId,
                studentId: studentId,
                assignmentId: assignmentId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubmissionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubmissionsTable,
      SubmissionRow,
      $$SubmissionsTableFilterComposer,
      $$SubmissionsTableOrderingComposer,
      $$SubmissionsTableAnnotationComposer,
      $$SubmissionsTableCreateCompanionBuilder,
      $$SubmissionsTableUpdateCompanionBuilder,
      (
        SubmissionRow,
        BaseReferences<_$AppDatabase, $SubmissionsTable, SubmissionRow>,
      ),
      SubmissionRow,
      PrefetchHooks Function()
    >;
typedef $$SubmissionDetailsTableCreateCompanionBuilder =
    SubmissionDetailsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int?> submissionId,
      required int questionId,
      Value<int> attemptNumber,
      Value<String> status,
      Value<String?> answerText,
      Value<int?> isCorrect,
      required String createdAt,
      required String updatedAt,
    });
typedef $$SubmissionDetailsTableUpdateCompanionBuilder =
    SubmissionDetailsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int?> submissionId,
      Value<int> questionId,
      Value<int> attemptNumber,
      Value<String> status,
      Value<String?> answerText,
      Value<int?> isCorrect,
      Value<String> createdAt,
      Value<String> updatedAt,
    });

class $$SubmissionDetailsTableFilterComposer
    extends Composer<_$AppDatabase, $SubmissionDetailsTable> {
  $$SubmissionDetailsTableFilterComposer({
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

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get submissionId => $composableBuilder(
    column: $table.submissionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptNumber => $composableBuilder(
    column: $table.attemptNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerText => $composableBuilder(
    column: $table.answerText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubmissionDetailsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubmissionDetailsTable> {
  $$SubmissionDetailsTableOrderingComposer({
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

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get submissionId => $composableBuilder(
    column: $table.submissionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptNumber => $composableBuilder(
    column: $table.attemptNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerText => $composableBuilder(
    column: $table.answerText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubmissionDetailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubmissionDetailsTable> {
  $$SubmissionDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get submissionId => $composableBuilder(
    column: $table.submissionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptNumber => $composableBuilder(
    column: $table.attemptNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get answerText => $composableBuilder(
    column: $table.answerText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SubmissionDetailsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubmissionDetailsTable,
          SubmissionDetailRow,
          $$SubmissionDetailsTableFilterComposer,
          $$SubmissionDetailsTableOrderingComposer,
          $$SubmissionDetailsTableAnnotationComposer,
          $$SubmissionDetailsTableCreateCompanionBuilder,
          $$SubmissionDetailsTableUpdateCompanionBuilder,
          (
            SubmissionDetailRow,
            BaseReferences<
              _$AppDatabase,
              $SubmissionDetailsTable,
              SubmissionDetailRow
            >,
          ),
          SubmissionDetailRow,
          PrefetchHooks Function()
        > {
  $$SubmissionDetailsTableTableManager(
    _$AppDatabase db,
    $SubmissionDetailsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubmissionDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubmissionDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubmissionDetailsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int?> submissionId = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<int> attemptNumber = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> answerText = const Value.absent(),
                Value<int?> isCorrect = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
              }) => SubmissionDetailsCompanion(
                id: id,
                serverId: serverId,
                submissionId: submissionId,
                questionId: questionId,
                attemptNumber: attemptNumber,
                status: status,
                answerText: answerText,
                isCorrect: isCorrect,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int?> submissionId = const Value.absent(),
                required int questionId,
                Value<int> attemptNumber = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> answerText = const Value.absent(),
                Value<int?> isCorrect = const Value.absent(),
                required String createdAt,
                required String updatedAt,
              }) => SubmissionDetailsCompanion.insert(
                id: id,
                serverId: serverId,
                submissionId: submissionId,
                questionId: questionId,
                attemptNumber: attemptNumber,
                status: status,
                answerText: answerText,
                isCorrect: isCorrect,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubmissionDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubmissionDetailsTable,
      SubmissionDetailRow,
      $$SubmissionDetailsTableFilterComposer,
      $$SubmissionDetailsTableOrderingComposer,
      $$SubmissionDetailsTableAnnotationComposer,
      $$SubmissionDetailsTableCreateCompanionBuilder,
      $$SubmissionDetailsTableUpdateCompanionBuilder,
      (
        SubmissionDetailRow,
        BaseReferences<
          _$AppDatabase,
          $SubmissionDetailsTable,
          SubmissionDetailRow
        >,
      ),
      SubmissionDetailRow,
      PrefetchHooks Function()
    >;
typedef $$StepFeedbacksTableCreateCompanionBuilder =
    StepFeedbacksCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required int submissionDetailId,
      required int questionId,
      Value<int?> subQuestionIndex,
      Value<int?> methodId,
      required int stepNumber,
      required String status,
      required String createdAt,
    });
typedef $$StepFeedbacksTableUpdateCompanionBuilder =
    StepFeedbacksCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int> submissionDetailId,
      Value<int> questionId,
      Value<int?> subQuestionIndex,
      Value<int?> methodId,
      Value<int> stepNumber,
      Value<String> status,
      Value<String> createdAt,
    });

class $$StepFeedbacksTableFilterComposer
    extends Composer<_$AppDatabase, $StepFeedbacksTable> {
  $$StepFeedbacksTableFilterComposer({
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

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get submissionDetailId => $composableBuilder(
    column: $table.submissionDetailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subQuestionIndex => $composableBuilder(
    column: $table.subQuestionIndex,
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StepFeedbacksTableOrderingComposer
    extends Composer<_$AppDatabase, $StepFeedbacksTable> {
  $$StepFeedbacksTableOrderingComposer({
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

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get submissionDetailId => $composableBuilder(
    column: $table.submissionDetailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subQuestionIndex => $composableBuilder(
    column: $table.subQuestionIndex,
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StepFeedbacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $StepFeedbacksTable> {
  $$StepFeedbacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get submissionDetailId => $composableBuilder(
    column: $table.submissionDetailId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subQuestionIndex => $composableBuilder(
    column: $table.subQuestionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get methodId =>
      $composableBuilder(column: $table.methodId, builder: (column) => column);

  GeneratedColumn<int> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StepFeedbacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StepFeedbacksTable,
          StepFeedbackRow,
          $$StepFeedbacksTableFilterComposer,
          $$StepFeedbacksTableOrderingComposer,
          $$StepFeedbacksTableAnnotationComposer,
          $$StepFeedbacksTableCreateCompanionBuilder,
          $$StepFeedbacksTableUpdateCompanionBuilder,
          (
            StepFeedbackRow,
            BaseReferences<_$AppDatabase, $StepFeedbacksTable, StepFeedbackRow>,
          ),
          StepFeedbackRow,
          PrefetchHooks Function()
        > {
  $$StepFeedbacksTableTableManager(_$AppDatabase db, $StepFeedbacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StepFeedbacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StepFeedbacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StepFeedbacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> submissionDetailId = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<int?> subQuestionIndex = const Value.absent(),
                Value<int?> methodId = const Value.absent(),
                Value<int> stepNumber = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => StepFeedbacksCompanion(
                id: id,
                serverId: serverId,
                submissionDetailId: submissionDetailId,
                questionId: questionId,
                subQuestionIndex: subQuestionIndex,
                methodId: methodId,
                stepNumber: stepNumber,
                status: status,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required int submissionDetailId,
                required int questionId,
                Value<int?> subQuestionIndex = const Value.absent(),
                Value<int?> methodId = const Value.absent(),
                required int stepNumber,
                required String status,
                required String createdAt,
              }) => StepFeedbacksCompanion.insert(
                id: id,
                serverId: serverId,
                submissionDetailId: submissionDetailId,
                questionId: questionId,
                subQuestionIndex: subQuestionIndex,
                methodId: methodId,
                stepNumber: stepNumber,
                status: status,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StepFeedbacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StepFeedbacksTable,
      StepFeedbackRow,
      $$StepFeedbacksTableFilterComposer,
      $$StepFeedbacksTableOrderingComposer,
      $$StepFeedbacksTableAnnotationComposer,
      $$StepFeedbacksTableCreateCompanionBuilder,
      $$StepFeedbacksTableUpdateCompanionBuilder,
      (
        StepFeedbackRow,
        BaseReferences<_$AppDatabase, $StepFeedbacksTable, StepFeedbackRow>,
      ),
      StepFeedbackRow,
      PrefetchHooks Function()
    >;
typedef $$CardFeedbacksTableCreateCompanionBuilder =
    CardFeedbacksCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required int submissionDetailId,
      required int questionId,
      required String cardTitle,
      required String cardStatus,
      required String createdAt,
    });
typedef $$CardFeedbacksTableUpdateCompanionBuilder =
    CardFeedbacksCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int> submissionDetailId,
      Value<int> questionId,
      Value<String> cardTitle,
      Value<String> cardStatus,
      Value<String> createdAt,
    });

class $$CardFeedbacksTableFilterComposer
    extends Composer<_$AppDatabase, $CardFeedbacksTable> {
  $$CardFeedbacksTableFilterComposer({
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

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get submissionDetailId => $composableBuilder(
    column: $table.submissionDetailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardTitle => $composableBuilder(
    column: $table.cardTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardStatus => $composableBuilder(
    column: $table.cardStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CardFeedbacksTableOrderingComposer
    extends Composer<_$AppDatabase, $CardFeedbacksTable> {
  $$CardFeedbacksTableOrderingComposer({
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

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get submissionDetailId => $composableBuilder(
    column: $table.submissionDetailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardTitle => $composableBuilder(
    column: $table.cardTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardStatus => $composableBuilder(
    column: $table.cardStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardFeedbacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardFeedbacksTable> {
  $$CardFeedbacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get submissionDetailId => $composableBuilder(
    column: $table.submissionDetailId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardTitle =>
      $composableBuilder(column: $table.cardTitle, builder: (column) => column);

  GeneratedColumn<String> get cardStatus => $composableBuilder(
    column: $table.cardStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CardFeedbacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardFeedbacksTable,
          CardFeedbackRow,
          $$CardFeedbacksTableFilterComposer,
          $$CardFeedbacksTableOrderingComposer,
          $$CardFeedbacksTableAnnotationComposer,
          $$CardFeedbacksTableCreateCompanionBuilder,
          $$CardFeedbacksTableUpdateCompanionBuilder,
          (
            CardFeedbackRow,
            BaseReferences<_$AppDatabase, $CardFeedbacksTable, CardFeedbackRow>,
          ),
          CardFeedbackRow,
          PrefetchHooks Function()
        > {
  $$CardFeedbacksTableTableManager(_$AppDatabase db, $CardFeedbacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardFeedbacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardFeedbacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardFeedbacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> submissionDetailId = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<String> cardTitle = const Value.absent(),
                Value<String> cardStatus = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => CardFeedbacksCompanion(
                id: id,
                serverId: serverId,
                submissionDetailId: submissionDetailId,
                questionId: questionId,
                cardTitle: cardTitle,
                cardStatus: cardStatus,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required int submissionDetailId,
                required int questionId,
                required String cardTitle,
                required String cardStatus,
                required String createdAt,
              }) => CardFeedbacksCompanion.insert(
                id: id,
                serverId: serverId,
                submissionDetailId: submissionDetailId,
                questionId: questionId,
                cardTitle: cardTitle,
                cardStatus: cardStatus,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CardFeedbacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardFeedbacksTable,
      CardFeedbackRow,
      $$CardFeedbacksTableFilterComposer,
      $$CardFeedbacksTableOrderingComposer,
      $$CardFeedbacksTableAnnotationComposer,
      $$CardFeedbacksTableCreateCompanionBuilder,
      $$CardFeedbacksTableUpdateCompanionBuilder,
      (
        CardFeedbackRow,
        BaseReferences<_$AppDatabase, $CardFeedbacksTable, CardFeedbackRow>,
      ),
      CardFeedbackRow,
      PrefetchHooks Function()
    >;
typedef $$QuestionRatingsTableCreateCompanionBuilder =
    QuestionRatingsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required int questionId,
      required int difficultyScore,
      required int calculationScore,
      required int eleganceScore,
      required String createdAt,
    });
typedef $$QuestionRatingsTableUpdateCompanionBuilder =
    QuestionRatingsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int> questionId,
      Value<int> difficultyScore,
      Value<int> calculationScore,
      Value<int> eleganceScore,
      Value<String> createdAt,
    });

class $$QuestionRatingsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionRatingsTable> {
  $$QuestionRatingsTableFilterComposer({
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

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficultyScore => $composableBuilder(
    column: $table.difficultyScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calculationScore => $composableBuilder(
    column: $table.calculationScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eleganceScore => $composableBuilder(
    column: $table.eleganceScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestionRatingsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionRatingsTable> {
  $$QuestionRatingsTableOrderingComposer({
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

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficultyScore => $composableBuilder(
    column: $table.difficultyScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calculationScore => $composableBuilder(
    column: $table.calculationScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eleganceScore => $composableBuilder(
    column: $table.eleganceScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestionRatingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionRatingsTable> {
  $$QuestionRatingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get difficultyScore => $composableBuilder(
    column: $table.difficultyScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get calculationScore => $composableBuilder(
    column: $table.calculationScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get eleganceScore => $composableBuilder(
    column: $table.eleganceScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$QuestionRatingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestionRatingsTable,
          QuestionRatingRow,
          $$QuestionRatingsTableFilterComposer,
          $$QuestionRatingsTableOrderingComposer,
          $$QuestionRatingsTableAnnotationComposer,
          $$QuestionRatingsTableCreateCompanionBuilder,
          $$QuestionRatingsTableUpdateCompanionBuilder,
          (
            QuestionRatingRow,
            BaseReferences<
              _$AppDatabase,
              $QuestionRatingsTable,
              QuestionRatingRow
            >,
          ),
          QuestionRatingRow,
          PrefetchHooks Function()
        > {
  $$QuestionRatingsTableTableManager(
    _$AppDatabase db,
    $QuestionRatingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionRatingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionRatingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionRatingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<int> difficultyScore = const Value.absent(),
                Value<int> calculationScore = const Value.absent(),
                Value<int> eleganceScore = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => QuestionRatingsCompanion(
                id: id,
                serverId: serverId,
                questionId: questionId,
                difficultyScore: difficultyScore,
                calculationScore: calculationScore,
                eleganceScore: eleganceScore,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required int questionId,
                required int difficultyScore,
                required int calculationScore,
                required int eleganceScore,
                required String createdAt,
              }) => QuestionRatingsCompanion.insert(
                id: id,
                serverId: serverId,
                questionId: questionId,
                difficultyScore: difficultyScore,
                calculationScore: calculationScore,
                eleganceScore: eleganceScore,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestionRatingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestionRatingsTable,
      QuestionRatingRow,
      $$QuestionRatingsTableFilterComposer,
      $$QuestionRatingsTableOrderingComposer,
      $$QuestionRatingsTableAnnotationComposer,
      $$QuestionRatingsTableCreateCompanionBuilder,
      $$QuestionRatingsTableUpdateCompanionBuilder,
      (
        QuestionRatingRow,
        BaseReferences<_$AppDatabase, $QuestionRatingsTable, QuestionRatingRow>,
      ),
      QuestionRatingRow,
      PrefetchHooks Function()
    >;
typedef $$CustomPapersTableCreateCompanionBuilder =
    CustomPapersCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required String title,
      Value<String?> description,
      Value<String?> filterSnapshot,
      Value<int> isPublic,
      Value<int> viewCount,
      required String createdAt,
      required String updatedAt,
    });
typedef $$CustomPapersTableUpdateCompanionBuilder =
    CustomPapersCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String> title,
      Value<String?> description,
      Value<String?> filterSnapshot,
      Value<int> isPublic,
      Value<int> viewCount,
      Value<String> createdAt,
      Value<String> updatedAt,
    });

class $$CustomPapersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomPapersTable> {
  $$CustomPapersTableFilterComposer({
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

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
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

  ColumnFilters<String> get filterSnapshot => $composableBuilder(
    column: $table.filterSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get viewCount => $composableBuilder(
    column: $table.viewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomPapersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomPapersTable> {
  $$CustomPapersTableOrderingComposer({
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

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
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

  ColumnOrderings<String> get filterSnapshot => $composableBuilder(
    column: $table.filterSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get viewCount => $composableBuilder(
    column: $table.viewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomPapersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomPapersTable> {
  $$CustomPapersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filterSnapshot => $composableBuilder(
    column: $table.filterSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isPublic =>
      $composableBuilder(column: $table.isPublic, builder: (column) => column);

  GeneratedColumn<int> get viewCount =>
      $composableBuilder(column: $table.viewCount, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomPapersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomPapersTable,
          CustomPaperRow,
          $$CustomPapersTableFilterComposer,
          $$CustomPapersTableOrderingComposer,
          $$CustomPapersTableAnnotationComposer,
          $$CustomPapersTableCreateCompanionBuilder,
          $$CustomPapersTableUpdateCompanionBuilder,
          (
            CustomPaperRow,
            BaseReferences<_$AppDatabase, $CustomPapersTable, CustomPaperRow>,
          ),
          CustomPaperRow,
          PrefetchHooks Function()
        > {
  $$CustomPapersTableTableManager(_$AppDatabase db, $CustomPapersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomPapersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomPapersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomPapersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> filterSnapshot = const Value.absent(),
                Value<int> isPublic = const Value.absent(),
                Value<int> viewCount = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
              }) => CustomPapersCompanion(
                id: id,
                serverId: serverId,
                title: title,
                description: description,
                filterSnapshot: filterSnapshot,
                isPublic: isPublic,
                viewCount: viewCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> filterSnapshot = const Value.absent(),
                Value<int> isPublic = const Value.absent(),
                Value<int> viewCount = const Value.absent(),
                required String createdAt,
                required String updatedAt,
              }) => CustomPapersCompanion.insert(
                id: id,
                serverId: serverId,
                title: title,
                description: description,
                filterSnapshot: filterSnapshot,
                isPublic: isPublic,
                viewCount: viewCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomPapersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomPapersTable,
      CustomPaperRow,
      $$CustomPapersTableFilterComposer,
      $$CustomPapersTableOrderingComposer,
      $$CustomPapersTableAnnotationComposer,
      $$CustomPapersTableCreateCompanionBuilder,
      $$CustomPapersTableUpdateCompanionBuilder,
      (
        CustomPaperRow,
        BaseReferences<_$AppDatabase, $CustomPapersTable, CustomPaperRow>,
      ),
      CustomPaperRow,
      PrefetchHooks Function()
    >;
typedef $$CustomPaperQuestionsTableCreateCompanionBuilder =
    CustomPaperQuestionsCompanion Function({
      Value<int> id,
      required int paperId,
      required int questionId,
      required int sortOrder,
    });
typedef $$CustomPaperQuestionsTableUpdateCompanionBuilder =
    CustomPaperQuestionsCompanion Function({
      Value<int> id,
      Value<int> paperId,
      Value<int> questionId,
      Value<int> sortOrder,
    });

class $$CustomPaperQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomPaperQuestionsTable> {
  $$CustomPaperQuestionsTableFilterComposer({
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

  ColumnFilters<int> get paperId => $composableBuilder(
    column: $table.paperId,
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

class $$CustomPaperQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomPaperQuestionsTable> {
  $$CustomPaperQuestionsTableOrderingComposer({
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

  ColumnOrderings<int> get paperId => $composableBuilder(
    column: $table.paperId,
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

class $$CustomPaperQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomPaperQuestionsTable> {
  $$CustomPaperQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get paperId =>
      $composableBuilder(column: $table.paperId, builder: (column) => column);

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CustomPaperQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomPaperQuestionsTable,
          CustomPaperQuestionRow,
          $$CustomPaperQuestionsTableFilterComposer,
          $$CustomPaperQuestionsTableOrderingComposer,
          $$CustomPaperQuestionsTableAnnotationComposer,
          $$CustomPaperQuestionsTableCreateCompanionBuilder,
          $$CustomPaperQuestionsTableUpdateCompanionBuilder,
          (
            CustomPaperQuestionRow,
            BaseReferences<
              _$AppDatabase,
              $CustomPaperQuestionsTable,
              CustomPaperQuestionRow
            >,
          ),
          CustomPaperQuestionRow,
          PrefetchHooks Function()
        > {
  $$CustomPaperQuestionsTableTableManager(
    _$AppDatabase db,
    $CustomPaperQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomPaperQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomPaperQuestionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomPaperQuestionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> paperId = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CustomPaperQuestionsCompanion(
                id: id,
                paperId: paperId,
                questionId: questionId,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int paperId,
                required int questionId,
                required int sortOrder,
              }) => CustomPaperQuestionsCompanion.insert(
                id: id,
                paperId: paperId,
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

typedef $$CustomPaperQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomPaperQuestionsTable,
      CustomPaperQuestionRow,
      $$CustomPaperQuestionsTableFilterComposer,
      $$CustomPaperQuestionsTableOrderingComposer,
      $$CustomPaperQuestionsTableAnnotationComposer,
      $$CustomPaperQuestionsTableCreateCompanionBuilder,
      $$CustomPaperQuestionsTableUpdateCompanionBuilder,
      (
        CustomPaperQuestionRow,
        BaseReferences<
          _$AppDatabase,
          $CustomPaperQuestionsTable,
          CustomPaperQuestionRow
        >,
      ),
      CustomPaperQuestionRow,
      PrefetchHooks Function()
    >;
typedef $$PaperLikesTableCreateCompanionBuilder =
    PaperLikesCompanion Function({
      Value<int> paperId,
      required String createdAt,
    });
typedef $$PaperLikesTableUpdateCompanionBuilder =
    PaperLikesCompanion Function({Value<int> paperId, Value<String> createdAt});

class $$PaperLikesTableFilterComposer
    extends Composer<_$AppDatabase, $PaperLikesTable> {
  $$PaperLikesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get paperId => $composableBuilder(
    column: $table.paperId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaperLikesTableOrderingComposer
    extends Composer<_$AppDatabase, $PaperLikesTable> {
  $$PaperLikesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get paperId => $composableBuilder(
    column: $table.paperId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaperLikesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaperLikesTable> {
  $$PaperLikesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get paperId =>
      $composableBuilder(column: $table.paperId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PaperLikesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaperLikesTable,
          PaperLikeRow,
          $$PaperLikesTableFilterComposer,
          $$PaperLikesTableOrderingComposer,
          $$PaperLikesTableAnnotationComposer,
          $$PaperLikesTableCreateCompanionBuilder,
          $$PaperLikesTableUpdateCompanionBuilder,
          (
            PaperLikeRow,
            BaseReferences<_$AppDatabase, $PaperLikesTable, PaperLikeRow>,
          ),
          PaperLikeRow,
          PrefetchHooks Function()
        > {
  $$PaperLikesTableTableManager(_$AppDatabase db, $PaperLikesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaperLikesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaperLikesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaperLikesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> paperId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => PaperLikesCompanion(paperId: paperId, createdAt: createdAt),
          createCompanionCallback:
              ({
                Value<int> paperId = const Value.absent(),
                required String createdAt,
              }) => PaperLikesCompanion.insert(
                paperId: paperId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaperLikesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaperLikesTable,
      PaperLikeRow,
      $$PaperLikesTableFilterComposer,
      $$PaperLikesTableOrderingComposer,
      $$PaperLikesTableAnnotationComposer,
      $$PaperLikesTableCreateCompanionBuilder,
      $$PaperLikesTableUpdateCompanionBuilder,
      (
        PaperLikeRow,
        BaseReferences<_$AppDatabase, $PaperLikesTable, PaperLikeRow>,
      ),
      PaperLikeRow,
      PrefetchHooks Function()
    >;
typedef $$PaperCollectsTableCreateCompanionBuilder =
    PaperCollectsCompanion Function({
      Value<int> paperId,
      required String createdAt,
    });
typedef $$PaperCollectsTableUpdateCompanionBuilder =
    PaperCollectsCompanion Function({
      Value<int> paperId,
      Value<String> createdAt,
    });

class $$PaperCollectsTableFilterComposer
    extends Composer<_$AppDatabase, $PaperCollectsTable> {
  $$PaperCollectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get paperId => $composableBuilder(
    column: $table.paperId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaperCollectsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaperCollectsTable> {
  $$PaperCollectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get paperId => $composableBuilder(
    column: $table.paperId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaperCollectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaperCollectsTable> {
  $$PaperCollectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get paperId =>
      $composableBuilder(column: $table.paperId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PaperCollectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaperCollectsTable,
          PaperCollectRow,
          $$PaperCollectsTableFilterComposer,
          $$PaperCollectsTableOrderingComposer,
          $$PaperCollectsTableAnnotationComposer,
          $$PaperCollectsTableCreateCompanionBuilder,
          $$PaperCollectsTableUpdateCompanionBuilder,
          (
            PaperCollectRow,
            BaseReferences<_$AppDatabase, $PaperCollectsTable, PaperCollectRow>,
          ),
          PaperCollectRow,
          PrefetchHooks Function()
        > {
  $$PaperCollectsTableTableManager(_$AppDatabase db, $PaperCollectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaperCollectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaperCollectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaperCollectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> paperId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => PaperCollectsCompanion(
                paperId: paperId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> paperId = const Value.absent(),
                required String createdAt,
              }) => PaperCollectsCompanion.insert(
                paperId: paperId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaperCollectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaperCollectsTable,
      PaperCollectRow,
      $$PaperCollectsTableFilterComposer,
      $$PaperCollectsTableOrderingComposer,
      $$PaperCollectsTableAnnotationComposer,
      $$PaperCollectsTableCreateCompanionBuilder,
      $$PaperCollectsTableUpdateCompanionBuilder,
      (
        PaperCollectRow,
        BaseReferences<_$AppDatabase, $PaperCollectsTable, PaperCollectRow>,
      ),
      PaperCollectRow,
      PrefetchHooks Function()
    >;
typedef $$PreferenceFiltersTableCreateCompanionBuilder =
    PreferenceFiltersCompanion Function({
      Value<int> id,
      required String name,
      required String years,
      required String regions,
      required String conceptTags,
      Value<String?> types,
      Value<String?> knowledgeCards,
      Value<String?> questionTypes,
      Value<double?> diffMin,
      Value<double?> diffMax,
      Value<double?> calcMin,
      Value<double?> calcMax,
    });
typedef $$PreferenceFiltersTableUpdateCompanionBuilder =
    PreferenceFiltersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> years,
      Value<String> regions,
      Value<String> conceptTags,
      Value<String?> types,
      Value<String?> knowledgeCards,
      Value<String?> questionTypes,
      Value<double?> diffMin,
      Value<double?> diffMax,
      Value<double?> calcMin,
      Value<double?> calcMax,
    });

class $$PreferenceFiltersTableFilterComposer
    extends Composer<_$AppDatabase, $PreferenceFiltersTable> {
  $$PreferenceFiltersTableFilterComposer({
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

  ColumnFilters<String> get years => $composableBuilder(
    column: $table.years,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regions => $composableBuilder(
    column: $table.regions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conceptTags => $composableBuilder(
    column: $table.conceptTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get types => $composableBuilder(
    column: $table.types,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get knowledgeCards => $composableBuilder(
    column: $table.knowledgeCards,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionTypes => $composableBuilder(
    column: $table.questionTypes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get diffMin => $composableBuilder(
    column: $table.diffMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get diffMax => $composableBuilder(
    column: $table.diffMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calcMin => $composableBuilder(
    column: $table.calcMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calcMax => $composableBuilder(
    column: $table.calcMax,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferenceFiltersTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferenceFiltersTable> {
  $$PreferenceFiltersTableOrderingComposer({
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

  ColumnOrderings<String> get years => $composableBuilder(
    column: $table.years,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regions => $composableBuilder(
    column: $table.regions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conceptTags => $composableBuilder(
    column: $table.conceptTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get types => $composableBuilder(
    column: $table.types,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get knowledgeCards => $composableBuilder(
    column: $table.knowledgeCards,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionTypes => $composableBuilder(
    column: $table.questionTypes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get diffMin => $composableBuilder(
    column: $table.diffMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get diffMax => $composableBuilder(
    column: $table.diffMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calcMin => $composableBuilder(
    column: $table.calcMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calcMax => $composableBuilder(
    column: $table.calcMax,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferenceFiltersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferenceFiltersTable> {
  $$PreferenceFiltersTableAnnotationComposer({
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

  GeneratedColumn<String> get years =>
      $composableBuilder(column: $table.years, builder: (column) => column);

  GeneratedColumn<String> get regions =>
      $composableBuilder(column: $table.regions, builder: (column) => column);

  GeneratedColumn<String> get conceptTags => $composableBuilder(
    column: $table.conceptTags,
    builder: (column) => column,
  );

  GeneratedColumn<String> get types =>
      $composableBuilder(column: $table.types, builder: (column) => column);

  GeneratedColumn<String> get knowledgeCards => $composableBuilder(
    column: $table.knowledgeCards,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionTypes => $composableBuilder(
    column: $table.questionTypes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get diffMin =>
      $composableBuilder(column: $table.diffMin, builder: (column) => column);

  GeneratedColumn<double> get diffMax =>
      $composableBuilder(column: $table.diffMax, builder: (column) => column);

  GeneratedColumn<double> get calcMin =>
      $composableBuilder(column: $table.calcMin, builder: (column) => column);

  GeneratedColumn<double> get calcMax =>
      $composableBuilder(column: $table.calcMax, builder: (column) => column);
}

class $$PreferenceFiltersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferenceFiltersTable,
          PreferenceFilterRow,
          $$PreferenceFiltersTableFilterComposer,
          $$PreferenceFiltersTableOrderingComposer,
          $$PreferenceFiltersTableAnnotationComposer,
          $$PreferenceFiltersTableCreateCompanionBuilder,
          $$PreferenceFiltersTableUpdateCompanionBuilder,
          (
            PreferenceFilterRow,
            BaseReferences<
              _$AppDatabase,
              $PreferenceFiltersTable,
              PreferenceFilterRow
            >,
          ),
          PreferenceFilterRow,
          PrefetchHooks Function()
        > {
  $$PreferenceFiltersTableTableManager(
    _$AppDatabase db,
    $PreferenceFiltersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferenceFiltersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferenceFiltersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferenceFiltersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> years = const Value.absent(),
                Value<String> regions = const Value.absent(),
                Value<String> conceptTags = const Value.absent(),
                Value<String?> types = const Value.absent(),
                Value<String?> knowledgeCards = const Value.absent(),
                Value<String?> questionTypes = const Value.absent(),
                Value<double?> diffMin = const Value.absent(),
                Value<double?> diffMax = const Value.absent(),
                Value<double?> calcMin = const Value.absent(),
                Value<double?> calcMax = const Value.absent(),
              }) => PreferenceFiltersCompanion(
                id: id,
                name: name,
                years: years,
                regions: regions,
                conceptTags: conceptTags,
                types: types,
                knowledgeCards: knowledgeCards,
                questionTypes: questionTypes,
                diffMin: diffMin,
                diffMax: diffMax,
                calcMin: calcMin,
                calcMax: calcMax,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String years,
                required String regions,
                required String conceptTags,
                Value<String?> types = const Value.absent(),
                Value<String?> knowledgeCards = const Value.absent(),
                Value<String?> questionTypes = const Value.absent(),
                Value<double?> diffMin = const Value.absent(),
                Value<double?> diffMax = const Value.absent(),
                Value<double?> calcMin = const Value.absent(),
                Value<double?> calcMax = const Value.absent(),
              }) => PreferenceFiltersCompanion.insert(
                id: id,
                name: name,
                years: years,
                regions: regions,
                conceptTags: conceptTags,
                types: types,
                knowledgeCards: knowledgeCards,
                questionTypes: questionTypes,
                diffMin: diffMin,
                diffMax: diffMax,
                calcMin: calcMin,
                calcMax: calcMax,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferenceFiltersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferenceFiltersTable,
      PreferenceFilterRow,
      $$PreferenceFiltersTableFilterComposer,
      $$PreferenceFiltersTableOrderingComposer,
      $$PreferenceFiltersTableAnnotationComposer,
      $$PreferenceFiltersTableCreateCompanionBuilder,
      $$PreferenceFiltersTableUpdateCompanionBuilder,
      (
        PreferenceFilterRow,
        BaseReferences<
          _$AppDatabase,
          $PreferenceFiltersTable,
          PreferenceFilterRow
        >,
      ),
      PreferenceFilterRow,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String entityType,
      required String operationType,
      required int entityId,
      Value<int?> serverId,
      required String payload,
      Value<String> status,
      Value<int> retryCount,
      required String createdAt,
      Value<String?> updatedAt,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<String> operationType,
      Value<int> entityId,
      Value<int?> serverId,
      Value<String> payload,
      Value<String> status,
      Value<int> retryCount,
      Value<String> createdAt,
      Value<String?> updatedAt,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
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

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
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

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueRow,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueRow,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueRow>,
          ),
          SyncQueueRow,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<int> entityId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entityType: entityType,
                operationType: operationType,
                entityId: entityId,
                serverId: serverId,
                payload: payload,
                status: status,
                retryCount: retryCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required String operationType,
                required int entityId,
                Value<int?> serverId = const Value.absent(),
                required String payload,
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                required String createdAt,
                Value<String?> updatedAt = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                entityType: entityType,
                operationType: operationType,
                entityId: entityId,
                serverId: serverId,
                payload: payload,
                status: status,
                retryCount: retryCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueRow,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueRow,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueRow>,
      ),
      SyncQueueRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$UserLoginLogsTableTableManager get userLoginLogs =>
      $$UserLoginLogsTableTableManager(_db, _db.userLoginLogs);
  $$PointsTransactionsTableTableManager get pointsTransactions =>
      $$PointsTransactionsTableTableManager(_db, _db.pointsTransactions);
  $$StudentAchievementsTableTableManager get studentAchievements =>
      $$StudentAchievementsTableTableManager(_db, _db.studentAchievements);
  $$SubmissionsTableTableManager get submissions =>
      $$SubmissionsTableTableManager(_db, _db.submissions);
  $$SubmissionDetailsTableTableManager get submissionDetails =>
      $$SubmissionDetailsTableTableManager(_db, _db.submissionDetails);
  $$StepFeedbacksTableTableManager get stepFeedbacks =>
      $$StepFeedbacksTableTableManager(_db, _db.stepFeedbacks);
  $$CardFeedbacksTableTableManager get cardFeedbacks =>
      $$CardFeedbacksTableTableManager(_db, _db.cardFeedbacks);
  $$QuestionRatingsTableTableManager get questionRatings =>
      $$QuestionRatingsTableTableManager(_db, _db.questionRatings);
  $$CustomPapersTableTableManager get customPapers =>
      $$CustomPapersTableTableManager(_db, _db.customPapers);
  $$CustomPaperQuestionsTableTableManager get customPaperQuestions =>
      $$CustomPaperQuestionsTableTableManager(_db, _db.customPaperQuestions);
  $$PaperLikesTableTableManager get paperLikes =>
      $$PaperLikesTableTableManager(_db, _db.paperLikes);
  $$PaperCollectsTableTableManager get paperCollects =>
      $$PaperCollectsTableTableManager(_db, _db.paperCollects);
  $$PreferenceFiltersTableTableManager get preferenceFilters =>
      $$PreferenceFiltersTableTableManager(_db, _db.preferenceFilters);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
