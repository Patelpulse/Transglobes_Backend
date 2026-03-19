class CountryCode {
  final String id;
  final String code;
  final String countryName;
  final String status; // 'Published', 'Unpublished'

  CountryCode({
    required this.id,
    required this.code,
    required this.countryName,
    required this.status,
  });

  CountryCode copyWith({
    String? id,
    String? code,
    String? countryName,
    String? status,
  }) {
    return CountryCode(
      id: id ?? this.id,
      code: code ?? this.code,
      countryName: countryName ?? this.countryName,
      status: status ?? this.status,
    );
  }
}
