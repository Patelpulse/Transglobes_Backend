Map<String, String?> readCorporateSession() {
  return const {
    'token': null,
    'account': null,
  };
}

void writeCorporateSession({
  required String token,
  required String accountJson,
}) {}

void clearCorporateSession() {}
