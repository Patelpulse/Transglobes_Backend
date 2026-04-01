import 'dart:html' as html;

const String _tokenKey = 'corporate_auth_token';
const String _accountKey = 'corporate_auth_account';

Map<String, String?> readCorporateSession() {
  return {
    'token': html.window.localStorage[_tokenKey],
    'account': html.window.localStorage[_accountKey],
  };
}

void writeCorporateSession({
  required String token,
  required String accountJson,
}) {
  html.window.localStorage[_tokenKey] = token;
  html.window.localStorage[_accountKey] = accountJson;
}

void clearCorporateSession() {
  html.window.localStorage.remove(_tokenKey);
  html.window.localStorage.remove(_accountKey);
}
