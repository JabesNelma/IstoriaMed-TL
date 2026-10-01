// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pasien_schema.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPasienCollection on Isar {
  IsarCollection<Pasien> get pasiens => this.collection();
}

const PasienSchema = CollectionSchema(
  name: r'Pasien_538',
  id: 6607991385340966,
  properties: {
    r'fingerprintHash': PropertySchema(
      id: 0,
      name: r'fingerprintHash',
      type: IsarType.string,
    ),
    r'jenisKelamin': PropertySchema(
      id: 1,
      name: r'jenisKelamin',
      type: IsarType.string,
    ),
    r'localStatus': PropertySchema(
      id: 2,
      name: r'localStatus',
      type: IsarType.string,
    ),
    r'namaLengkap': PropertySchema(
      id: 3,
      name: r'namaLengkap',
      type: IsarType.string,
    ),
    r'noKtp': PropertySchema(
      id: 4,
      name: r'noKtp',
      type: IsarType.string,
    ),
    r'remoteId': PropertySchema(
      id: 5,
      name: r'remoteId',
      type: IsarType.string,
    ),
    r'tanggalLahir': PropertySchema(
      id: 6,
      name: r'tanggalLahir',
      type: IsarType.dateTime,
    ),
    r'tempatLahir': PropertySchema(
      id: 7,
      name: r'tempatLahir',
      type: IsarType.string,
    )
  },
  estimateSize: _pasienEstimateSize,
  serialize: _pasienSerialize,
  deserialize: _pasienDeserialize,
  deserializeProp: _pasienDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _pasienGetId,
  getLinks: _pasienGetLinks,
  attach: _pasienAttach,
  version: '3.1.0+1',
);

int _pasienEstimateSize(
  Pasien object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.fingerprintHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.jenisKelamin.length * 3;
  bytesCount += 3 + object.localStatus.length * 3;
  bytesCount += 3 + object.namaLengkap.length * 3;
  bytesCount += 3 + object.noKtp.length * 3;
  {
    final value = object.remoteId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tempatLahir.length * 3;
  return bytesCount;
}

void _pasienSerialize(
  Pasien object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.fingerprintHash);
  writer.writeString(offsets[1], object.jenisKelamin);
  writer.writeString(offsets[2], object.localStatus);
  writer.writeString(offsets[3], object.namaLengkap);
  writer.writeString(offsets[4], object.noKtp);
  writer.writeString(offsets[5], object.remoteId);
  writer.writeDateTime(offsets[6], object.tanggalLahir);
  writer.writeString(offsets[7], object.tempatLahir);
}

Pasien _pasienDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Pasien();
  object.fingerprintHash = reader.readStringOrNull(offsets[0]);
  object.id = id;
  object.jenisKelamin = reader.readString(offsets[1]);
  object.localStatus = reader.readString(offsets[2]);
  object.namaLengkap = reader.readString(offsets[3]);
  object.noKtp = reader.readString(offsets[4]);
  object.remoteId = reader.readStringOrNull(offsets[5]);
  object.tanggalLahir = reader.readDateTime(offsets[6]);
  object.tempatLahir = reader.readString(offsets[7]);
  return object;
}

