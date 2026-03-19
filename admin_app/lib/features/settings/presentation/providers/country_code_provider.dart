import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/country_code_model.dart';

class CountryCodeNotifier extends Notifier<List<CountryCode>> {
  @override
  List<CountryCode> build() => [
    CountryCode(id: '1', code: '+972', countryName: 'Israel', status: 'Publish'),
    CountryCode(id: '2', code: '+93', countryName: 'Afghanistan', status: 'Publish'),
    CountryCode(id: '3', code: '+355', countryName: 'Albania', status: 'Publish'),
    CountryCode(id: '4', code: '+213', countryName: 'Algeria', status: 'Publish'),
    CountryCode(id: '5', code: '+1 684', countryName: 'American Samoa', status: 'Publish'),
    CountryCode(id: '6', code: '+376', countryName: 'Andorra', status: 'Publish'),
    CountryCode(id: '7', code: '+244', countryName: 'Angola', status: 'Publish'),
    CountryCode(id: '8', code: '+1 264', countryName: 'Anguilla', status: 'Publish'),
  ];

  void addCountryCode(String code, String name, String status) {
    final newCode = CountryCode(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: code,
      countryName: name,
      status: status,
    );
    state = [...state, newCode];
  }

  void removeCountryCode(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void updateStatus(String id, String newStatus) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(status: newStatus) else item
    ];
  }
}

final countryCodeProvider = NotifierProvider<CountryCodeNotifier, List<CountryCode>>(() {
  return CountryCodeNotifier();
});
