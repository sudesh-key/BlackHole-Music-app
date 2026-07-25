// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KeyValueEntriesTable extends KeyValueEntries
    with TableInfo<$KeyValueEntriesTable, KeyValueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _boxMeta = const VerificationMeta('box');
  @override
  late final GeneratedColumn<String> box = GeneratedColumn<String>(
    'box',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  @override
  List<GeneratedColumn> get $columns => [box, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_value_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('box')) {
      context.handle(
        _boxMeta,
        box.isAcceptableOrUnknown(data['box']!, _boxMeta),
      );
    } else if (isInserting) {
      context.missing(_boxMeta);
    }
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {box, key};
  @override
  KeyValueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueEntry(
      box: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}box'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValueEntriesTable createAlias(String alias) {
    return $KeyValueEntriesTable(attachedDatabase, alias);
  }
}

class KeyValueEntry extends DataClass implements Insertable<KeyValueEntry> {
  final String box;
  final String key;
  final String value;
  const KeyValueEntry({
    required this.box,
    required this.key,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['box'] = Variable<String>(box);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValueEntriesCompanion toCompanion(bool nullToAbsent) {
    return KeyValueEntriesCompanion(
      box: Value(box),
      key: Value(key),
      value: Value(value),
    );
  }

  factory KeyValueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueEntry(
      box: serializer.fromJson<String>(json['box']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'box': serializer.toJson<String>(box),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValueEntry copyWith({String? box, String? key, String? value}) =>
      KeyValueEntry(
        box: box ?? this.box,
        key: key ?? this.key,
        value: value ?? this.value,
      );
  KeyValueEntry copyWithCompanion(KeyValueEntriesCompanion data) {
    return KeyValueEntry(
      box: data.box.present ? data.box.value : this.box,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueEntry(')
          ..write('box: $box, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(box, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValueEntry &&
          other.box == this.box &&
          other.key == this.key &&
          other.value == this.value);
}

class KeyValueEntriesCompanion extends UpdateCompanion<KeyValueEntry> {
  final Value<String> box;
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValueEntriesCompanion({
    this.box = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValueEntriesCompanion.insert({
    required String box,
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : box = Value(box),
       key = Value(key),
       value = Value(value);
  static Insertable<KeyValueEntry> custom({
    Expression<String>? box,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (box != null) 'box': box,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValueEntriesCompanion copyWith({
    Value<String>? box,
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValueEntriesCompanion(
      box: box ?? this.box,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (box.present) {
      map['box'] = Variable<String>(box.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueEntriesCompanion(')
          ..write('box: $box, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoxRegistryTable extends BoxRegistry
    with TableInfo<$BoxRegistryTable, BoxRegistryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoxRegistryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'box_registry';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoxRegistryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  BoxRegistryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoxRegistryEntry(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $BoxRegistryTable createAlias(String alias) {
    return $BoxRegistryTable(attachedDatabase, alias);
  }
}

class BoxRegistryEntry extends DataClass
    implements Insertable<BoxRegistryEntry> {
  final String name;
  const BoxRegistryEntry({required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    return map;
  }

  BoxRegistryCompanion toCompanion(bool nullToAbsent) {
    return BoxRegistryCompanion(name: Value(name));
  }

  factory BoxRegistryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoxRegistryEntry(name: serializer.fromJson<String>(json['name']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'name': serializer.toJson<String>(name)};
  }

  BoxRegistryEntry copyWith({String? name}) =>
      BoxRegistryEntry(name: name ?? this.name);
  BoxRegistryEntry copyWithCompanion(BoxRegistryCompanion data) {
    return BoxRegistryEntry(
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoxRegistryEntry(')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => name.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoxRegistryEntry && other.name == this.name);
}

class BoxRegistryCompanion extends UpdateCompanion<BoxRegistryEntry> {
  final Value<String> name;
  final Value<int> rowid;
  const BoxRegistryCompanion({
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoxRegistryCompanion.insert({
    required String name,
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<BoxRegistryEntry> custom({
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoxRegistryCompanion copyWith({Value<String>? name, Value<int>? rowid}) {
    return BoxRegistryCompanion(
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoxRegistryCompanion(')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KeyValueEntriesTable keyValueEntries = $KeyValueEntriesTable(
    this,
  );
  late final $BoxRegistryTable boxRegistry = $BoxRegistryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    keyValueEntries,
    boxRegistry,
  ];
}

typedef $$KeyValueEntriesTableCreateCompanionBuilder =
    KeyValueEntriesCompanion Function({
      required String box,
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$KeyValueEntriesTableUpdateCompanionBuilder =
    KeyValueEntriesCompanion Function({
      Value<String> box,
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$KeyValueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValueEntriesTable> {
  $$KeyValueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValueEntriesTable> {
  $$KeyValueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValueEntriesTable> {
  $$KeyValueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get box =>
      $composableBuilder(column: $table.box, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValueEntriesTable,
          KeyValueEntry,
          $$KeyValueEntriesTableFilterComposer,
          $$KeyValueEntriesTableOrderingComposer,
          $$KeyValueEntriesTableAnnotationComposer,
          $$KeyValueEntriesTableCreateCompanionBuilder,
          $$KeyValueEntriesTableUpdateCompanionBuilder,
          (
            KeyValueEntry,
            BaseReferences<_$AppDatabase, $KeyValueEntriesTable, KeyValueEntry>,
          ),
          KeyValueEntry,
          PrefetchHooks Function()
        > {
  $$KeyValueEntriesTableTableManager(
    _$AppDatabase db,
    $KeyValueEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValueEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> box = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValueEntriesCompanion(
                box: box,
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String box,
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => KeyValueEntriesCompanion.insert(
                box: box,
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValueEntriesTable,
      KeyValueEntry,
      $$KeyValueEntriesTableFilterComposer,
      $$KeyValueEntriesTableOrderingComposer,
      $$KeyValueEntriesTableAnnotationComposer,
      $$KeyValueEntriesTableCreateCompanionBuilder,
      $$KeyValueEntriesTableUpdateCompanionBuilder,
      (
        KeyValueEntry,
        BaseReferences<_$AppDatabase, $KeyValueEntriesTable, KeyValueEntry>,
      ),
      KeyValueEntry,
      PrefetchHooks Function()
    >;
typedef $$BoxRegistryTableCreateCompanionBuilder =
    BoxRegistryCompanion Function({required String name, Value<int> rowid});
typedef $$BoxRegistryTableUpdateCompanionBuilder =
    BoxRegistryCompanion Function({Value<String> name, Value<int> rowid});

class $$BoxRegistryTableFilterComposer
    extends Composer<_$AppDatabase, $BoxRegistryTable> {
  $$BoxRegistryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoxRegistryTableOrderingComposer
    extends Composer<_$AppDatabase, $BoxRegistryTable> {
  $$BoxRegistryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoxRegistryTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoxRegistryTable> {
  $$BoxRegistryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$BoxRegistryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoxRegistryTable,
          BoxRegistryEntry,
          $$BoxRegistryTableFilterComposer,
          $$BoxRegistryTableOrderingComposer,
          $$BoxRegistryTableAnnotationComposer,
          $$BoxRegistryTableCreateCompanionBuilder,
          $$BoxRegistryTableUpdateCompanionBuilder,
          (
            BoxRegistryEntry,
            BaseReferences<_$AppDatabase, $BoxRegistryTable, BoxRegistryEntry>,
          ),
          BoxRegistryEntry,
          PrefetchHooks Function()
        > {
  $$BoxRegistryTableTableManager(_$AppDatabase db, $BoxRegistryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoxRegistryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoxRegistryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoxRegistryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoxRegistryCompanion(name: name, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => BoxRegistryCompanion.insert(name: name, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoxRegistryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoxRegistryTable,
      BoxRegistryEntry,
      $$BoxRegistryTableFilterComposer,
      $$BoxRegistryTableOrderingComposer,
      $$BoxRegistryTableAnnotationComposer,
      $$BoxRegistryTableCreateCompanionBuilder,
      $$BoxRegistryTableUpdateCompanionBuilder,
      (
        BoxRegistryEntry,
        BaseReferences<_$AppDatabase, $BoxRegistryTable, BoxRegistryEntry>,
      ),
      BoxRegistryEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KeyValueEntriesTableTableManager get keyValueEntries =>
      $$KeyValueEntriesTableTableManager(_db, _db.keyValueEntries);
  $$BoxRegistryTableTableManager get boxRegistry =>
      $$BoxRegistryTableTableManager(_db, _db.boxRegistry);
}
