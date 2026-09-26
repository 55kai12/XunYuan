// GENERATED CODE - DO NOT MODIFY BY HAND



part of 'database.dart';

// ignore_for_file: type=lint
class $FamilyTreesTable extends FamilyTrees
    with TableInfo<$FamilyTreesTable, FamilyTree> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyTreesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _surnameMeta =
      const VerificationMeta('surname');
  @override
  late final GeneratedColumn<String> surname = GeneratedColumn<String>(
      'surname', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _hallNameMeta =
      const VerificationMeta('hallName');
  @override
  late final GeneratedColumn<String> hallName = GeneratedColumn<String>(
      'hall_name', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
      'origin', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _generationWordsMeta =
      const VerificationMeta('generationWords');
  @override
  late final GeneratedColumn<String> generationWords = GeneratedColumn<String>(
      'generation_words', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 5000),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _coverMediaIdMeta =
      const VerificationMeta('coverMediaId');
  @override
  late final GeneratedColumn<int> coverMediaId = GeneratedColumn<int>(
      'cover_media_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        surname,
        hallName,
        origin,
        generationWords,
        description,
        coverMediaId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_trees';
  @override
  VerificationContext validateIntegrity(Insertable<FamilyTree> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('surname')) {
      context.handle(_surnameMeta,
          surname.isAcceptableOrUnknown(data['surname']!, _surnameMeta));
    } else if (isInserting) {
      context.missing(_surnameMeta);
    }
    if (data.containsKey('hall_name')) {
      context.handle(_hallNameMeta,
          hallName.isAcceptableOrUnknown(data['hall_name']!, _hallNameMeta));
    }
    if (data.containsKey('origin')) {
      context.handle(_originMeta,
          origin.isAcceptableOrUnknown(data['origin']!, _originMeta));
    }
    if (data.containsKey('generation_words')) {
      context.handle(
          _generationWordsMeta,
          generationWords.isAcceptableOrUnknown(
              data['generation_words']!, _generationWordsMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('cover_media_id')) {
      context.handle(
          _coverMediaIdMeta,
          coverMediaId.isAcceptableOrUnknown(
              data['cover_media_id']!, _coverMediaIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyTree map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyTree(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      surname: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}surname'])!,
      hallName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hall_name']),
      origin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}origin']),
      generationWords: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}generation_words']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      coverMediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cover_media_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FamilyTreesTable createAlias(String alias) {
    return $FamilyTreesTable(attachedDatabase, alias);
  }
}

class FamilyTree extends DataClass implements Insertable<FamilyTree> {
  final int id;

  /// 家族名称
  final String name;

  /// 姓氏
  final String surname;

  /// 堂号
  final String? hallName;

  /// 郡望
  final String? origin;

  /// 字辈（多个字辈用顿号或空格分隔）
  final String? generationWords;

  /// 家族简介
  final String? description;

  /// 封面媒体 ID（仅存储 ID，避免与外键循环引用）
  final int? coverMediaId;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;
  const FamilyTree(
      {required this.id,
      required this.name,
      required this.surname,
      this.hallName,
      this.origin,
      this.generationWords,
      this.description,
      this.coverMediaId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['surname'] = Variable<String>(surname);
    if (!nullToAbsent || hallName != null) {
      map['hall_name'] = Variable<String>(hallName);
    }
    if (!nullToAbsent || origin != null) {
      map['origin'] = Variable<String>(origin);
    }
    if (!nullToAbsent || generationWords != null) {
      map['generation_words'] = Variable<String>(generationWords);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || coverMediaId != null) {
      map['cover_media_id'] = Variable<int>(coverMediaId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FamilyTreesCompanion toCompanion(bool nullToAbsent) {
    return FamilyTreesCompanion(
      id: Value(id),
      name: Value(name),
      surname: Value(surname),
      hallName: hallName == null && nullToAbsent
          ? const Value.absent()
          : Value(hallName),
      origin:
          origin == null && nullToAbsent ? const Value.absent() : Value(origin),
      generationWords: generationWords == null && nullToAbsent
          ? const Value.absent()
          : Value(generationWords),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      coverMediaId: coverMediaId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverMediaId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FamilyTree.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyTree(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      surname: serializer.fromJson<String>(json['surname']),
      hallName: serializer.fromJson<String?>(json['hallName']),
      origin: serializer.fromJson<String?>(json['origin']),
      generationWords: serializer.fromJson<String?>(json['generationWords']),
      description: serializer.fromJson<String?>(json['description']),
      coverMediaId: serializer.fromJson<int?>(json['coverMediaId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'surname': serializer.toJson<String>(surname),
      'hallName': serializer.toJson<String?>(hallName),
      'origin': serializer.toJson<String?>(origin),
      'generationWords': serializer.toJson<String?>(generationWords),
      'description': serializer.toJson<String?>(description),
      'coverMediaId': serializer.toJson<int?>(coverMediaId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FamilyTree copyWith(
          {int? id,
          String? name,
          String? surname,
          Value<String?> hallName = const Value.absent(),
          Value<String?> origin = const Value.absent(),
          Value<String?> generationWords = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<int?> coverMediaId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      FamilyTree(
        id: id ?? this.id,
        name: name ?? this.name,
        surname: surname ?? this.surname,
        hallName: hallName.present ? hallName.value : this.hallName,
        origin: origin.present ? origin.value : this.origin,
        generationWords: generationWords.present
            ? generationWords.value
            : this.generationWords,
        description: description.present ? description.value : this.description,
        coverMediaId:
            coverMediaId.present ? coverMediaId.value : this.coverMediaId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FamilyTree copyWithCompanion(FamilyTreesCompanion data) {
    return FamilyTree(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      surname: data.surname.present ? data.surname.value : this.surname,
      hallName: data.hallName.present ? data.hallName.value : this.hallName,
      origin: data.origin.present ? data.origin.value : this.origin,
      generationWords: data.generationWords.present
          ? data.generationWords.value
          : this.generationWords,
      description:
          data.description.present ? data.description.value : this.description,
      coverMediaId: data.coverMediaId.present
          ? data.coverMediaId.value
          : this.coverMediaId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyTree(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('surname: $surname, ')
          ..write('hallName: $hallName, ')
          ..write('origin: $origin, ')
          ..write('generationWords: $generationWords, ')
          ..write('description: $description, ')
          ..write('coverMediaId: $coverMediaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, surname, hallName, origin,
      generationWords, description, coverMediaId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyTree &&
          other.id == this.id &&
          other.name == this.name &&
          other.surname == this.surname &&
          other.hallName == this.hallName &&
          other.origin == this.origin &&
          other.generationWords == this.generationWords &&
          other.description == this.description &&
          other.coverMediaId == this.coverMediaId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FamilyTreesCompanion extends UpdateCompanion<FamilyTree> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> surname;
  final Value<String?> hallName;
  final Value<String?> origin;
  final Value<String?> generationWords;
  final Value<String?> description;
  final Value<int?> coverMediaId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FamilyTreesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.surname = const Value.absent(),
    this.hallName = const Value.absent(),
    this.origin = const Value.absent(),
    this.generationWords = const Value.absent(),
    this.description = const Value.absent(),
    this.coverMediaId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FamilyTreesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String surname,
    this.hallName = const Value.absent(),
    this.origin = const Value.absent(),
    this.generationWords = const Value.absent(),
    this.description = const Value.absent(),
    this.coverMediaId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : name = Value(name),
        surname = Value(surname),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<FamilyTree> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? surname,
    Expression<String>? hallName,
    Expression<String>? origin,
    Expression<String>? generationWords,
    Expression<String>? description,
    Expression<int>? coverMediaId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (surname != null) 'surname': surname,
      if (hallName != null) 'hall_name': hallName,
      if (origin != null) 'origin': origin,
      if (generationWords != null) 'generation_words': generationWords,
      if (description != null) 'description': description,
      if (coverMediaId != null) 'cover_media_id': coverMediaId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FamilyTreesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? surname,
      Value<String?>? hallName,
      Value<String?>? origin,
      Value<String?>? generationWords,
      Value<String?>? description,
      Value<int?>? coverMediaId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return FamilyTreesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      hallName: hallName ?? this.hallName,
      origin: origin ?? this.origin,
      generationWords: generationWords ?? this.generationWords,
      description: description ?? this.description,
      coverMediaId: coverMediaId ?? this.coverMediaId,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (surname.present) {
      map['surname'] = Variable<String>(surname.value);
    }
    if (hallName.present) {
      map['hall_name'] = Variable<String>(hallName.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (generationWords.present) {
      map['generation_words'] = Variable<String>(generationWords.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverMediaId.present) {
      map['cover_media_id'] = Variable<int>(coverMediaId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyTreesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('surname: $surname, ')
          ..write('hallName: $hallName, ')
          ..write('origin: $origin, ')
          ..write('generationWords: $generationWords, ')
          ..write('description: $description, ')
          ..write('coverMediaId: $coverMediaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MediaTableTable extends MediaTable
    with TableInfo<$MediaTableTable, MediaTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _treeIdMeta = const VerificationMeta('treeId');
  @override
  late final GeneratedColumn<int> treeId = GeneratedColumn<int>(
      'tree_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _personIdMeta =
      const VerificationMeta('personId');
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
      'person_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumnWithTypeConverter<MediaKind, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MediaKind>($MediaTableTable.$convertertype);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 1, maxTextLength: 1000),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _captionMeta =
      const VerificationMeta('caption');
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
      'caption', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, treeId, personId, type, path, caption, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media';
  @override
  VerificationContext validateIntegrity(Insertable<MediaTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tree_id')) {
      context.handle(_treeIdMeta,
          treeId.isAcceptableOrUnknown(data['tree_id']!, _treeIdMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(_personIdMeta,
          personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta));
    }
    context.handle(_typeMeta, const VerificationResult.success());
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(_captionMeta,
          caption.isAcceptableOrUnknown(data['caption']!, _captionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      treeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tree_id']),
      personId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}person_id']),
      type: $MediaTableTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      caption: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}caption']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MediaTableTable createAlias(String alias) {
    return $MediaTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaKind, String, String> $convertertype =
      const EnumNameConverter<MediaKind>(MediaKind.values);
}

class MediaTableData extends DataClass implements Insertable<MediaTableData> {
  final int id;

  /// 所属家族（仅存储 ID，避免与外键循环引用）
  final int? treeId;

  /// 关联成员（可空，仅存储 ID 避免与外键循环）
  final int? personId;

  /// 媒体类型
  final MediaKind type;

  /// 本地文件路径
  final String path;

  /// 说明文字
  final String? caption;

  /// 创建时间
  final DateTime createdAt;
  const MediaTableData(
      {required this.id,
      this.treeId,
      this.personId,
      required this.type,
      required this.path,
      this.caption,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || treeId != null) {
      map['tree_id'] = Variable<int>(treeId);
    }
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    {
      map['type'] =
          Variable<String>($MediaTableTable.$convertertype.toSql(type));
    }
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MediaTableCompanion toCompanion(bool nullToAbsent) {
    return MediaTableCompanion(
      id: Value(id),
      treeId:
          treeId == null && nullToAbsent ? const Value.absent() : Value(treeId),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      type: Value(type),
      path: Value(path),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      createdAt: Value(createdAt),
    );
  }

  factory MediaTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaTableData(
      id: serializer.fromJson<int>(json['id']),
      treeId: serializer.fromJson<int?>(json['treeId']),
      personId: serializer.fromJson<int?>(json['personId']),
      type: $MediaTableTable.$convertertype
          .fromJson(serializer.fromJson<String>(json['type'])),
      path: serializer.fromJson<String>(json['path']),
      caption: serializer.fromJson<String?>(json['caption']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'treeId': serializer.toJson<int?>(treeId),
      'personId': serializer.toJson<int?>(personId),
      'type': serializer
          .toJson<String>($MediaTableTable.$convertertype.toJson(type)),
      'path': serializer.toJson<String>(path),
      'caption': serializer.toJson<String?>(caption),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MediaTableData copyWith(
          {int? id,
          Value<int?> treeId = const Value.absent(),
          Value<int?> personId = const Value.absent(),
          MediaKind? type,
          String? path,
          Value<String?> caption = const Value.absent(),
          DateTime? createdAt}) =>
      MediaTableData(
        id: id ?? this.id,
        treeId: treeId.present ? treeId.value : this.treeId,
        personId: personId.present ? personId.value : this.personId,
        type: type ?? this.type,
        path: path ?? this.path,
        caption: caption.present ? caption.value : this.caption,
        createdAt: createdAt ?? this.createdAt,
      );
  MediaTableData copyWithCompanion(MediaTableCompanion data) {
    return MediaTableData(
      id: data.id.present ? data.id.value : this.id,
      treeId: data.treeId.present ? data.treeId.value : this.treeId,
      personId: data.personId.present ? data.personId.value : this.personId,
      type: data.type.present ? data.type.value : this.type,
      path: data.path.present ? data.path.value : this.path,
      caption: data.caption.present ? data.caption.value : this.caption,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaTableData(')
          ..write('id: $id, ')
          ..write('treeId: $treeId, ')
          ..write('personId: $personId, ')
          ..write('type: $type, ')
          ..write('path: $path, ')
          ..write('caption: $caption, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, treeId, personId, type, path, caption, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaTableData &&
          other.id == this.id &&
          other.treeId == this.treeId &&
          other.personId == this.personId &&
          other.type == this.type &&
          other.path == this.path &&
          other.caption == this.caption &&
          other.createdAt == this.createdAt);
}

class MediaTableCompanion extends UpdateCompanion<MediaTableData> {
  final Value<int> id;
  final Value<int?> treeId;
  final Value<int?> personId;
  final Value<MediaKind> type;
  final Value<String> path;
  final Value<String?> caption;
  final Value<DateTime> createdAt;
  const MediaTableCompanion({
    this.id = const Value.absent(),
    this.treeId = const Value.absent(),
    this.personId = const Value.absent(),
    this.type = const Value.absent(),
    this.path = const Value.absent(),
    this.caption = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MediaTableCompanion.insert({
    this.id = const Value.absent(),
    this.treeId = const Value.absent(),
    this.personId = const Value.absent(),
    required MediaKind type,
    required String path,
    this.caption = const Value.absent(),
    required DateTime createdAt,
  })  : type = Value(type),
        path = Value(path),
        createdAt = Value(createdAt);
  static Insertable<MediaTableData> custom({
    Expression<int>? id,
    Expression<int>? treeId,
    Expression<int>? personId,
    Expression<String>? type,
    Expression<String>? path,
    Expression<String>? caption,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (treeId != null) 'tree_id': treeId,
      if (personId != null) 'person_id': personId,
      if (type != null) 'type': type,
      if (path != null) 'path': path,
      if (caption != null) 'caption': caption,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MediaTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? treeId,
      Value<int?>? personId,
      Value<MediaKind>? type,
      Value<String>? path,
      Value<String?>? caption,
      Value<DateTime>? createdAt}) {
    return MediaTableCompanion(
      id: id ?? this.id,
      treeId: treeId ?? this.treeId,
      personId: personId ?? this.personId,
      type: type ?? this.type,
      path: path ?? this.path,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (treeId.present) {
      map['tree_id'] = Variable<int>(treeId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (type.present) {
      map['type'] =
          Variable<String>($MediaTableTable.$convertertype.toSql(type.value));
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaTableCompanion(')
          ..write('id: $id, ')
          ..write('treeId: $treeId, ')
          ..write('personId: $personId, ')
          ..write('type: $type, ')
          ..write('path: $path, ')
          ..write('caption: $caption, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PersonsTable extends Persons with TableInfo<$PersonsTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _treeIdMeta = const VerificationMeta('treeId');
  @override
  late final GeneratedColumn<int> treeId = GeneratedColumn<int>(
      'tree_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES family_trees (id)'));
  static const VerificationMeta _surnameMeta =
      const VerificationMeta('surname');
  @override
  late final GeneratedColumn<String> surname = GeneratedColumn<String>(
      'surname', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _givenNameMeta =
      const VerificationMeta('givenName');
  @override
  late final GeneratedColumn<String> givenName = GeneratedColumn<String>(
      'given_name', aliasedName, false,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _courtesyNameMeta =
      const VerificationMeta('courtesyName');
  @override
  late final GeneratedColumn<String> courtesyName = GeneratedColumn<String>(
      'courtesy_name', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _artNameMeta =
      const VerificationMeta('artName');
  @override
  late final GeneratedColumn<String> artName = GeneratedColumn<String>(
      'art_name', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumnWithTypeConverter<Gender, int> gender =
      GeneratedColumn<int>('gender', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<Gender>($PersonsTable.$convertergender);
  static const VerificationMeta _generationMeta =
      const VerificationMeta('generation');
  @override
  late final GeneratedColumn<int> generation = GeneratedColumn<int>(
      'generation', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _generationWordMeta =
      const VerificationMeta('generationWord');
  @override
  late final GeneratedColumn<String> generationWord = GeneratedColumn<String>(
      'generation_word', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _branchMeta = const VerificationMeta('branch');
  @override
  late final GeneratedColumn<String> branch = GeneratedColumn<String>(
      'branch', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
      'rank', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _birthDateMeta =
      const VerificationMeta('birthDate');
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
      'birth_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deathDateMeta =
      const VerificationMeta('deathDate');
  @override
  late final GeneratedColumn<DateTime> deathDate = GeneratedColumn<DateTime>(
      'death_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isAliveMeta =
      const VerificationMeta('isAlive');
  @override
  late final GeneratedColumn<bool> isAlive = GeneratedColumn<bool>(
      'is_alive', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_alive" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _birthPlaceMeta =
      const VerificationMeta('birthPlace');
  @override
  late final GeneratedColumn<String> birthPlace = GeneratedColumn<String>(
      'birth_place', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _deathPlaceMeta =
      const VerificationMeta('deathPlace');
  @override
  late final GeneratedColumn<String> deathPlace = GeneratedColumn<String>(
      'death_place', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _burialPlaceMeta =
      const VerificationMeta('burialPlace');
  @override
  late final GeneratedColumn<String> burialPlace = GeneratedColumn<String>(
      'burial_place', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _occupationMeta =
      const VerificationMeta('occupation');
  @override
  late final GeneratedColumn<String> occupation = GeneratedColumn<String>(
      'occupation', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _biographyMeta =
      const VerificationMeta('biography');
  @override
  late final GeneratedColumn<String> biography = GeneratedColumn<String>(
      'biography', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 10000),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _avatarMediaIdMeta =
      const VerificationMeta('avatarMediaId');
  @override
  late final GeneratedColumn<int> avatarMediaId = GeneratedColumn<int>(
      'avatar_media_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES media (id)'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        treeId,
        surname,
        givenName,
        courtesyName,
        artName,
        gender,
        generation,
        generationWord,
        branch,
        rank,
        birthDate,
        deathDate,
        isAlive,
        birthPlace,
        deathPlace,
        burialPlace,
        occupation,
        title,
        biography,
        avatarMediaId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'persons';
  @override
  VerificationContext validateIntegrity(Insertable<Person> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tree_id')) {
      context.handle(_treeIdMeta,
          treeId.isAcceptableOrUnknown(data['tree_id']!, _treeIdMeta));
    } else if (isInserting) {
      context.missing(_treeIdMeta);
    }
    if (data.containsKey('surname')) {
      context.handle(_surnameMeta,
          surname.isAcceptableOrUnknown(data['surname']!, _surnameMeta));
    } else if (isInserting) {
      context.missing(_surnameMeta);
    }
    if (data.containsKey('given_name')) {
      context.handle(_givenNameMeta,
          givenName.isAcceptableOrUnknown(data['given_name']!, _givenNameMeta));
    } else if (isInserting) {
      context.missing(_givenNameMeta);
    }
    if (data.containsKey('courtesy_name')) {
      context.handle(
          _courtesyNameMeta,
          courtesyName.isAcceptableOrUnknown(
              data['courtesy_name']!, _courtesyNameMeta));
    }
    if (data.containsKey('art_name')) {
      context.handle(_artNameMeta,
          artName.isAcceptableOrUnknown(data['art_name']!, _artNameMeta));
    }
    context.handle(_genderMeta, const VerificationResult.success());
    if (data.containsKey('generation')) {
      context.handle(
          _generationMeta,
          generation.isAcceptableOrUnknown(
              data['generation']!, _generationMeta));
    }
    if (data.containsKey('generation_word')) {
      context.handle(
          _generationWordMeta,
          generationWord.isAcceptableOrUnknown(
              data['generation_word']!, _generationWordMeta));
    }
    if (data.containsKey('branch')) {
      context.handle(_branchMeta,
          branch.isAcceptableOrUnknown(data['branch']!, _branchMeta));
    }
    if (data.containsKey('rank')) {
      context.handle(
          _rankMeta, rank.isAcceptableOrUnknown(data['rank']!, _rankMeta));
    }
    if (data.containsKey('birth_date')) {
      context.handle(_birthDateMeta,
          birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta));
    }
    if (data.containsKey('death_date')) {
      context.handle(_deathDateMeta,
          deathDate.isAcceptableOrUnknown(data['death_date']!, _deathDateMeta));
    }
    if (data.containsKey('is_alive')) {
      context.handle(_isAliveMeta,
          isAlive.isAcceptableOrUnknown(data['is_alive']!, _isAliveMeta));
    }
    if (data.containsKey('birth_place')) {
      context.handle(
          _birthPlaceMeta,
          birthPlace.isAcceptableOrUnknown(
              data['birth_place']!, _birthPlaceMeta));
    }
    if (data.containsKey('death_place')) {
      context.handle(
          _deathPlaceMeta,
          deathPlace.isAcceptableOrUnknown(
              data['death_place']!, _deathPlaceMeta));
    }
    if (data.containsKey('burial_place')) {
      context.handle(
          _burialPlaceMeta,
          burialPlace.isAcceptableOrUnknown(
              data['burial_place']!, _burialPlaceMeta));
    }
    if (data.containsKey('occupation')) {
      context.handle(
          _occupationMeta,
          occupation.isAcceptableOrUnknown(
              data['occupation']!, _occupationMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('biography')) {
      context.handle(_biographyMeta,
          biography.isAcceptableOrUnknown(data['biography']!, _biographyMeta));
    }
    if (data.containsKey('avatar_media_id')) {
      context.handle(
          _avatarMediaIdMeta,
          avatarMediaId.isAcceptableOrUnknown(
              data['avatar_media_id']!, _avatarMediaIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      treeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tree_id'])!,
      surname: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}surname'])!,
      givenName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}given_name'])!,
      courtesyName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}courtesy_name']),
      artName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}art_name']),
      gender: $PersonsTable.$convertergender.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gender'])!),
      generation: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}generation']),
      generationWord: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}generation_word']),
      branch: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch']),
      rank: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rank']),
      birthDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}birth_date']),
      deathDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}death_date']),
      isAlive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_alive'])!,
      birthPlace: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}birth_place']),
      deathPlace: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}death_place']),
      burialPlace: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}burial_place']),
      occupation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}occupation']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      biography: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}biography']),
      avatarMediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}avatar_media_id']),
    );
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Gender, int, int> $convertergender =
      const EnumIndexConverter<Gender>(Gender.values);
}

class Person extends DataClass implements Insertable<Person> {
  final int id;

  /// 所属家族
  final int treeId;

  /// 姓
  final String surname;

  /// 名
  final String givenName;

  /// 字
  final String? courtesyName;

  /// 号
  final String? artName;

  /// 性别
  final Gender gender;

  /// 世代（第几世）
  final int? generation;

  /// 字辈
  final String? generationWord;

  /// 房支
  final String? branch;

  /// 排行
  final int? rank;

  /// 生日
  final DateTime? birthDate;

  /// 忌日
  final DateTime? deathDate;

  /// 是否在世（默认在世）
  final bool isAlive;

  /// 出生地
  final String? birthPlace;

  /// 去世地
  final String? deathPlace;

  /// 葬地
  final String? burialPlace;

  /// 职业
  final String? occupation;

  /// 功名 / 头衔
  final String? title;

  /// 简介 / 家族故事
  final String? biography;

  /// 头像媒体 ID
  final int? avatarMediaId;
  const Person(
      {required this.id,
      required this.treeId,
      required this.surname,
      required this.givenName,
      this.courtesyName,
      this.artName,
      required this.gender,
      this.generation,
      this.generationWord,
      this.branch,
      this.rank,
      this.birthDate,
      this.deathDate,
      required this.isAlive,
      this.birthPlace,
      this.deathPlace,
      this.burialPlace,
      this.occupation,
      this.title,
      this.biography,
      this.avatarMediaId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tree_id'] = Variable<int>(treeId);
    map['surname'] = Variable<String>(surname);
    map['given_name'] = Variable<String>(givenName);
    if (!nullToAbsent || courtesyName != null) {
      map['courtesy_name'] = Variable<String>(courtesyName);
    }
    if (!nullToAbsent || artName != null) {
      map['art_name'] = Variable<String>(artName);
    }
    {
      map['gender'] =
          Variable<int>($PersonsTable.$convertergender.toSql(gender));
    }
    if (!nullToAbsent || generation != null) {
      map['generation'] = Variable<int>(generation);
    }
    if (!nullToAbsent || generationWord != null) {
      map['generation_word'] = Variable<String>(generationWord);
    }
    if (!nullToAbsent || branch != null) {
      map['branch'] = Variable<String>(branch);
    }
    if (!nullToAbsent || rank != null) {
      map['rank'] = Variable<int>(rank);
    }
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<DateTime>(birthDate);
    }
    if (!nullToAbsent || deathDate != null) {
      map['death_date'] = Variable<DateTime>(deathDate);
    }
    map['is_alive'] = Variable<bool>(isAlive);
    if (!nullToAbsent || birthPlace != null) {
      map['birth_place'] = Variable<String>(birthPlace);
    }
    if (!nullToAbsent || deathPlace != null) {
      map['death_place'] = Variable<String>(deathPlace);
    }
    if (!nullToAbsent || burialPlace != null) {
      map['burial_place'] = Variable<String>(burialPlace);
    }
    if (!nullToAbsent || occupation != null) {
      map['occupation'] = Variable<String>(occupation);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || biography != null) {
      map['biography'] = Variable<String>(biography);
    }
    if (!nullToAbsent || avatarMediaId != null) {
      map['avatar_media_id'] = Variable<int>(avatarMediaId);
    }
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      id: Value(id),
      treeId: Value(treeId),
      surname: Value(surname),
      givenName: Value(givenName),
      courtesyName: courtesyName == null && nullToAbsent
          ? const Value.absent()
          : Value(courtesyName),
      artName: artName == null && nullToAbsent
          ? const Value.absent()
          : Value(artName),
      gender: Value(gender),
      generation: generation == null && nullToAbsent
          ? const Value.absent()
          : Value(generation),
      generationWord: generationWord == null && nullToAbsent
          ? const Value.absent()
          : Value(generationWord),
      branch:
          branch == null && nullToAbsent ? const Value.absent() : Value(branch),
      rank: rank == null && nullToAbsent ? const Value.absent() : Value(rank),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      deathDate: deathDate == null && nullToAbsent
          ? const Value.absent()
          : Value(deathDate),
      isAlive: Value(isAlive),
      birthPlace: birthPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(birthPlace),
      deathPlace: deathPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(deathPlace),
      burialPlace: burialPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(burialPlace),
      occupation: occupation == null && nullToAbsent
          ? const Value.absent()
          : Value(occupation),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      biography: biography == null && nullToAbsent
          ? const Value.absent()
          : Value(biography),
      avatarMediaId: avatarMediaId == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarMediaId),
    );
  }

  factory Person.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<int>(json['id']),
      treeId: serializer.fromJson<int>(json['treeId']),
      surname: serializer.fromJson<String>(json['surname']),
      givenName: serializer.fromJson<String>(json['givenName']),
      courtesyName: serializer.fromJson<String?>(json['courtesyName']),
      artName: serializer.fromJson<String?>(json['artName']),
      gender: $PersonsTable.$convertergender
          .fromJson(serializer.fromJson<int>(json['gender'])),
      generation: serializer.fromJson<int?>(json['generation']),
      generationWord: serializer.fromJson<String?>(json['generationWord']),
      branch: serializer.fromJson<String?>(json['branch']),
      rank: serializer.fromJson<int?>(json['rank']),
      birthDate: serializer.fromJson<DateTime?>(json['birthDate']),
      deathDate: serializer.fromJson<DateTime?>(json['deathDate']),
      isAlive: serializer.fromJson<bool>(json['isAlive']),
      birthPlace: serializer.fromJson<String?>(json['birthPlace']),
      deathPlace: serializer.fromJson<String?>(json['deathPlace']),
      burialPlace: serializer.fromJson<String?>(json['burialPlace']),
      occupation: serializer.fromJson<String?>(json['occupation']),
      title: serializer.fromJson<String?>(json['title']),
      biography: serializer.fromJson<String?>(json['biography']),
      avatarMediaId: serializer.fromJson<int?>(json['avatarMediaId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'treeId': serializer.toJson<int>(treeId),
      'surname': serializer.toJson<String>(surname),
      'givenName': serializer.toJson<String>(givenName),
      'courtesyName': serializer.toJson<String?>(courtesyName),
      'artName': serializer.toJson<String?>(artName),
      'gender':
          serializer.toJson<int>($PersonsTable.$convertergender.toJson(gender)),
      'generation': serializer.toJson<int?>(generation),
      'generationWord': serializer.toJson<String?>(generationWord),
      'branch': serializer.toJson<String?>(branch),
      'rank': serializer.toJson<int?>(rank),
      'birthDate': serializer.toJson<DateTime?>(birthDate),
      'deathDate': serializer.toJson<DateTime?>(deathDate),
      'isAlive': serializer.toJson<bool>(isAlive),
      'birthPlace': serializer.toJson<String?>(birthPlace),
      'deathPlace': serializer.toJson<String?>(deathPlace),
      'burialPlace': serializer.toJson<String?>(burialPlace),
      'occupation': serializer.toJson<String?>(occupation),
      'title': serializer.toJson<String?>(title),
      'biography': serializer.toJson<String?>(biography),
      'avatarMediaId': serializer.toJson<int?>(avatarMediaId),
    };
  }

  Person copyWith(
          {int? id,
          int? treeId,
          String? surname,
          String? givenName,
          Value<String?> courtesyName = const Value.absent(),
          Value<String?> artName = const Value.absent(),
          Gender? gender,
          Value<int?> generation = const Value.absent(),
          Value<String?> generationWord = const Value.absent(),
          Value<String?> branch = const Value.absent(),
          Value<int?> rank = const Value.absent(),
          Value<DateTime?> birthDate = const Value.absent(),
          Value<DateTime?> deathDate = const Value.absent(),
          bool? isAlive,
          Value<String?> birthPlace = const Value.absent(),
          Value<String?> deathPlace = const Value.absent(),
          Value<String?> burialPlace = const Value.absent(),
          Value<String?> occupation = const Value.absent(),
          Value<String?> title = const Value.absent(),
          Value<String?> biography = const Value.absent(),
          Value<int?> avatarMediaId = const Value.absent()}) =>
      Person(
        id: id ?? this.id,
        treeId: treeId ?? this.treeId,
        surname: surname ?? this.surname,
        givenName: givenName ?? this.givenName,
        courtesyName:
            courtesyName.present ? courtesyName.value : this.courtesyName,
        artName: artName.present ? artName.value : this.artName,
        gender: gender ?? this.gender,
        generation: generation.present ? generation.value : this.generation,
        generationWord:
            generationWord.present ? generationWord.value : this.generationWord,
        branch: branch.present ? branch.value : this.branch,
        rank: rank.present ? rank.value : this.rank,
        birthDate: birthDate.present ? birthDate.value : this.birthDate,
        deathDate: deathDate.present ? deathDate.value : this.deathDate,
        isAlive: isAlive ?? this.isAlive,
        birthPlace: birthPlace.present ? birthPlace.value : this.birthPlace,
        deathPlace: deathPlace.present ? deathPlace.value : this.deathPlace,
        burialPlace: burialPlace.present ? burialPlace.value : this.burialPlace,
        occupation: occupation.present ? occupation.value : this.occupation,
        title: title.present ? title.value : this.title,
        biography: biography.present ? biography.value : this.biography,
        avatarMediaId:
            avatarMediaId.present ? avatarMediaId.value : this.avatarMediaId,
      );
  Person copyWithCompanion(PersonsCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      treeId: data.treeId.present ? data.treeId.value : this.treeId,
      surname: data.surname.present ? data.surname.value : this.surname,
      givenName: data.givenName.present ? data.givenName.value : this.givenName,
      courtesyName: data.courtesyName.present
          ? data.courtesyName.value
          : this.courtesyName,
      artName: data.artName.present ? data.artName.value : this.artName,
      gender: data.gender.present ? data.gender.value : this.gender,
      generation:
          data.generation.present ? data.generation.value : this.generation,
      generationWord: data.generationWord.present
          ? data.generationWord.value
          : this.generationWord,
      branch: data.branch.present ? data.branch.value : this.branch,
      rank: data.rank.present ? data.rank.value : this.rank,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      deathDate: data.deathDate.present ? data.deathDate.value : this.deathDate,
      isAlive: data.isAlive.present ? data.isAlive.value : this.isAlive,
      birthPlace:
          data.birthPlace.present ? data.birthPlace.value : this.birthPlace,
      deathPlace:
          data.deathPlace.present ? data.deathPlace.value : this.deathPlace,
      burialPlace:
          data.burialPlace.present ? data.burialPlace.value : this.burialPlace,
      occupation:
          data.occupation.present ? data.occupation.value : this.occupation,
      title: data.title.present ? data.title.value : this.title,
      biography: data.biography.present ? data.biography.value : this.biography,
      avatarMediaId: data.avatarMediaId.present
          ? data.avatarMediaId.value
          : this.avatarMediaId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('treeId: $treeId, ')
          ..write('surname: $surname, ')
          ..write('givenName: $givenName, ')
          ..write('courtesyName: $courtesyName, ')
          ..write('artName: $artName, ')
          ..write('gender: $gender, ')
          ..write('generation: $generation, ')
          ..write('generationWord: $generationWord, ')
          ..write('branch: $branch, ')
          ..write('rank: $rank, ')
          ..write('birthDate: $birthDate, ')
          ..write('deathDate: $deathDate, ')
          ..write('isAlive: $isAlive, ')
          ..write('birthPlace: $birthPlace, ')
          ..write('deathPlace: $deathPlace, ')
          ..write('burialPlace: $burialPlace, ')
          ..write('occupation: $occupation, ')
          ..write('title: $title, ')
          ..write('biography: $biography, ')
          ..write('avatarMediaId: $avatarMediaId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        treeId,
        surname,
        givenName,
        courtesyName,
        artName,
        gender,
        generation,
        generationWord,
        branch,
        rank,
        birthDate,
        deathDate,
        isAlive,
        birthPlace,
        deathPlace,
        burialPlace,
        occupation,
        title,
        biography,
        avatarMediaId
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.treeId == this.treeId &&
          other.surname == this.surname &&
          other.givenName == this.givenName &&
          other.courtesyName == this.courtesyName &&
          other.artName == this.artName &&
          other.gender == this.gender &&
          other.generation == this.generation &&
          other.generationWord == this.generationWord &&
          other.branch == this.branch &&
          other.rank == this.rank &&
          other.birthDate == this.birthDate &&
          other.deathDate == this.deathDate &&
          other.isAlive == this.isAlive &&
          other.birthPlace == this.birthPlace &&
          other.deathPlace == this.deathPlace &&
          other.burialPlace == this.burialPlace &&
          other.occupation == this.occupation &&
          other.title == this.title &&
          other.biography == this.biography &&
          other.avatarMediaId == this.avatarMediaId);
}

class PersonsCompanion extends UpdateCompanion<Person> {
  final Value<int> id;
  final Value<int> treeId;
  final Value<String> surname;
  final Value<String> givenName;
  final Value<String?> courtesyName;
  final Value<String?> artName;
  final Value<Gender> gender;
  final Value<int?> generation;
  final Value<String?> generationWord;
  final Value<String?> branch;
  final Value<int?> rank;
  final Value<DateTime?> birthDate;
  final Value<DateTime?> deathDate;
  final Value<bool> isAlive;
  final Value<String?> birthPlace;
  final Value<String?> deathPlace;
  final Value<String?> burialPlace;
  final Value<String?> occupation;
  final Value<String?> title;
  final Value<String?> biography;
  final Value<int?> avatarMediaId;
  const PersonsCompanion({
    this.id = const Value.absent(),
    this.treeId = const Value.absent(),
    this.surname = const Value.absent(),
    this.givenName = const Value.absent(),
    this.courtesyName = const Value.absent(),
    this.artName = const Value.absent(),
    this.gender = const Value.absent(),
    this.generation = const Value.absent(),
    this.generationWord = const Value.absent(),
    this.branch = const Value.absent(),
    this.rank = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.deathDate = const Value.absent(),
    this.isAlive = const Value.absent(),
    this.birthPlace = const Value.absent(),
    this.deathPlace = const Value.absent(),
    this.burialPlace = const Value.absent(),
    this.occupation = const Value.absent(),
    this.title = const Value.absent(),
    this.biography = const Value.absent(),
    this.avatarMediaId = const Value.absent(),
  });
  PersonsCompanion.insert({
    this.id = const Value.absent(),
    required int treeId,
    required String surname,
    required String givenName,
    this.courtesyName = const Value.absent(),
    this.artName = const Value.absent(),
    required Gender gender,
    this.generation = const Value.absent(),
    this.generationWord = const Value.absent(),
    this.branch = const Value.absent(),
    this.rank = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.deathDate = const Value.absent(),
    this.isAlive = const Value.absent(),
    this.birthPlace = const Value.absent(),
    this.deathPlace = const Value.absent(),
    this.burialPlace = const Value.absent(),
    this.occupation = const Value.absent(),
    this.title = const Value.absent(),
    this.biography = const Value.absent(),
    this.avatarMediaId = const Value.absent(),
  })  : treeId = Value(treeId),
        surname = Value(surname),
        givenName = Value(givenName),
        gender = Value(gender);
  static Insertable<Person> custom({
    Expression<int>? id,
    Expression<int>? treeId,
    Expression<String>? surname,
    Expression<String>? givenName,
    Expression<String>? courtesyName,
    Expression<String>? artName,
    Expression<int>? gender,
    Expression<int>? generation,
    Expression<String>? generationWord,
    Expression<String>? branch,
    Expression<int>? rank,
    Expression<DateTime>? birthDate,
    Expression<DateTime>? deathDate,
    Expression<bool>? isAlive,
    Expression<String>? birthPlace,
    Expression<String>? deathPlace,
    Expression<String>? burialPlace,
    Expression<String>? occupation,
    Expression<String>? title,
    Expression<String>? biography,
    Expression<int>? avatarMediaId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (treeId != null) 'tree_id': treeId,
      if (surname != null) 'surname': surname,
      if (givenName != null) 'given_name': givenName,
      if (courtesyName != null) 'courtesy_name': courtesyName,
      if (artName != null) 'art_name': artName,
      if (gender != null) 'gender': gender,
      if (generation != null) 'generation': generation,
      if (generationWord != null) 'generation_word': generationWord,
      if (branch != null) 'branch': branch,
      if (rank != null) 'rank': rank,
      if (birthDate != null) 'birth_date': birthDate,
      if (deathDate != null) 'death_date': deathDate,
      if (isAlive != null) 'is_alive': isAlive,
      if (birthPlace != null) 'birth_place': birthPlace,
      if (deathPlace != null) 'death_place': deathPlace,
      if (burialPlace != null) 'burial_place': burialPlace,
      if (occupation != null) 'occupation': occupation,
      if (title != null) 'title': title,
      if (biography != null) 'biography': biography,
      if (avatarMediaId != null) 'avatar_media_id': avatarMediaId,
    });
  }

  PersonsCompanion copyWith(
      {Value<int>? id,
      Value<int>? treeId,
      Value<String>? surname,
      Value<String>? givenName,
      Value<String?>? courtesyName,
      Value<String?>? artName,
      Value<Gender>? gender,
      Value<int?>? generation,
      Value<String?>? generationWord,
      Value<String?>? branch,
      Value<int?>? rank,
      Value<DateTime?>? birthDate,
      Value<DateTime?>? deathDate,
      Value<bool>? isAlive,
      Value<String?>? birthPlace,
      Value<String?>? deathPlace,
      Value<String?>? burialPlace,
      Value<String?>? occupation,
      Value<String?>? title,
      Value<String?>? biography,
      Value<int?>? avatarMediaId}) {
    return PersonsCompanion(
      id: id ?? this.id,
      treeId: treeId ?? this.treeId,
      surname: surname ?? this.surname,
      givenName: givenName ?? this.givenName,
      courtesyName: courtesyName ?? this.courtesyName,
      artName: artName ?? this.artName,
      gender: gender ?? this.gender,
      generation: generation ?? this.generation,
      generationWord: generationWord ?? this.generationWord,
      branch: branch ?? this.branch,
      rank: rank ?? this.rank,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      isAlive: isAlive ?? this.isAlive,
      birthPlace: birthPlace ?? this.birthPlace,
      deathPlace: deathPlace ?? this.deathPlace,
      burialPlace: burialPlace ?? this.burialPlace,
      occupation: occupation ?? this.occupation,
      title: title ?? this.title,
      biography: biography ?? this.biography,
      avatarMediaId: avatarMediaId ?? this.avatarMediaId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (treeId.present) {
      map['tree_id'] = Variable<int>(treeId.value);
    }
    if (surname.present) {
      map['surname'] = Variable<String>(surname.value);
    }
    if (givenName.present) {
      map['given_name'] = Variable<String>(givenName.value);
    }
    if (courtesyName.present) {
      map['courtesy_name'] = Variable<String>(courtesyName.value);
    }
    if (artName.present) {
      map['art_name'] = Variable<String>(artName.value);
    }
    if (gender.present) {
      map['gender'] =
          Variable<int>($PersonsTable.$convertergender.toSql(gender.value));
    }
    if (generation.present) {
      map['generation'] = Variable<int>(generation.value);
    }
    if (generationWord.present) {
      map['generation_word'] = Variable<String>(generationWord.value);
    }
    if (branch.present) {
      map['branch'] = Variable<String>(branch.value);
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (deathDate.present) {
      map['death_date'] = Variable<DateTime>(deathDate.value);
    }
    if (isAlive.present) {
      map['is_alive'] = Variable<bool>(isAlive.value);
    }
    if (birthPlace.present) {
      map['birth_place'] = Variable<String>(birthPlace.value);
    }
    if (deathPlace.present) {
      map['death_place'] = Variable<String>(deathPlace.value);
    }
    if (burialPlace.present) {
      map['burial_place'] = Variable<String>(burialPlace.value);
    }
    if (occupation.present) {
      map['occupation'] = Variable<String>(occupation.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (biography.present) {
      map['biography'] = Variable<String>(biography.value);
    }
    if (avatarMediaId.present) {
      map['avatar_media_id'] = Variable<int>(avatarMediaId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('id: $id, ')
          ..write('treeId: $treeId, ')
          ..write('surname: $surname, ')
          ..write('givenName: $givenName, ')
          ..write('courtesyName: $courtesyName, ')
          ..write('artName: $artName, ')
          ..write('gender: $gender, ')
          ..write('generation: $generation, ')
          ..write('generationWord: $generationWord, ')
          ..write('branch: $branch, ')
          ..write('rank: $rank, ')
          ..write('birthDate: $birthDate, ')
          ..write('deathDate: $deathDate, ')
          ..write('isAlive: $isAlive, ')
          ..write('birthPlace: $birthPlace, ')
          ..write('deathPlace: $deathPlace, ')
          ..write('burialPlace: $burialPlace, ')
          ..write('occupation: $occupation, ')
          ..write('title: $title, ')
          ..write('biography: $biography, ')
          ..write('avatarMediaId: $avatarMediaId')
          ..write(')'))
        .toString();
  }
}

class $RelationshipsTable extends Relationships
    with TableInfo<$RelationshipsTable, Relationship> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelationshipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _treeIdMeta = const VerificationMeta('treeId');
  @override
  late final GeneratedColumn<int> treeId = GeneratedColumn<int>(
      'tree_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES family_trees (id)'));
  static const VerificationMeta _fromPersonIdMeta =
      const VerificationMeta('fromPersonId');
  @override
  late final GeneratedColumn<int> fromPersonId = GeneratedColumn<int>(
      'from_person_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES persons (id)'));
  static const VerificationMeta _toPersonIdMeta =
      const VerificationMeta('toPersonId');
  @override
  late final GeneratedColumn<int> toPersonId = GeneratedColumn<int>(
      'to_person_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES persons (id)'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumnWithTypeConverter<RelationType, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<RelationType>($RelationshipsTable.$convertertype);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, treeId, fromPersonId, toPersonId, type, startDate, endDate, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relationships';
  @override
  VerificationContext validateIntegrity(Insertable<Relationship> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tree_id')) {
      context.handle(_treeIdMeta,
          treeId.isAcceptableOrUnknown(data['tree_id']!, _treeIdMeta));
    } else if (isInserting) {
      context.missing(_treeIdMeta);
    }
    if (data.containsKey('from_person_id')) {
      context.handle(
          _fromPersonIdMeta,
          fromPersonId.isAcceptableOrUnknown(
              data['from_person_id']!, _fromPersonIdMeta));
    } else if (isInserting) {
      context.missing(_fromPersonIdMeta);
    }
    if (data.containsKey('to_person_id')) {
      context.handle(
          _toPersonIdMeta,
          toPersonId.isAcceptableOrUnknown(
              data['to_person_id']!, _toPersonIdMeta));
    } else if (isInserting) {
      context.missing(_toPersonIdMeta);
    }
    context.handle(_typeMeta, const VerificationResult.success());
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Relationship map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Relationship(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      treeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tree_id'])!,
      fromPersonId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_person_id'])!,
      toPersonId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_person_id'])!,
      type: $RelationshipsTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date']),
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $RelationshipsTable createAlias(String alias) {
    return $RelationshipsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RelationType, String, String> $convertertype =
      const EnumNameConverter<RelationType>(RelationType.values);
}

class Relationship extends DataClass implements Insertable<Relationship> {
  final int id;

  /// 所属家族
  final int treeId;

  /// 关系发起方
  final int fromPersonId;

  /// 关系接收方
  final int toPersonId;

  /// 关系类型
  final RelationType type;

  /// 关系开始时间（如婚姻开始年）
  final DateTime? startDate;

  /// 关系结束时间（如继配结束年）
  final DateTime? endDate;

  /// 备注（如"继配""过继"等说明）
  final String? note;
  const Relationship(
      {required this.id,
      required this.treeId,
      required this.fromPersonId,
      required this.toPersonId,
      required this.type,
      this.startDate,
      this.endDate,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tree_id'] = Variable<int>(treeId);
    map['from_person_id'] = Variable<int>(fromPersonId);
    map['to_person_id'] = Variable<int>(toPersonId);
    {
      map['type'] =
          Variable<String>($RelationshipsTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  RelationshipsCompanion toCompanion(bool nullToAbsent) {
    return RelationshipsCompanion(
      id: Value(id),
      treeId: Value(treeId),
      fromPersonId: Value(fromPersonId),
      toPersonId: Value(toPersonId),
      type: Value(type),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Relationship.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Relationship(
      id: serializer.fromJson<int>(json['id']),
      treeId: serializer.fromJson<int>(json['treeId']),
      fromPersonId: serializer.fromJson<int>(json['fromPersonId']),
      toPersonId: serializer.fromJson<int>(json['toPersonId']),
      type: $RelationshipsTable.$convertertype
          .fromJson(serializer.fromJson<String>(json['type'])),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'treeId': serializer.toJson<int>(treeId),
      'fromPersonId': serializer.toJson<int>(fromPersonId),
      'toPersonId': serializer.toJson<int>(toPersonId),
      'type': serializer
          .toJson<String>($RelationshipsTable.$convertertype.toJson(type)),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'note': serializer.toJson<String?>(note),
    };
  }

  Relationship copyWith(
          {int? id,
          int? treeId,
          int? fromPersonId,
          int? toPersonId,
          RelationType? type,
          Value<DateTime?> startDate = const Value.absent(),
          Value<DateTime?> endDate = const Value.absent(),
          Value<String?> note = const Value.absent()}) =>
      Relationship(
        id: id ?? this.id,
        treeId: treeId ?? this.treeId,
        fromPersonId: fromPersonId ?? this.fromPersonId,
        toPersonId: toPersonId ?? this.toPersonId,
        type: type ?? this.type,
        startDate: startDate.present ? startDate.value : this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        note: note.present ? note.value : this.note,
      );
  Relationship copyWithCompanion(RelationshipsCompanion data) {
    return Relationship(
      id: data.id.present ? data.id.value : this.id,
      treeId: data.treeId.present ? data.treeId.value : this.treeId,
      fromPersonId: data.fromPersonId.present
          ? data.fromPersonId.value
          : this.fromPersonId,
      toPersonId:
          data.toPersonId.present ? data.toPersonId.value : this.toPersonId,
      type: data.type.present ? data.type.value : this.type,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Relationship(')
          ..write('id: $id, ')
          ..write('treeId: $treeId, ')
          ..write('fromPersonId: $fromPersonId, ')
          ..write('toPersonId: $toPersonId, ')
          ..write('type: $type, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, treeId, fromPersonId, toPersonId, type, startDate, endDate, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Relationship &&
          other.id == this.id &&
          other.treeId == this.treeId &&
          other.fromPersonId == this.fromPersonId &&
          other.toPersonId == this.toPersonId &&
          other.type == this.type &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.note == this.note);
}

class RelationshipsCompanion extends UpdateCompanion<Relationship> {
  final Value<int> id;
  final Value<int> treeId;
  final Value<int> fromPersonId;
  final Value<int> toPersonId;
  final Value<RelationType> type;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<String?> note;
  const RelationshipsCompanion({
    this.id = const Value.absent(),
    this.treeId = const Value.absent(),
    this.fromPersonId = const Value.absent(),
    this.toPersonId = const Value.absent(),
    this.type = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.note = const Value.absent(),
  });
  RelationshipsCompanion.insert({
    this.id = const Value.absent(),
    required int treeId,
    required int fromPersonId,
    required int toPersonId,
    required RelationType type,
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.note = const Value.absent(),
  })  : treeId = Value(treeId),
        fromPersonId = Value(fromPersonId),
        toPersonId = Value(toPersonId),
        type = Value(type);
  static Insertable<Relationship> custom({
    Expression<int>? id,
    Expression<int>? treeId,
    Expression<int>? fromPersonId,
    Expression<int>? toPersonId,
    Expression<String>? type,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (treeId != null) 'tree_id': treeId,
      if (fromPersonId != null) 'from_person_id': fromPersonId,
      if (toPersonId != null) 'to_person_id': toPersonId,
      if (type != null) 'type': type,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (note != null) 'note': note,
    });
  }

  RelationshipsCompanion copyWith(
      {Value<int>? id,
      Value<int>? treeId,
      Value<int>? fromPersonId,
      Value<int>? toPersonId,
      Value<RelationType>? type,
      Value<DateTime?>? startDate,
      Value<DateTime?>? endDate,
      Value<String?>? note}) {
    return RelationshipsCompanion(
      id: id ?? this.id,
      treeId: treeId ?? this.treeId,
      fromPersonId: fromPersonId ?? this.fromPersonId,
      toPersonId: toPersonId ?? this.toPersonId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (treeId.present) {
      map['tree_id'] = Variable<int>(treeId.value);
    }
    if (fromPersonId.present) {
      map['from_person_id'] = Variable<int>(fromPersonId.value);
    }
    if (toPersonId.present) {
      map['to_person_id'] = Variable<int>(toPersonId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
          $RelationshipsTable.$convertertype.toSql(type.value));
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelationshipsCompanion(')
          ..write('id: $id, ')
          ..write('treeId: $treeId, ')
          ..write('fromPersonId: $fromPersonId, ')
          ..write('toPersonId: $toPersonId, ')
          ..write('type: $type, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _personIdMeta =
      const VerificationMeta('personId');
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
      'person_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES persons (id)'));
  static const VerificationMeta _treeIdMeta = const VerificationMeta('treeId');
  @override
  late final GeneratedColumn<int> treeId = GeneratedColumn<int>(
      'tree_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES family_trees (id)'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumnWithTypeConverter<EventType, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<EventType>($EventsTable.$convertertype);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _placeMeta = const VerificationMeta('place');
  @override
  late final GeneratedColumn<String> place = GeneratedColumn<String>(
      'place', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 5000),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, personId, treeId, type, title, date, place, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(Insertable<Event> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(_personIdMeta,
          personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta));
    }
    if (data.containsKey('tree_id')) {
      context.handle(_treeIdMeta,
          treeId.isAcceptableOrUnknown(data['tree_id']!, _treeIdMeta));
    } else if (isInserting) {
      context.missing(_treeIdMeta);
    }
    context.handle(_typeMeta, const VerificationResult.success());
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    }
    if (data.containsKey('place')) {
      context.handle(
          _placeMeta, place.isAcceptableOrUnknown(data['place']!, _placeMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      personId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}person_id']),
      treeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tree_id'])!,
      type: $EventsTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date']),
      place: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}place']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EventType, String, String> $convertertype =
      const EnumNameConverter<EventType>(EventType.values);
}

class Event extends DataClass implements Insertable<Event> {
  final int id;

  /// 关联成员（可空：家族级事件可不关联具体成员）
  final int? personId;

  /// 所属家族
  final int treeId;

  /// 事件类型
  final EventType type;

  /// 事件标题
  final String title;

  /// 事件日期
  final DateTime? date;

  /// 事件地点
  final String? place;

  /// 事件描述
  final String? description;
  const Event(
      {required this.id,
      this.personId,
      required this.treeId,
      required this.type,
      required this.title,
      this.date,
      this.place,
      this.description});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    map['tree_id'] = Variable<int>(treeId);
    {
      map['type'] = Variable<String>($EventsTable.$convertertype.toSql(type));
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<DateTime>(date);
    }
    if (!nullToAbsent || place != null) {
      map['place'] = Variable<String>(place);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      treeId: Value(treeId),
      type: Value(type),
      title: Value(title),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      place:
          place == null && nullToAbsent ? const Value.absent() : Value(place),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory Event.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int?>(json['personId']),
      treeId: serializer.fromJson<int>(json['treeId']),
      type: $EventsTable.$convertertype
          .fromJson(serializer.fromJson<String>(json['type'])),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<DateTime?>(json['date']),
      place: serializer.fromJson<String?>(json['place']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int?>(personId),
      'treeId': serializer.toJson<int>(treeId),
      'type':
          serializer.toJson<String>($EventsTable.$convertertype.toJson(type)),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<DateTime?>(date),
      'place': serializer.toJson<String?>(place),
      'description': serializer.toJson<String?>(description),
    };
  }

  Event copyWith(
          {int? id,
          Value<int?> personId = const Value.absent(),
          int? treeId,
          EventType? type,
          String? title,
          Value<DateTime?> date = const Value.absent(),
          Value<String?> place = const Value.absent(),
          Value<String?> description = const Value.absent()}) =>
      Event(
        id: id ?? this.id,
        personId: personId.present ? personId.value : this.personId,
        treeId: treeId ?? this.treeId,
        type: type ?? this.type,
        title: title ?? this.title,
        date: date.present ? date.value : this.date,
        place: place.present ? place.value : this.place,
        description: description.present ? description.value : this.description,
      );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      treeId: data.treeId.present ? data.treeId.value : this.treeId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      place: data.place.present ? data.place.value : this.place,
      description:
          data.description.present ? data.description.value : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('treeId: $treeId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('place: $place, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, personId, treeId, type, title, date, place, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.treeId == this.treeId &&
          other.type == this.type &&
          other.title == this.title &&
          other.date == this.date &&
          other.place == this.place &&
          other.description == this.description);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<int> id;
  final Value<int?> personId;
  final Value<int> treeId;
  final Value<EventType> type;
  final Value<String> title;
  final Value<DateTime?> date;
  final Value<String?> place;
  final Value<String?> description;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.treeId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.place = const Value.absent(),
    this.description = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    required int treeId,
    required EventType type,
    required String title,
    this.date = const Value.absent(),
    this.place = const Value.absent(),
    this.description = const Value.absent(),
  })  : treeId = Value(treeId),
        type = Value(type),
        title = Value(title);
  static Insertable<Event> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<int>? treeId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<DateTime>? date,
    Expression<String>? place,
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (treeId != null) 'tree_id': treeId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (place != null) 'place': place,
      if (description != null) 'description': description,
    });
  }

  EventsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? personId,
      Value<int>? treeId,
      Value<EventType>? type,
      Value<String>? title,
      Value<DateTime?>? date,
      Value<String?>? place,
      Value<String?>? description}) {
    return EventsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      treeId: treeId ?? this.treeId,
      type: type ?? this.type,
      title: title ?? this.title,
      date: date ?? this.date,
      place: place ?? this.place,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (treeId.present) {
      map['tree_id'] = Variable<int>(treeId.value);
    }
    if (type.present) {
      map['type'] =
          Variable<String>($EventsTable.$convertertype.toSql(type.value));
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (place.present) {
      map['place'] = Variable<String>(place.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('treeId: $treeId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('place: $place, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

class $PlacesTable extends Places with TableInfo<$PlacesTable, Place> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, address, latitude, longitude];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'places';
  @override
  VerificationContext validateIntegrity(Insertable<Place> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Place map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Place(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
    );
  }

  @override
  $PlacesTable createAlias(String alias) {
    return $PlacesTable(attachedDatabase, alias);
  }
}

class Place extends DataClass implements Insertable<Place> {
  final int id;

  /// 地点名称
  final String name;

  /// 详细地址
  final String? address;

  /// 纬度
  final double? latitude;

  /// 经度
  final double? longitude;
  const Place(
      {required this.id,
      required this.name,
      this.address,
      this.latitude,
      this.longitude});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    return map;
  }

  PlacesCompanion toCompanion(bool nullToAbsent) {
    return PlacesCompanion(
      id: Value(id),
      name: Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
    );
  }

  factory Place.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Place(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String?>(address),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
    };
  }

  Place copyWith(
          {int? id,
          String? name,
          Value<String?> address = const Value.absent(),
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent()}) =>
      Place(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address.present ? address.value : this.address,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
      );
  Place copyWithCompanion(PlacesCompanion data) {
    return Place(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Place(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, address, latitude, longitude);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Place &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude);
}

class PlacesCompanion extends UpdateCompanion<Place> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> address;
  final Value<double?> latitude;
  final Value<double?> longitude;
  const PlacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
  });
  PlacesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.address = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Place> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<double>? latitude,
    Expression<double>? longitude,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  PlacesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? address,
      Value<double?>? latitude,
      Value<double?>? longitude}) {
    return PlacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }
}

class $SourcesTable extends Sources with TableInfo<$SourcesTable, Source> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _treeIdMeta = const VerificationMeta('treeId');
  @override
  late final GeneratedColumn<int> treeId = GeneratedColumn<int>(
      'tree_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES family_trees (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 300),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 1000),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 2000),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, treeId, title, url, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(Insertable<Source> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tree_id')) {
      context.handle(_treeIdMeta,
          treeId.isAcceptableOrUnknown(data['tree_id']!, _treeIdMeta));
    } else if (isInserting) {
      context.missing(_treeIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Source map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Source(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      treeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tree_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }
}

class Source extends DataClass implements Insertable<Source> {
  final int id;

  /// 所属家族
  final int treeId;

  /// 资料标题
  final String title;

  /// 资料链接
  final String? url;

  /// 备注
  final String? note;
  const Source(
      {required this.id,
      required this.treeId,
      required this.title,
      this.url,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tree_id'] = Variable<int>(treeId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      treeId: Value(treeId),
      title: Value(title),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Source.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Source(
      id: serializer.fromJson<int>(json['id']),
      treeId: serializer.fromJson<int>(json['treeId']),
      title: serializer.fromJson<String>(json['title']),
      url: serializer.fromJson<String?>(json['url']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'treeId': serializer.toJson<int>(treeId),
      'title': serializer.toJson<String>(title),
      'url': serializer.toJson<String?>(url),
      'note': serializer.toJson<String?>(note),
    };
  }

  Source copyWith(
          {int? id,
          int? treeId,
          String? title,
          Value<String?> url = const Value.absent(),
          Value<String?> note = const Value.absent()}) =>
      Source(
        id: id ?? this.id,
        treeId: treeId ?? this.treeId,
        title: title ?? this.title,
        url: url.present ? url.value : this.url,
        note: note.present ? note.value : this.note,
      );
  Source copyWithCompanion(SourcesCompanion data) {
    return Source(
      id: data.id.present ? data.id.value : this.id,
      treeId: data.treeId.present ? data.treeId.value : this.treeId,
      title: data.title.present ? data.title.value : this.title,
      url: data.url.present ? data.url.value : this.url,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Source(')
          ..write('id: $id, ')
          ..write('treeId: $treeId, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, treeId, title, url, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Source &&
          other.id == this.id &&
          other.treeId == this.treeId &&
          other.title == this.title &&
          other.url == this.url &&
          other.note == this.note);
}

class SourcesCompanion extends UpdateCompanion<Source> {
  final Value<int> id;
  final Value<int> treeId;
  final Value<String> title;
  final Value<String?> url;
  final Value<String?> note;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.treeId = const Value.absent(),
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    this.note = const Value.absent(),
  });
  SourcesCompanion.insert({
    this.id = const Value.absent(),
    required int treeId,
    required String title,
    this.url = const Value.absent(),
    this.note = const Value.absent(),
  })  : treeId = Value(treeId),
        title = Value(title);
  static Insertable<Source> custom({
    Expression<int>? id,
    Expression<int>? treeId,
    Expression<String>? title,
    Expression<String>? url,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (treeId != null) 'tree_id': treeId,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (note != null) 'note': note,
    });
  }

  SourcesCompanion copyWith(
      {Value<int>? id,
      Value<int>? treeId,
      Value<String>? title,
      Value<String?>? url,
      Value<String?>? note}) {
    return SourcesCompanion(
      id: id ?? this.id,
      treeId: treeId ?? this.treeId,
      title: title ?? this.title,
      url: url ?? this.url,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (treeId.present) {
      map['tree_id'] = Variable<int>(treeId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('treeId: $treeId, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FamilyTreesTable familyTrees = $FamilyTreesTable(this);
  late final $MediaTableTable mediaTable = $MediaTableTable(this);
  late final $PersonsTable persons = $PersonsTable(this);
  late final $RelationshipsTable relationships = $RelationshipsTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $PlacesTable places = $PlacesTable(this);
  late final $SourcesTable sources = $SourcesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        familyTrees,
        mediaTable,
        persons,
        relationships,
        events,
        places,
        sources
      ];
}

typedef $$FamilyTreesTableCreateCompanionBuilder = FamilyTreesCompanion
    Function({
  Value<int> id,
  required String name,
  required String surname,
  Value<String?> hallName,
  Value<String?> origin,
  Value<String?> generationWords,
  Value<String?> description,
  Value<int?> coverMediaId,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$FamilyTreesTableUpdateCompanionBuilder = FamilyTreesCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> surname,
  Value<String?> hallName,
  Value<String?> origin,
  Value<String?> generationWords,
  Value<String?> description,
  Value<int?> coverMediaId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$FamilyTreesTableReferences
    extends BaseReferences<_$AppDatabase, $FamilyTreesTable, FamilyTree> {
  $$FamilyTreesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PersonsTable, List<Person>> _personsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.persons,
          aliasName:
              $_aliasNameGenerator(db.familyTrees.id, db.persons.treeId));

  $$PersonsTableProcessedTableManager get personsRefs {
    final manager = $$PersonsTableTableManager($_db, $_db.persons)
        .filter((f) => f.treeId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_personsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RelationshipsTable, List<Relationship>>
      _relationshipsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.relationships,
              aliasName: $_aliasNameGenerator(
                  db.familyTrees.id, db.relationships.treeId));

  $$RelationshipsTableProcessedTableManager get relationshipsRefs {
    final manager = $$RelationshipsTableTableManager($_db, $_db.relationships)
        .filter((f) => f.treeId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_relationshipsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EventsTable, List<Event>> _eventsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.events,
          aliasName: $_aliasNameGenerator(db.familyTrees.id, db.events.treeId));

  $$EventsTableProcessedTableManager get eventsRefs {
    final manager = $$EventsTableTableManager($_db, $_db.events)
        .filter((f) => f.treeId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_eventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SourcesTable, List<Source>> _sourcesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.sources,
          aliasName:
              $_aliasNameGenerator(db.familyTrees.id, db.sources.treeId));

  $$SourcesTableProcessedTableManager get sourcesRefs {
    final manager = $$SourcesTableTableManager($_db, $_db.sources)
        .filter((f) => f.treeId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_sourcesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FamilyTreesTableFilterComposer
    extends Composer<_$AppDatabase, $FamilyTreesTable> {
  $$FamilyTreesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surname => $composableBuilder(
      column: $table.surname, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hallName => $composableBuilder(
      column: $table.hallName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get generationWords => $composableBuilder(
      column: $table.generationWords,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get coverMediaId => $composableBuilder(
      column: $table.coverMediaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> personsRefs(
      Expression<bool> Function($$PersonsTableFilterComposer f) f) {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.treeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableFilterComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> relationshipsRefs(
      Expression<bool> Function($$RelationshipsTableFilterComposer f) f) {
    final $$RelationshipsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.relationships,
        getReferencedColumn: (t) => t.treeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RelationshipsTableFilterComposer(
              $db: $db,
              $table: $db.relationships,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> eventsRefs(
      Expression<bool> Function($$EventsTableFilterComposer f) f) {
    final $$EventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.treeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableFilterComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> sourcesRefs(
      Expression<bool> Function($$SourcesTableFilterComposer f) f) {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sources,
        getReferencedColumn: (t) => t.treeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SourcesTableFilterComposer(
              $db: $db,
              $table: $db.sources,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FamilyTreesTableOrderingComposer
    extends Composer<_$AppDatabase, $FamilyTreesTable> {
  $$FamilyTreesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surname => $composableBuilder(
      column: $table.surname, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hallName => $composableBuilder(
      column: $table.hallName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get generationWords => $composableBuilder(
      column: $table.generationWords,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get coverMediaId => $composableBuilder(
      column: $table.coverMediaId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FamilyTreesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamilyTreesTable> {
  $$FamilyTreesTableAnnotationComposer({
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

  GeneratedColumn<String> get surname =>
      $composableBuilder(column: $table.surname, builder: (column) => column);

  GeneratedColumn<String> get hallName =>
      $composableBuilder(column: $table.hallName, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get generationWords => $composableBuilder(
      column: $table.generationWords, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get coverMediaId => $composableBuilder(
      column: $table.coverMediaId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> personsRefs<T extends Object>(
      Expression<T> Function($$PersonsTableAnnotationComposer a) f) {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.treeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableAnnotationComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> relationshipsRefs<T extends Object>(
      Expression<T> Function($$RelationshipsTableAnnotationComposer a) f) {
    final $$RelationshipsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.relationships,
        getReferencedColumn: (t) => t.treeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RelationshipsTableAnnotationComposer(
              $db: $db,
              $table: $db.relationships,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> eventsRefs<T extends Object>(
      Expression<T> Function($$EventsTableAnnotationComposer a) f) {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.treeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableAnnotationComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> sourcesRefs<T extends Object>(
      Expression<T> Function($$SourcesTableAnnotationComposer a) f) {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sources,
        getReferencedColumn: (t) => t.treeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SourcesTableAnnotationComposer(
              $db: $db,
              $table: $db.sources,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FamilyTreesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FamilyTreesTable,
    FamilyTree,
    $$FamilyTreesTableFilterComposer,
    $$FamilyTreesTableOrderingComposer,
    $$FamilyTreesTableAnnotationComposer,
    $$FamilyTreesTableCreateCompanionBuilder,
    $$FamilyTreesTableUpdateCompanionBuilder,
    (FamilyTree, $$FamilyTreesTableReferences),
    FamilyTree,
    PrefetchHooks Function(
        {bool personsRefs,
        bool relationshipsRefs,
        bool eventsRefs,
        bool sourcesRefs})> {
  $$FamilyTreesTableTableManager(_$AppDatabase db, $FamilyTreesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyTreesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyTreesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyTreesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> surname = const Value.absent(),
            Value<String?> hallName = const Value.absent(),
            Value<String?> origin = const Value.absent(),
            Value<String?> generationWords = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int?> coverMediaId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              FamilyTreesCompanion(
            id: id,
            name: name,
            surname: surname,
            hallName: hallName,
            origin: origin,
            generationWords: generationWords,
            description: description,
            coverMediaId: coverMediaId,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String surname,
            Value<String?> hallName = const Value.absent(),
            Value<String?> origin = const Value.absent(),
            Value<String?> generationWords = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int?> coverMediaId = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              FamilyTreesCompanion.insert(
            id: id,
            name: name,
            surname: surname,
            hallName: hallName,
            origin: origin,
            generationWords: generationWords,
            description: description,
            coverMediaId: coverMediaId,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FamilyTreesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {personsRefs = false,
              relationshipsRefs = false,
              eventsRefs = false,
              sourcesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (personsRefs) db.persons,
                if (relationshipsRefs) db.relationships,
                if (eventsRefs) db.events,
                if (sourcesRefs) db.sources
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (personsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$FamilyTreesTableReferences._personsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FamilyTreesTableReferences(db, table, p0)
                                .personsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.treeId == item.id),
                        typedResults: items),
                  if (relationshipsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$FamilyTreesTableReferences
                            ._relationshipsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FamilyTreesTableReferences(db, table, p0)
                                .relationshipsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.treeId == item.id),
                        typedResults: items),
                  if (eventsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$FamilyTreesTableReferences._eventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FamilyTreesTableReferences(db, table, p0)
                                .eventsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.treeId == item.id),
                        typedResults: items),
                  if (sourcesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$FamilyTreesTableReferences._sourcesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FamilyTreesTableReferences(db, table, p0)
                                .sourcesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.treeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$FamilyTreesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FamilyTreesTable,
    FamilyTree,
    $$FamilyTreesTableFilterComposer,
    $$FamilyTreesTableOrderingComposer,
    $$FamilyTreesTableAnnotationComposer,
    $$FamilyTreesTableCreateCompanionBuilder,
    $$FamilyTreesTableUpdateCompanionBuilder,
    (FamilyTree, $$FamilyTreesTableReferences),
    FamilyTree,
    PrefetchHooks Function(
        {bool personsRefs,
        bool relationshipsRefs,
        bool eventsRefs,
        bool sourcesRefs})>;
typedef $$MediaTableTableCreateCompanionBuilder = MediaTableCompanion Function({
  Value<int> id,
  Value<int?> treeId,
  Value<int?> personId,
  required MediaKind type,
  required String path,
  Value<String?> caption,
  required DateTime createdAt,
});
typedef $$MediaTableTableUpdateCompanionBuilder = MediaTableCompanion Function({
  Value<int> id,
  Value<int?> treeId,
  Value<int?> personId,
  Value<MediaKind> type,
  Value<String> path,
  Value<String?> caption,
  Value<DateTime> createdAt,
});

final class $$MediaTableTableReferences
    extends BaseReferences<_$AppDatabase, $MediaTableTable, MediaTableData> {
  $$MediaTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PersonsTable, List<Person>> _personsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.persons,
          aliasName:
              $_aliasNameGenerator(db.mediaTable.id, db.persons.avatarMediaId));

  $$PersonsTableProcessedTableManager get personsRefs {
    final manager = $$PersonsTableTableManager($_db, $_db.persons)
        .filter((f) => f.avatarMediaId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_personsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MediaTableTableFilterComposer
    extends Composer<_$AppDatabase, $MediaTableTable> {
  $$MediaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get treeId => $composableBuilder(
      column: $table.treeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get personId => $composableBuilder(
      column: $table.personId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MediaKind, MediaKind, String> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> personsRefs(
      Expression<bool> Function($$PersonsTableFilterComposer f) f) {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.avatarMediaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableFilterComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MediaTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaTableTable> {
  $$MediaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get treeId => $composableBuilder(
      column: $table.treeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get personId => $composableBuilder(
      column: $table.personId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MediaTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaTableTable> {
  $$MediaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get treeId =>
      $composableBuilder(column: $table.treeId, builder: (column) => column);

  GeneratedColumn<int> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaKind, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> personsRefs<T extends Object>(
      Expression<T> Function($$PersonsTableAnnotationComposer a) f) {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.avatarMediaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableAnnotationComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MediaTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaTableTable,
    MediaTableData,
    $$MediaTableTableFilterComposer,
    $$MediaTableTableOrderingComposer,
    $$MediaTableTableAnnotationComposer,
    $$MediaTableTableCreateCompanionBuilder,
    $$MediaTableTableUpdateCompanionBuilder,
    (MediaTableData, $$MediaTableTableReferences),
    MediaTableData,
    PrefetchHooks Function({bool personsRefs})> {
  $$MediaTableTableTableManager(_$AppDatabase db, $MediaTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> treeId = const Value.absent(),
            Value<int?> personId = const Value.absent(),
            Value<MediaKind> type = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<String?> caption = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MediaTableCompanion(
            id: id,
            treeId: treeId,
            personId: personId,
            type: type,
            path: path,
            caption: caption,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> treeId = const Value.absent(),
            Value<int?> personId = const Value.absent(),
            required MediaKind type,
            required String path,
            Value<String?> caption = const Value.absent(),
            required DateTime createdAt,
          }) =>
              MediaTableCompanion.insert(
            id: id,
            treeId: treeId,
            personId: personId,
            type: type,
            path: path,
            caption: caption,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MediaTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({personsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (personsRefs) db.persons],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (personsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$MediaTableTableReferences._personsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MediaTableTableReferences(db, table, p0)
                                .personsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.avatarMediaId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$MediaTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaTableTable,
    MediaTableData,
    $$MediaTableTableFilterComposer,
    $$MediaTableTableOrderingComposer,
    $$MediaTableTableAnnotationComposer,
    $$MediaTableTableCreateCompanionBuilder,
    $$MediaTableTableUpdateCompanionBuilder,
    (MediaTableData, $$MediaTableTableReferences),
    MediaTableData,
    PrefetchHooks Function({bool personsRefs})>;
typedef $$PersonsTableCreateCompanionBuilder = PersonsCompanion Function({
  Value<int> id,
  required int treeId,
  required String surname,
  required String givenName,
  Value<String?> courtesyName,
  Value<String?> artName,
  required Gender gender,
  Value<int?> generation,
  Value<String?> generationWord,
  Value<String?> branch,
  Value<int?> rank,
  Value<DateTime?> birthDate,
  Value<DateTime?> deathDate,
  Value<bool> isAlive,
  Value<String?> birthPlace,
  Value<String?> deathPlace,
  Value<String?> burialPlace,
  Value<String?> occupation,
  Value<String?> title,
  Value<String?> biography,
  Value<int?> avatarMediaId,
});
typedef $$PersonsTableUpdateCompanionBuilder = PersonsCompanion Function({
  Value<int> id,
  Value<int> treeId,
  Value<String> surname,
  Value<String> givenName,
  Value<String?> courtesyName,
  Value<String?> artName,
  Value<Gender> gender,
  Value<int?> generation,
  Value<String?> generationWord,
  Value<String?> branch,
  Value<int?> rank,
  Value<DateTime?> birthDate,
  Value<DateTime?> deathDate,
  Value<bool> isAlive,
  Value<String?> birthPlace,
  Value<String?> deathPlace,
  Value<String?> burialPlace,
  Value<String?> occupation,
  Value<String?> title,
  Value<String?> biography,
  Value<int?> avatarMediaId,
});

final class $$PersonsTableReferences
    extends BaseReferences<_$AppDatabase, $PersonsTable, Person> {
  $$PersonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FamilyTreesTable _treeIdTable(_$AppDatabase db) => db.familyTrees
      .createAlias($_aliasNameGenerator(db.persons.treeId, db.familyTrees.id));

  $$FamilyTreesTableProcessedTableManager get treeId {
    final manager = $$FamilyTreesTableTableManager($_db, $_db.familyTrees)
        .filter((f) => f.id($_item.treeId));
    final item = $_typedResult.readTableOrNull(_treeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $MediaTableTable _avatarMediaIdTable(_$AppDatabase db) =>
      db.mediaTable.createAlias(
          $_aliasNameGenerator(db.persons.avatarMediaId, db.mediaTable.id));

  $$MediaTableTableProcessedTableManager? get avatarMediaId {
    if ($_item.avatarMediaId == null) return null;
    final manager = $$MediaTableTableTableManager($_db, $_db.mediaTable)
        .filter((f) => f.id($_item.avatarMediaId!));
    final item = $_typedResult.readTableOrNull(_avatarMediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RelationshipsTable, List<Relationship>>
      _from_relationshipsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.relationships,
              aliasName: $_aliasNameGenerator(
                  db.persons.id, db.relationships.fromPersonId));

  $$RelationshipsTableProcessedTableManager get from_relationships {
    final manager = $$RelationshipsTableTableManager($_db, $_db.relationships)
        .filter((f) => f.fromPersonId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_from_relationshipsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RelationshipsTable, List<Relationship>>
      _to_relationshipsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.relationships,
          aliasName:
              $_aliasNameGenerator(db.persons.id, db.relationships.toPersonId));

  $$RelationshipsTableProcessedTableManager get to_relationships {
    final manager = $$RelationshipsTableTableManager($_db, $_db.relationships)
        .filter((f) => f.toPersonId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_to_relationshipsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EventsTable, List<Event>> _eventsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.events,
          aliasName: $_aliasNameGenerator(db.persons.id, db.events.personId));

  $$EventsTableProcessedTableManager get eventsRefs {
    final manager = $$EventsTableTableManager($_db, $_db.events)
        .filter((f) => f.personId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_eventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PersonsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surname => $composableBuilder(
      column: $table.surname, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get givenName => $composableBuilder(
      column: $table.givenName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get courtesyName => $composableBuilder(
      column: $table.courtesyName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artName => $composableBuilder(
      column: $table.artName, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Gender, Gender, int> get gender =>
      $composableBuilder(
          column: $table.gender,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get generation => $composableBuilder(
      column: $table.generation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get generationWord => $composableBuilder(
      column: $table.generationWord,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branch => $composableBuilder(
      column: $table.branch, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rank => $composableBuilder(
      column: $table.rank, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
      column: $table.birthDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deathDate => $composableBuilder(
      column: $table.deathDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAlive => $composableBuilder(
      column: $table.isAlive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get birthPlace => $composableBuilder(
      column: $table.birthPlace, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deathPlace => $composableBuilder(
      column: $table.deathPlace, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get burialPlace => $composableBuilder(
      column: $table.burialPlace, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get occupation => $composableBuilder(
      column: $table.occupation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get biography => $composableBuilder(
      column: $table.biography, builder: (column) => ColumnFilters(column));

  $$FamilyTreesTableFilterComposer get treeId {
    final $$FamilyTreesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treeId,
        referencedTable: $db.familyTrees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FamilyTreesTableFilterComposer(
              $db: $db,
              $table: $db.familyTrees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MediaTableTableFilterComposer get avatarMediaId {
    final $$MediaTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.avatarMediaId,
        referencedTable: $db.mediaTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MediaTableTableFilterComposer(
              $db: $db,
              $table: $db.mediaTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> from_relationships(
      Expression<bool> Function($$RelationshipsTableFilterComposer f) f) {
    final $$RelationshipsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.relationships,
        getReferencedColumn: (t) => t.fromPersonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RelationshipsTableFilterComposer(
              $db: $db,
              $table: $db.relationships,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> to_relationships(
      Expression<bool> Function($$RelationshipsTableFilterComposer f) f) {
    final $$RelationshipsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.relationships,
        getReferencedColumn: (t) => t.toPersonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RelationshipsTableFilterComposer(
              $db: $db,
              $table: $db.relationships,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> eventsRefs(
      Expression<bool> Function($$EventsTableFilterComposer f) f) {
    final $$EventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.personId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableFilterComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surname => $composableBuilder(
      column: $table.surname, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get givenName => $composableBuilder(
      column: $table.givenName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get courtesyName => $composableBuilder(
      column: $table.courtesyName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artName => $composableBuilder(
      column: $table.artName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get generation => $composableBuilder(
      column: $table.generation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get generationWord => $composableBuilder(
      column: $table.generationWord,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branch => $composableBuilder(
      column: $table.branch, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rank => $composableBuilder(
      column: $table.rank, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
      column: $table.birthDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deathDate => $composableBuilder(
      column: $table.deathDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAlive => $composableBuilder(
      column: $table.isAlive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get birthPlace => $composableBuilder(
      column: $table.birthPlace, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deathPlace => $composableBuilder(
      column: $table.deathPlace, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get burialPlace => $composableBuilder(
      column: $table.burialPlace, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get occupation => $composableBuilder(
      column: $table.occupation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get biography => $composableBuilder(
      column: $table.biography, builder: (column) => ColumnOrderings(column));

  $$FamilyTreesTableOrderingComposer get treeId {
    final $$FamilyTreesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treeId,
        referencedTable: $db.familyTrees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FamilyTreesTableOrderingComposer(
              $db: $db,
              $table: $db.familyTrees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MediaTableTableOrderingComposer get avatarMediaId {
    final $$MediaTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.avatarMediaId,
        referencedTable: $db.mediaTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MediaTableTableOrderingComposer(
              $db: $db,
              $table: $db.mediaTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surname =>
      $composableBuilder(column: $table.surname, builder: (column) => column);

  GeneratedColumn<String> get givenName =>
      $composableBuilder(column: $table.givenName, builder: (column) => column);

  GeneratedColumn<String> get courtesyName => $composableBuilder(
      column: $table.courtesyName, builder: (column) => column);

  GeneratedColumn<String> get artName =>
      $composableBuilder(column: $table.artName, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Gender, int> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get generation => $composableBuilder(
      column: $table.generation, builder: (column) => column);

  GeneratedColumn<String> get generationWord => $composableBuilder(
      column: $table.generationWord, builder: (column) => column);

  GeneratedColumn<String> get branch =>
      $composableBuilder(column: $table.branch, builder: (column) => column);

  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<DateTime> get deathDate =>
      $composableBuilder(column: $table.deathDate, builder: (column) => column);

  GeneratedColumn<bool> get isAlive =>
      $composableBuilder(column: $table.isAlive, builder: (column) => column);

  GeneratedColumn<String> get birthPlace => $composableBuilder(
      column: $table.birthPlace, builder: (column) => column);

  GeneratedColumn<String> get deathPlace => $composableBuilder(
      column: $table.deathPlace, builder: (column) => column);

  GeneratedColumn<String> get burialPlace => $composableBuilder(
      column: $table.burialPlace, builder: (column) => column);

  GeneratedColumn<String> get occupation => $composableBuilder(
      column: $table.occupation, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get biography =>
      $composableBuilder(column: $table.biography, builder: (column) => column);

  $$FamilyTreesTableAnnotationComposer get treeId {
    final $$FamilyTreesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treeId,
        referencedTable: $db.familyTrees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FamilyTreesTableAnnotationComposer(
              $db: $db,
              $table: $db.familyTrees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MediaTableTableAnnotationComposer get avatarMediaId {
    final $$MediaTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.avatarMediaId,
        referencedTable: $db.mediaTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MediaTableTableAnnotationComposer(
              $db: $db,
              $table: $db.mediaTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> from_relationships<T extends Object>(
      Expression<T> Function($$RelationshipsTableAnnotationComposer a) f) {
    final $$RelationshipsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.relationships,
        getReferencedColumn: (t) => t.fromPersonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RelationshipsTableAnnotationComposer(
              $db: $db,
              $table: $db.relationships,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> to_relationships<T extends Object>(
      Expression<T> Function($$RelationshipsTableAnnotationComposer a) f) {
    final $$RelationshipsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.relationships,
        getReferencedColumn: (t) => t.toPersonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RelationshipsTableAnnotationComposer(
              $db: $db,
              $table: $db.relationships,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> eventsRefs<T extends Object>(
      Expression<T> Function($$EventsTableAnnotationComposer a) f) {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.personId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableAnnotationComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PersonsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PersonsTable,
    Person,
    $$PersonsTableFilterComposer,
    $$PersonsTableOrderingComposer,
    $$PersonsTableAnnotationComposer,
    $$PersonsTableCreateCompanionBuilder,
    $$PersonsTableUpdateCompanionBuilder,
    (Person, $$PersonsTableReferences),
    Person,
    PrefetchHooks Function(
        {bool treeId,
        bool avatarMediaId,
        bool from_relationships,
        bool to_relationships,
        bool eventsRefs})> {
  $$PersonsTableTableManager(_$AppDatabase db, $PersonsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> treeId = const Value.absent(),
            Value<String> surname = const Value.absent(),
            Value<String> givenName = const Value.absent(),
            Value<String?> courtesyName = const Value.absent(),
            Value<String?> artName = const Value.absent(),
            Value<Gender> gender = const Value.absent(),
            Value<int?> generation = const Value.absent(),
            Value<String?> generationWord = const Value.absent(),
            Value<String?> branch = const Value.absent(),
            Value<int?> rank = const Value.absent(),
            Value<DateTime?> birthDate = const Value.absent(),
            Value<DateTime?> deathDate = const Value.absent(),
            Value<bool> isAlive = const Value.absent(),
            Value<String?> birthPlace = const Value.absent(),
            Value<String?> deathPlace = const Value.absent(),
            Value<String?> burialPlace = const Value.absent(),
            Value<String?> occupation = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> biography = const Value.absent(),
            Value<int?> avatarMediaId = const Value.absent(),
          }) =>
              PersonsCompanion(
            id: id,
            treeId: treeId,
            surname: surname,
            givenName: givenName,
            courtesyName: courtesyName,
            artName: artName,
            gender: gender,
            generation: generation,
            generationWord: generationWord,
            branch: branch,
            rank: rank,
            birthDate: birthDate,
            deathDate: deathDate,
            isAlive: isAlive,
            birthPlace: birthPlace,
            deathPlace: deathPlace,
            burialPlace: burialPlace,
            occupation: occupation,
            title: title,
            biography: biography,
            avatarMediaId: avatarMediaId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int treeId,
            required String surname,
            required String givenName,
            Value<String?> courtesyName = const Value.absent(),
            Value<String?> artName = const Value.absent(),
            required Gender gender,
            Value<int?> generation = const Value.absent(),
            Value<String?> generationWord = const Value.absent(),
            Value<String?> branch = const Value.absent(),
            Value<int?> rank = const Value.absent(),
            Value<DateTime?> birthDate = const Value.absent(),
            Value<DateTime?> deathDate = const Value.absent(),
            Value<bool> isAlive = const Value.absent(),
            Value<String?> birthPlace = const Value.absent(),
            Value<String?> deathPlace = const Value.absent(),
            Value<String?> burialPlace = const Value.absent(),
            Value<String?> occupation = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> biography = const Value.absent(),
            Value<int?> avatarMediaId = const Value.absent(),
          }) =>
              PersonsCompanion.insert(
            id: id,
            treeId: treeId,
            surname: surname,
            givenName: givenName,
            courtesyName: courtesyName,
            artName: artName,
            gender: gender,
            generation: generation,
            generationWord: generationWord,
            branch: branch,
            rank: rank,
            birthDate: birthDate,
            deathDate: deathDate,
            isAlive: isAlive,
            birthPlace: birthPlace,
            deathPlace: deathPlace,
            burialPlace: burialPlace,
            occupation: occupation,
            title: title,
            biography: biography,
            avatarMediaId: avatarMediaId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PersonsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {treeId = false,
              avatarMediaId = false,
              from_relationships = false,
              to_relationships = false,
              eventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (from_relationships) db.relationships,
                if (to_relationships) db.relationships,
                if (eventsRefs) db.events
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (treeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.treeId,
                    referencedTable: $$PersonsTableReferences._treeIdTable(db),
                    referencedColumn:
                        $$PersonsTableReferences._treeIdTable(db).id,
                  ) as T;
                }
                if (avatarMediaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.avatarMediaId,
                    referencedTable:
                        $$PersonsTableReferences._avatarMediaIdTable(db),
                    referencedColumn:
                        $$PersonsTableReferences._avatarMediaIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (from_relationships)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$PersonsTableReferences
                            ._from_relationshipsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PersonsTableReferences(db, table, p0)
                                .from_relationships,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.fromPersonId == item.id),
                        typedResults: items),
                  if (to_relationships)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$PersonsTableReferences._to_relationshipsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PersonsTableReferences(db, table, p0)
                                .to_relationships,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.toPersonId == item.id),
                        typedResults: items),
                  if (eventsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$PersonsTableReferences._eventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PersonsTableReferences(db, table, p0).eventsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.personId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PersonsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PersonsTable,
    Person,
    $$PersonsTableFilterComposer,
    $$PersonsTableOrderingComposer,
    $$PersonsTableAnnotationComposer,
    $$PersonsTableCreateCompanionBuilder,
    $$PersonsTableUpdateCompanionBuilder,
    (Person, $$PersonsTableReferences),
    Person,
    PrefetchHooks Function(
        {bool treeId,
        bool avatarMediaId,
        bool from_relationships,
        bool to_relationships,
        bool eventsRefs})>;
typedef $$RelationshipsTableCreateCompanionBuilder = RelationshipsCompanion
    Function({
  Value<int> id,
  required int treeId,
  required int fromPersonId,
  required int toPersonId,
  required RelationType type,
  Value<DateTime?> startDate,
  Value<DateTime?> endDate,
  Value<String?> note,
});
typedef $$RelationshipsTableUpdateCompanionBuilder = RelationshipsCompanion
    Function({
  Value<int> id,
  Value<int> treeId,
  Value<int> fromPersonId,
  Value<int> toPersonId,
  Value<RelationType> type,
  Value<DateTime?> startDate,
  Value<DateTime?> endDate,
  Value<String?> note,
});

final class $$RelationshipsTableReferences
    extends BaseReferences<_$AppDatabase, $RelationshipsTable, Relationship> {
  $$RelationshipsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $FamilyTreesTable _treeIdTable(_$AppDatabase db) =>
      db.familyTrees.createAlias(
          $_aliasNameGenerator(db.relationships.treeId, db.familyTrees.id));

  $$FamilyTreesTableProcessedTableManager get treeId {
    final manager = $$FamilyTreesTableTableManager($_db, $_db.familyTrees)
        .filter((f) => f.id($_item.treeId));
    final item = $_typedResult.readTableOrNull(_treeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PersonsTable _fromPersonIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
          $_aliasNameGenerator(db.relationships.fromPersonId, db.persons.id));

  $$PersonsTableProcessedTableManager get fromPersonId {
    final manager = $$PersonsTableTableManager($_db, $_db.persons)
        .filter((f) => f.id($_item.fromPersonId));
    final item = $_typedResult.readTableOrNull(_fromPersonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PersonsTable _toPersonIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
          $_aliasNameGenerator(db.relationships.toPersonId, db.persons.id));

  $$PersonsTableProcessedTableManager get toPersonId {
    final manager = $$PersonsTableTableManager($_db, $_db.persons)
        .filter((f) => f.id($_item.toPersonId));
    final item = $_typedResult.readTableOrNull(_toPersonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RelationshipsTableFilterComposer
    extends Composer<_$AppDatabase, $RelationshipsTable> {
  $$RelationshipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<RelationType, RelationType, String> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$FamilyTreesTableFilterComposer get treeId {
    final $$FamilyTreesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treeId,
        referencedTable: $db.familyTrees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FamilyTreesTableFilterComposer(
              $db: $db,
              $table: $db.familyTrees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PersonsTableFilterComposer get fromPersonId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromPersonId,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableFilterComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PersonsTableFilterComposer get toPersonId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toPersonId,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableFilterComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RelationshipsTableOrderingComposer
    extends Composer<_$AppDatabase, $RelationshipsTable> {
  $$RelationshipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$FamilyTreesTableOrderingComposer get treeId {
    final $$FamilyTreesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treeId,
        referencedTable: $db.familyTrees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FamilyTreesTableOrderingComposer(
              $db: $db,
              $table: $db.familyTrees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PersonsTableOrderingComposer get fromPersonId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromPersonId,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableOrderingComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PersonsTableOrderingComposer get toPersonId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toPersonId,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableOrderingComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RelationshipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RelationshipsTable> {
  $$RelationshipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RelationType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$FamilyTreesTableAnnotationComposer get treeId {
    final $$FamilyTreesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treeId,
        referencedTable: $db.familyTrees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FamilyTreesTableAnnotationComposer(
              $db: $db,
              $table: $db.familyTrees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PersonsTableAnnotationComposer get fromPersonId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromPersonId,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableAnnotationComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PersonsTableAnnotationComposer get toPersonId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toPersonId,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableAnnotationComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RelationshipsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RelationshipsTable,
    Relationship,
    $$RelationshipsTableFilterComposer,
    $$RelationshipsTableOrderingComposer,
    $$RelationshipsTableAnnotationComposer,
    $$RelationshipsTableCreateCompanionBuilder,
    $$RelationshipsTableUpdateCompanionBuilder,
    (Relationship, $$RelationshipsTableReferences),
    Relationship,
    PrefetchHooks Function({bool treeId, bool fromPersonId, bool toPersonId})> {
  $$RelationshipsTableTableManager(_$AppDatabase db, $RelationshipsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelationshipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RelationshipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RelationshipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> treeId = const Value.absent(),
            Value<int> fromPersonId = const Value.absent(),
            Value<int> toPersonId = const Value.absent(),
            Value<RelationType> type = const Value.absent(),
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) =>
              RelationshipsCompanion(
            id: id,
            treeId: treeId,
            fromPersonId: fromPersonId,
            toPersonId: toPersonId,
            type: type,
            startDate: startDate,
            endDate: endDate,
            note: note,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int treeId,
            required int fromPersonId,
            required int toPersonId,
            required RelationType type,
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) =>
              RelationshipsCompanion.insert(
            id: id,
            treeId: treeId,
            fromPersonId: fromPersonId,
            toPersonId: toPersonId,
            type: type,
            startDate: startDate,
            endDate: endDate,
            note: note,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RelationshipsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {treeId = false, fromPersonId = false, toPersonId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (treeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.treeId,
                    referencedTable:
                        $$RelationshipsTableReferences._treeIdTable(db),
                    referencedColumn:
                        $$RelationshipsTableReferences._treeIdTable(db).id,
                  ) as T;
                }
                if (fromPersonId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fromPersonId,
                    referencedTable:
                        $$RelationshipsTableReferences._fromPersonIdTable(db),
                    referencedColumn: $$RelationshipsTableReferences
                        ._fromPersonIdTable(db)
                        .id,
                  ) as T;
                }
                if (toPersonId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.toPersonId,
                    referencedTable:
                        $$RelationshipsTableReferences._toPersonIdTable(db),
                    referencedColumn:
                        $$RelationshipsTableReferences._toPersonIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RelationshipsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RelationshipsTable,
    Relationship,
    $$RelationshipsTableFilterComposer,
    $$RelationshipsTableOrderingComposer,
    $$RelationshipsTableAnnotationComposer,
    $$RelationshipsTableCreateCompanionBuilder,
    $$RelationshipsTableUpdateCompanionBuilder,
    (Relationship, $$RelationshipsTableReferences),
    Relationship,
    PrefetchHooks Function({bool treeId, bool fromPersonId, bool toPersonId})>;
typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  Value<int?> personId,
  required int treeId,
  required EventType type,
  required String title,
  Value<DateTime?> date,
  Value<String?> place,
  Value<String?> description,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  Value<int?> personId,
  Value<int> treeId,
  Value<EventType> type,
  Value<String> title,
  Value<DateTime?> date,
  Value<String?> place,
  Value<String?> description,
});

final class $$EventsTableReferences
    extends BaseReferences<_$AppDatabase, $EventsTable, Event> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PersonsTable _personIdTable(_$AppDatabase db) => db.persons
      .createAlias($_aliasNameGenerator(db.events.personId, db.persons.id));

  $$PersonsTableProcessedTableManager? get personId {
    if ($_item.personId == null) return null;
    final manager = $$PersonsTableTableManager($_db, $_db.persons)
        .filter((f) => f.id($_item.personId!));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $FamilyTreesTable _treeIdTable(_$AppDatabase db) => db.familyTrees
      .createAlias($_aliasNameGenerator(db.events.treeId, db.familyTrees.id));

  $$FamilyTreesTableProcessedTableManager get treeId {
    final manager = $$FamilyTreesTableTableManager($_db, $_db.familyTrees)
        .filter((f) => f.id($_item.treeId));
    final item = $_typedResult.readTableOrNull(_treeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<EventType, EventType, String> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get place => $composableBuilder(
      column: $table.place, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableFilterComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FamilyTreesTableFilterComposer get treeId {
    final $$FamilyTreesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treeId,
        referencedTable: $db.familyTrees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FamilyTreesTableFilterComposer(
              $db: $db,
              $table: $db.familyTrees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get place => $composableBuilder(
      column: $table.place, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableOrderingComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FamilyTreesTableOrderingComposer get treeId {
    final $$FamilyTreesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treeId,
        referencedTable: $db.familyTrees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FamilyTreesTableOrderingComposer(
              $db: $db,
              $table: $db.familyTrees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EventType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get place =>
      $composableBuilder(column: $table.place, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.personId,
        referencedTable: $db.persons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PersonsTableAnnotationComposer(
              $db: $db,
              $table: $db.persons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FamilyTreesTableAnnotationComposer get treeId {
    final $$FamilyTreesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treeId,
        referencedTable: $db.familyTrees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FamilyTreesTableAnnotationComposer(
              $db: $db,
              $table: $db.familyTrees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, $$EventsTableReferences),
    Event,
    PrefetchHooks Function({bool personId, bool treeId})> {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> personId = const Value.absent(),
            Value<int> treeId = const Value.absent(),
            Value<EventType> type = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<DateTime?> date = const Value.absent(),
            Value<String?> place = const Value.absent(),
            Value<String?> description = const Value.absent(),
          }) =>
              EventsCompanion(
            id: id,
            personId: personId,
            treeId: treeId,
            type: type,
            title: title,
            date: date,
            place: place,
            description: description,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> personId = const Value.absent(),
            required int treeId,
            required EventType type,
            required String title,
            Value<DateTime?> date = const Value.absent(),
            Value<String?> place = const Value.absent(),
            Value<String?> description = const Value.absent(),
          }) =>
              EventsCompanion.insert(
            id: id,
            personId: personId,
            treeId: treeId,
            type: type,
            title: title,
            date: date,
            place: place,
            description: description,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$EventsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({personId = false, treeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (personId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.personId,
                    referencedTable: $$EventsTableReferences._personIdTable(db),
                    referencedColumn:
                        $$EventsTableReferences._personIdTable(db).id,
                  ) as T;
                }
                if (treeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.treeId,
                    referencedTable: $$EventsTableReferences._treeIdTable(db),
                    referencedColumn:
                        $$EventsTableReferences._treeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$EventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, $$EventsTableReferences),
    Event,
    PrefetchHooks Function({bool personId, bool treeId})>;
typedef $$PlacesTableCreateCompanionBuilder = PlacesCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> address,
  Value<double?> latitude,
  Value<double?> longitude,
});
typedef $$PlacesTableUpdateCompanionBuilder = PlacesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> address,
  Value<double?> latitude,
  Value<double?> longitude,
});

class $$PlacesTableFilterComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));
}

class $$PlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));
}

class $$PlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableAnnotationComposer({
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

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);
}

class $$PlacesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlacesTable,
    Place,
    $$PlacesTableFilterComposer,
    $$PlacesTableOrderingComposer,
    $$PlacesTableAnnotationComposer,
    $$PlacesTableCreateCompanionBuilder,
    $$PlacesTableUpdateCompanionBuilder,
    (Place, BaseReferences<_$AppDatabase, $PlacesTable, Place>),
    Place,
    PrefetchHooks Function()> {
  $$PlacesTableTableManager(_$AppDatabase db, $PlacesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
          }) =>
              PlacesCompanion(
            id: id,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> address = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
          }) =>
              PlacesCompanion.insert(
            id: id,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlacesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlacesTable,
    Place,
    $$PlacesTableFilterComposer,
    $$PlacesTableOrderingComposer,
    $$PlacesTableAnnotationComposer,
    $$PlacesTableCreateCompanionBuilder,
    $$PlacesTableUpdateCompanionBuilder,
    (Place, BaseReferences<_$AppDatabase, $PlacesTable, Place>),
    Place,
    PrefetchHooks Function()>;
typedef $$SourcesTableCreateCompanionBuilder = SourcesCompanion Function({
  Value<int> id,
  required int treeId,
  required String title,
  Value<String?> url,
  Value<String?> note,
});
typedef $$SourcesTableUpdateCompanionBuilder = SourcesCompanion Function({
  Value<int> id,
  Value<int> treeId,
  Value<String> title,
  Value<String?> url,
  Value<String?> note,
});

final class $$SourcesTableReferences
    extends BaseReferences<_$AppDatabase, $SourcesTable, Source> {
  $$SourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FamilyTreesTable _treeIdTable(_$AppDatabase db) => db.familyTrees
      .createAlias($_aliasNameGenerator(db.sources.treeId, db.familyTrees.id));

  $$FamilyTreesTableProcessedTableManager get treeId {
    final manager = $$FamilyTreesTableTableManager($_db, $_db.familyTrees)
        .filter((f) => f.id($_item.treeId));
    final item = $_typedResult.readTableOrNull(_treeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SourcesTableFilterComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$FamilyTreesTableFilterComposer get treeId {
    final $$FamilyTreesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treeId,
        referencedTable: $db.familyTrees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FamilyTreesTableFilterComposer(
              $db: $db,
              $table: $db.familyTrees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$FamilyTreesTableOrderingComposer get treeId {
    final $$FamilyTreesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treeId,
        referencedTable: $db.familyTrees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FamilyTreesTableOrderingComposer(
              $db: $db,
              $table: $db.familyTrees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
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

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$FamilyTreesTableAnnotationComposer get treeId {
    final $$FamilyTreesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.treeId,
        referencedTable: $db.familyTrees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FamilyTreesTableAnnotationComposer(
              $db: $db,
              $table: $db.familyTrees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SourcesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SourcesTable,
    Source,
    $$SourcesTableFilterComposer,
    $$SourcesTableOrderingComposer,
    $$SourcesTableAnnotationComposer,
    $$SourcesTableCreateCompanionBuilder,
    $$SourcesTableUpdateCompanionBuilder,
    (Source, $$SourcesTableReferences),
    Source,
    PrefetchHooks Function({bool treeId})> {
  $$SourcesTableTableManager(_$AppDatabase db, $SourcesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> treeId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) =>
              SourcesCompanion(
            id: id,
            treeId: treeId,
            title: title,
            url: url,
            note: note,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int treeId,
            required String title,
            Value<String?> url = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) =>
              SourcesCompanion.insert(
            id: id,
            treeId: treeId,
            title: title,
            url: url,
            note: note,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SourcesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({treeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (treeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.treeId,
                    referencedTable: $$SourcesTableReferences._treeIdTable(db),
                    referencedColumn:
                        $$SourcesTableReferences._treeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SourcesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SourcesTable,
    Source,
    $$SourcesTableFilterComposer,
    $$SourcesTableOrderingComposer,
    $$SourcesTableAnnotationComposer,
    $$SourcesTableCreateCompanionBuilder,
    $$SourcesTableUpdateCompanionBuilder,
    (Source, $$SourcesTableReferences),
    Source,
    PrefetchHooks Function({bool treeId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FamilyTreesTableTableManager get familyTrees =>
      $$FamilyTreesTableTableManager(_db, _db.familyTrees);
  $$MediaTableTableTableManager get mediaTable =>
      $$MediaTableTableTableManager(_db, _db.mediaTable);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db, _db.persons);
  $$RelationshipsTableTableManager get relationships =>
      $$RelationshipsTableTableManager(_db, _db.relationships);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$PlacesTableTableManager get places =>
      $$PlacesTableTableManager(_db, _db.places);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
}
