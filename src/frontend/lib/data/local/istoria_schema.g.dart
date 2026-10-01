// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'istoria_schema.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIstoriaKlinisCollection on Isar {
  IsarCollection<IstoriaKlinis> get istoriaKlinis => this.collection();
}

const IstoriaKlinisSchema = CollectionSchema(
  name: r'IstoriaKlinis_10267',
  id: 734954230837104,
  properties: {
    r'analisisAsesmen': PropertySchema(
      id: 0,
      name: r'analisisAsesmen',
      type: IsarType.string,
    ),
    r'keluhanSubjektif': PropertySchema(
      id: 1,
      name: r'keluhanSubjektif',
      type: IsarType.string,
    ),
    r'kodeIcd10': PropertySchema(
      id: 2,
      name: r'kodeIcd10',
      type: IsarType.string,
    ),
    r'namaPenyakitLokal': PropertySchema(
      id: 3,
      name: r'namaPenyakitLokal',
      type: IsarType.string,
    ),
    r'pasienId': PropertySchema(
      id: 4,
      name: r'pasienId',
      type: IsarType.string,
    ),
    r'pemeriksaanObjektif': PropertySchema(
      id: 5,
      name: r'pemeriksaanObjektif',
      type: IsarType.string,
    ),
    r'remoteId': PropertySchema(
      id: 6,
      name: r'remoteId',
      type: IsarType.string,
    ),
    r'rencanaTindakan': PropertySchema(
      id: 7,
      name: r'rencanaTindakan',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 8,
      name: r'syncStatus',
      type: IsarType.string,
    ),
    r'tanggalKunjungan': PropertySchema(
      id: 9,
      name: r'tanggalKunjungan',
      type: IsarType.dateTime,
    ),
    r'tenantId': PropertySchema(
      id: 10,
      name: r'tenantId',
      type: IsarType.string,
    )
  },
  estimateSize: _istoriaKlinisEstimateSize,
  serialize: _istoriaKlinisSerialize,
  deserialize: _istoriaKlinisDeserialize,
  deserializeProp: _istoriaKlinisDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _istoriaKlinisGetId,
  getLinks: _istoriaKlinisGetLinks,
  attach: _istoriaKlinisAttach,
  version: '3.1.0+1',
);

int _istoriaKlinisEstimateSize(
  IstoriaKlinis object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.analisisAsesmen.length * 3;
  bytesCount += 3 + object.keluhanSubjektif.length * 3;
  bytesCount += 3 + object.kodeIcd10.length * 3;
  bytesCount += 3 + object.namaPenyakitLokal.length * 3;
  bytesCount += 3 + object.pasienId.length * 3;
  bytesCount += 3 + object.pemeriksaanObjektif.length * 3;
  {
    final value = object.remoteId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.rencanaTindakan.length * 3;
  bytesCount += 3 + object.syncStatus.length * 3;
  bytesCount += 3 + object.tenantId.length * 3;
  return bytesCount;
}

void _istoriaKlinisSerialize(
  IstoriaKlinis object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.analisisAsesmen);
  writer.writeString(offsets[1], object.keluhanSubjektif);
  writer.writeString(offsets[2], object.kodeIcd10);
  writer.writeString(offsets[3], object.namaPenyakitLokal);
  writer.writeString(offsets[4], object.pasienId);
  writer.writeString(offsets[5], object.pemeriksaanObjektif);
  writer.writeString(offsets[6], object.remoteId);
  writer.writeString(offsets[7], object.rencanaTindakan);
  writer.writeString(offsets[8], object.syncStatus);
  writer.writeDateTime(offsets[9], object.tanggalKunjungan);
  writer.writeString(offsets[10], object.tenantId);
}

IstoriaKlinis _istoriaKlinisDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IstoriaKlinis();
  object.analisisAsesmen = reader.readString(offsets[0]);
  object.id = id;
  object.keluhanSubjektif = reader.readString(offsets[1]);
  object.kodeIcd10 = reader.readString(offsets[2]);
  object.namaPenyakitLokal = reader.readString(offsets[3]);
  object.pasienId = reader.readString(offsets[4]);
  object.pemeriksaanObjektif = reader.readString(offsets[5]);
  object.remoteId = reader.readStringOrNull(offsets[6]);
  object.rencanaTindakan = reader.readString(offsets[7]);
  object.syncStatus = reader.readString(offsets[8]);
  object.tanggalKunjungan = reader.readDateTimeOrNull(offsets[9]);
  object.tenantId = reader.readString(offsets[10]);
  return object;
}