P _pasienDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pasienGetId(Pasien object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pasienGetLinks(Pasien object) {
  return [];
}

void _pasienAttach(IsarCollection<dynamic> col, Id id, Pasien object) {
  object.id = id;
}

extension PasienQueryWhereSort on QueryBuilder<Pasien, Pasien, QWhere> {
  QueryBuilder<Pasien, Pasien, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PasienQueryWhere on QueryBuilder<Pasien, Pasien, QWhereClause> {
  QueryBuilder<Pasien, Pasien, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Pasien, Pasien, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterWhereClause> idBetween(
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

extension PasienQueryFilter on QueryBuilder<Pasien, Pasien, QFilterCondition> {
  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> fingerprintHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fingerprintHash',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition>
      fingerprintHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fingerprintHash',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> fingerprintHashEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fingerprintHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition>
      fingerprintHashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fingerprintHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> fingerprintHashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fingerprintHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> fingerprintHashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fingerprintHash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> fingerprintHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fingerprintHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> fingerprintHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fingerprintHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> fingerprintHashContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fingerprintHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> fingerprintHashMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fingerprintHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> fingerprintHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fingerprintHash',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition>
      fingerprintHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fingerprintHash',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> jenisKelaminEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jenisKelamin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> jenisKelaminGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jenisKelamin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> jenisKelaminLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jenisKelamin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> jenisKelaminBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jenisKelamin',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> jenisKelaminStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jenisKelamin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> jenisKelaminEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jenisKelamin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> jenisKelaminContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jenisKelamin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> jenisKelaminMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jenisKelamin',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> jenisKelaminIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jenisKelamin',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> jenisKelaminIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jenisKelamin',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> localStatusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> localStatusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> localStatusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> localStatusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> localStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> localStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> localStatusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> localStatusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> localStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> localStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> namaLengkapEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaLengkap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> namaLengkapGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'namaLengkap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> namaLengkapLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'namaLengkap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> namaLengkapBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'namaLengkap',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> namaLengkapStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'namaLengkap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> namaLengkapEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'namaLengkap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> namaLengkapContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'namaLengkap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> namaLengkapMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'namaLengkap',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> namaLengkapIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'namaLengkap',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> namaLengkapIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'namaLengkap',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> noKtpEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noKtp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> noKtpGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noKtp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> noKtpLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noKtp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> noKtpBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noKtp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> noKtpStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noKtp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> noKtpEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noKtp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> noKtpContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noKtp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> noKtpMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noKtp',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> noKtpIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noKtp',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> noKtpIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noKtp',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> remoteIdEqualTo(
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

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> remoteIdGreaterThan(
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

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> remoteIdLessThan(
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

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> remoteIdBetween(
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

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> remoteIdStartsWith(
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

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> remoteIdEndsWith(
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

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> remoteIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> remoteIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remoteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> remoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> remoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tanggalLahirEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tanggalLahir',
        value: value,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tanggalLahirGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tanggalLahir',
        value: value,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tanggalLahirLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tanggalLahir',
        value: value,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tanggalLahirBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tanggalLahir',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tempatLahirEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tempatLahir',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tempatLahirGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tempatLahir',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tempatLahirLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tempatLahir',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tempatLahirBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tempatLahir',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tempatLahirStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tempatLahir',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tempatLahirEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tempatLahir',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tempatLahirContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tempatLahir',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tempatLahirMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tempatLahir',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tempatLahirIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tempatLahir',
        value: '',
      ));
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterFilterCondition> tempatLahirIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tempatLahir',
        value: '',
      ));
    });
  }
}

extension PasienQueryObject on QueryBuilder<Pasien, Pasien, QFilterCondition> {}

extension PasienQueryLinks on QueryBuilder<Pasien, Pasien, QFilterCondition> {}

extension PasienQuerySortBy on QueryBuilder<Pasien, Pasien, QSortBy> {
  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByFingerprintHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fingerprintHash', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByFingerprintHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fingerprintHash', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByJenisKelamin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jenisKelamin', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByJenisKelaminDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jenisKelamin', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByLocalStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localStatus', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByLocalStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localStatus', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByNamaLengkap() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namaLengkap', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByNamaLengkapDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namaLengkap', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByNoKtp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noKtp', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByNoKtpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noKtp', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByTanggalLahir() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tanggalLahir', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByTanggalLahirDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tanggalLahir', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByTempatLahir() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempatLahir', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> sortByTempatLahirDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempatLahir', Sort.desc);
    });
  }
}

extension PasienQuerySortThenBy on QueryBuilder<Pasien, Pasien, QSortThenBy> {
  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByFingerprintHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fingerprintHash', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByFingerprintHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fingerprintHash', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByJenisKelamin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jenisKelamin', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByJenisKelaminDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jenisKelamin', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByLocalStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localStatus', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByLocalStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localStatus', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByNamaLengkap() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namaLengkap', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByNamaLengkapDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'namaLengkap', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByNoKtp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noKtp', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByNoKtpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noKtp', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByTanggalLahir() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tanggalLahir', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByTanggalLahirDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tanggalLahir', Sort.desc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByTempatLahir() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempatLahir', Sort.asc);
    });
  }

  QueryBuilder<Pasien, Pasien, QAfterSortBy> thenByTempatLahirDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempatLahir', Sort.desc);
    });
  }
}

extension PasienQueryWhereDistinct on QueryBuilder<Pasien, Pasien, QDistinct> {
  QueryBuilder<Pasien, Pasien, QDistinct> distinctByFingerprintHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fingerprintHash',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Pasien, Pasien, QDistinct> distinctByJenisKelamin(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jenisKelamin', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Pasien, Pasien, QDistinct> distinctByLocalStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localStatus', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Pasien, Pasien, QDistinct> distinctByNamaLengkap(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'namaLengkap', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Pasien, Pasien, QDistinct> distinctByNoKtp(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noKtp', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Pasien, Pasien, QDistinct> distinctByRemoteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Pasien, Pasien, QDistinct> distinctByTanggalLahir() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tanggalLahir');
    });
  }

  QueryBuilder<Pasien, Pasien, QDistinct> distinctByTempatLahir(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tempatLahir', caseSensitive: caseSensitive);
    });
  }
}

extension PasienQueryProperty on QueryBuilder<Pasien, Pasien, QQueryProperty> {
  QueryBuilder<Pasien, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Pasien, String?, QQueryOperations> fingerprintHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fingerprintHash');
    });
  }

  QueryBuilder<Pasien, String, QQueryOperations> jenisKelaminProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jenisKelamin');
    });
  }

  QueryBuilder<Pasien, String, QQueryOperations> localStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localStatus');
    });
  }

  QueryBuilder<Pasien, String, QQueryOperations> namaLengkapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'namaLengkap');
    });
  }

  QueryBuilder<Pasien, String, QQueryOperations> noKtpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noKtp');
    });
  }

  QueryBuilder<Pasien, String?, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<Pasien, DateTime, QQueryOperations> tanggalLahirProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tanggalLahir');
    });
  }

  QueryBuilder<Pasien, String, QQueryOperations> tempatLahirProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tempatLahir');
    });
  }
}
