class Division {
  final int id;
  final String? code;
  final String? geoCode;
  final String? name;
  final String? nameBn;

  Division({required this.id, this.code, this.geoCode, this.name, this.nameBn});

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'] ?? 0,
      code: json['code'],
      geoCode: json['geo_code'],
      name: json['name'],
      nameBn: json['name_bn'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'geo_code': geoCode,
      'name': name,
      'name_bn': nameBn,
    };
  }

  String get displayName => name ?? 'Unknown Division';
}

class District {
  final int id;
  final String? code;
  final String? geoCode;
  final String? name;
  final String? nameBn;
  final int? divisionId;

  District({
    required this.id,
    this.code,
    this.geoCode,
    this.name,
    this.nameBn,
    this.divisionId,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] ?? 0,
      code: json['code'],
      geoCode: json['geo_code'],
      name: json['name'],
      nameBn: json['name_bn'],
      divisionId: json['division_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'geo_code': geoCode,
      'name': name,
      'name_bn': nameBn,
      'division_id': divisionId,
    };
  }

  String get displayName => name ?? 'Unknown District';
}

class Upazila {
  final int id;
  final String? code;
  final String? geoCode;
  final String? name;
  final String? nameBn;
  final int? districtId;
  final bool? isCityCorporation;

  Upazila({
    required this.id,
    this.code,
    this.geoCode,
    this.name,
    this.nameBn,
    this.districtId,
    this.isCityCorporation,
  });

  factory Upazila.fromJson(Map<String, dynamic> json) {
    return Upazila(
      id: json['id'] ?? 0,
      code: json['code'],
      geoCode: json['geo_code'],
      name: json['name'],
      nameBn: json['name_bn'],
      districtId: json['district_id'],
      isCityCorporation: json['is_city_corporation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'geo_code': geoCode,
      'name': name,
      'name_bn': nameBn,
      'district_id': districtId,
      'is_city_corporation': isCityCorporation,
    };
  }

  String get displayName => name ?? 'Unknown Upazila';
}