P _istoriaKlinisDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _istoriaKlinisGetId(IstoriaKlinis object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _istoriaKlinisGetLinks(IstoriaKlinis object) {
  return [];
}

void _istoriaKlinisAttach(
    IsarCollection<dynamic> col, Id id, IstoriaKlinis object) {
  object.id = id;
}

extension IstoriaKlinisQueryWhereSort
    on QueryBuilder<IstoriaKlinis, IstoriaKlinis, QWhere> {
  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IstoriaKlinisQueryWhere
    on QueryBuilder<IstoriaKlinis, IstoriaKlinis, QWhereClause> {
  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IstoriaKlinisQueryFilter
    on QueryBuilder<IstoriaKlinis, IstoriaKlinis, QFilterCondition> {
  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      analisisAsesmenEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'analisisAsesmen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      analisisAsesmenGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'analisisAsesmen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      analisisAsesmenLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'analisisAsesmen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      analisisAsesmenBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'analisisAsesmen',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      analisisAsesmenStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'analisisAsesmen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      analisisAsesmenEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'analisisAsesmen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      analisisAsesmenContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'analisisAsesmen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      analisisAsesmenMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'analisisAsesmen',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      analisisAsesmenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'analisisAsesmen',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      analisisAsesmenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'analisisAsesmen',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      keluhanSubjektifEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keluhanSubjektif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      keluhanSubjektifGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'keluhanSubjektif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      keluhanSubjektifLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'keluhanSubjektif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      keluhanSubjektifBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'keluhanSubjektif',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      keluhanSubjektifStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'keluhanSubjektif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      keluhanSubjektifEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'keluhanSubjektif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      keluhanSubjektifContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'keluhanSubjektif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      keluhanSubjektifMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'keluhanSubjektif',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      keluhanSubjektifIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keluhanSubjektif',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      keluhanSubjektifIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'keluhanSubjektif',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      kodeIcd10EqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kodeIcd10',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      kodeIcd10GreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kodeIcd10',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      kodeIcd10LessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kodeIcd10',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      kodeIcd10Between(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kodeIcd10',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      kodeIcd10StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kodeIcd10',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      kodeIcd10EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kodeIcd10',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      kodeIcd10Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kodeIcd10',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      kodeIcd10Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kodeIcd10',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      kodeIcd10IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kodeIcd10',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      kodeIcd10IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kodeIcd10',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      namaPenyakitLokalEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaPenyakitLokal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      namaPenyakitLokalGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'namaPenyakitLokal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      namaPenyakitLokalLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'namaPenyakitLokal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      namaPenyakitLokalBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'namaPenyakitLokal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      namaPenyakitLokalStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'namaPenyakitLokal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      namaPenyakitLokalEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'namaPenyakitLokal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      namaPenyakitLokalContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namaPenyakitLokal',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      namaPenyakitLokalMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namaPenyakitLokal',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      namaPenyakitLokalIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaPenyakitLokal',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      namaPenyakitLokalIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namaPenyakitLokal',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pasienIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pasienId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pasienIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pasienId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pasienIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pasienId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pasienIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pasienId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pasienIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pasienId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pasienIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pasienId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pasienIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pasienId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pasienIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pasienId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pasienIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pasienId',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pasienIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pasienId',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pemeriksaanObjektifEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pemeriksaanObjektif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pemeriksaanObjektifGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pemeriksaanObjektif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pemeriksaanObjektifLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pemeriksaanObjektif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pemeriksaanObjektifBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pemeriksaanObjektif',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pemeriksaanObjektifStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pemeriksaanObjektif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pemeriksaanObjektifEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pemeriksaanObjektif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pemeriksaanObjektifContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pemeriksaanObjektif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pemeriksaanObjektifMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pemeriksaanObjektif',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pemeriksaanObjektifIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pemeriksaanObjektif',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      pemeriksaanObjektifIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pemeriksaanObjektif',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      remoteIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      remoteIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      remoteIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      remoteIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      remoteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      remoteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      remoteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      remoteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remoteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      remoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      remoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      rencanaTindakanEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rencanaTindakan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      rencanaTindakanGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rencanaTindakan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      rencanaTindakanLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rencanaTindakan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      rencanaTindakanBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rencanaTindakan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      rencanaTindakanStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rencanaTindakan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      rencanaTindakanEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rencanaTindakan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      rencanaTindakanContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rencanaTindakan',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      rencanaTindakanMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rencanaTindakan',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      rencanaTindakanIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rencanaTindakan',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      rencanaTindakanIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rencanaTindakan',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      syncStatusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      syncStatusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      syncStatusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      syncStatusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      syncStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      syncStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      syncStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      syncStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      syncStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      syncStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tanggalKunjunganIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tanggalKunjungan',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tanggalKunjunganIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tanggalKunjungan',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tanggalKunjunganEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tanggalKunjungan',
        value: value,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tanggalKunjunganGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tanggalKunjungan',
        value: value,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tanggalKunjunganLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tanggalKunjungan',
        value: value,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tanggalKunjunganBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tanggalKunjungan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tenantIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tenantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tenantIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tenantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tenantIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tenantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tenantIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tenantId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tenantIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tenantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tenantIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tenantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tenantIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tenantId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tenantIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tenantId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tenantIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tenantId',
        value: '',
      ));
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterFilterCondition>
      tenantIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tenantId',
        value: '',
      ));
    });
  }
}

extension IstoriaKlinisQueryObject
    on QueryBuilder<IstoriaKlinis, IstoriaKlinis, QFilterCondition> {}

extension IstoriaKlinisQueryLinks
    on QueryBuilder<IstoriaKlinis, IstoriaKlinis, QFilterCondition> {}

extension IstoriaKlinisQuerySortBy
    on QueryBuilder<IstoriaKlinis, IstoriaKlinis, QSortBy> {
  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByAnalisisAsesmen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analisisAsesmen', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByAnalisisAsesmenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analisisAsesmen', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByKeluhanSubjektif() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keluhanSubjektif', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByKeluhanSubjektifDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keluhanSubjektif', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy> sortByKodeIcd10() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kodeIcd10', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByKodeIcd10Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kodeIcd10', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByNamaPenyakitLokal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namaPenyakitLokal', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByNamaPenyakitLokalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namaPenyakitLokal', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy> sortByPasienId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pasienId', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByPasienIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pasienId', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByPemeriksaanObjektif() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pemeriksaanObjektif', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByPemeriksaanObjektifDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pemeriksaanObjektif', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByRencanaTindakan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rencanaTindakan', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByRencanaTindakanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rencanaTindakan', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByTanggalKunjungan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tanggalKunjungan', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByTanggalKunjunganDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tanggalKunjungan', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy> sortByTenantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tenantId', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      sortByTenantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tenantId', Sort.desc);
    });
  }
}

extension IstoriaKlinisQuerySortThenBy
    on QueryBuilder<IstoriaKlinis, IstoriaKlinis, QSortThenBy> {
  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByAnalisisAsesmen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analisisAsesmen', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByAnalisisAsesmenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analisisAsesmen', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByKeluhanSubjektif() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keluhanSubjektif', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByKeluhanSubjektifDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keluhanSubjektif', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy> thenByKodeIcd10() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kodeIcd10', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByKodeIcd10Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kodeIcd10', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByNamaPenyakitLokal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namaPenyakitLokal', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByNamaPenyakitLokalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namaPenyakitLokal', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy> thenByPasienId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pasienId', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByPasienIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pasienId', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByPemeriksaanObjektif() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pemeriksaanObjektif', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByPemeriksaanObjektifDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pemeriksaanObjektif', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByRencanaTindakan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rencanaTindakan', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByRencanaTindakanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rencanaTindakan', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByTanggalKunjungan() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tanggalKunjungan', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByTanggalKunjunganDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tanggalKunjungan', Sort.desc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy> thenByTenantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tenantId', Sort.asc);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QAfterSortBy>
      thenByTenantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tenantId', Sort.desc);
    });
  }
}

extension IstoriaKlinisQueryWhereDistinct
    on QueryBuilder<IstoriaKlinis, IstoriaKlinis, QDistinct> {
  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QDistinct>
      distinctByAnalisisAsesmen({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'analisisAsesmen',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QDistinct>
      distinctByKeluhanSubjektif({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keluhanSubjektif',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QDistinct> distinctByKodeIcd10(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kodeIcd10', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QDistinct>
      distinctByNamaPenyakitLokal({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'namaPenyakitLokal',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QDistinct> distinctByPasienId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pasienId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QDistinct>
      distinctByPemeriksaanObjektif({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pemeriksaanObjektif',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QDistinct> distinctByRemoteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QDistinct>
      distinctByRencanaTindakan({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rencanaTindakan',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QDistinct> distinctBySyncStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QDistinct>
      distinctByTanggalKunjungan() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tanggalKunjungan');
    });
  }

  QueryBuilder<IstoriaKlinis, IstoriaKlinis, QDistinct> distinctByTenantId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tenantId', caseSensitive: caseSensitive);
    });
  }
}

extension IstoriaKlinisQueryProperty
    on QueryBuilder<IstoriaKlinis, IstoriaKlinis, QQueryProperty> {
  QueryBuilder<IstoriaKlinis, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IstoriaKlinis, String, QQueryOperations>
      analisisAsesmenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'analisisAsesmen');
    });
  }

  QueryBuilder<IstoriaKlinis, String, QQueryOperations>
      keluhanSubjektifProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keluhanSubjektif');
    });
  }

  QueryBuilder<IstoriaKlinis, String, QQueryOperations> kodeIcd10Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kodeIcd10');
    });
  }

  QueryBuilder<IstoriaKlinis, String, QQueryOperations>
      namaPenyakitLokalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'namaPenyakitLokal');
    });
  }

  QueryBuilder<IstoriaKlinis, String, QQueryOperations> pasienIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pasienId');
    });
  }

  QueryBuilder<IstoriaKlinis, String, QQueryOperations>
      pemeriksaanObjektifProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pemeriksaanObjektif');
    });
  }

  QueryBuilder<IstoriaKlinis, String?, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<IstoriaKlinis, String, QQueryOperations>
      rencanaTindakanProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rencanaTindakan');
    });
  }

  QueryBuilder<IstoriaKlinis, String, QQueryOperations> syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<IstoriaKlinis, DateTime?, QQueryOperations>
      tanggalKunjunganProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tanggalKunjungan');
    });
  }

  QueryBuilder<IstoriaKlinis, String, QQueryOperations> tenantIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tenantId');
    });
  }
}
