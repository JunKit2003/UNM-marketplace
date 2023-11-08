import 'package:flutter/material.dart';
import 'package:msal_flutter/msal_flutter.dart';

class AuthenticationProvider with ChangeNotifier {
  bool _isAuthenticated = true;
  bool get isAuthenticated => _isAuthenticated;

  late PublicClientApplication pca;

  static const String _clientId = "c77465be-7bad-4398-9b7a-fe900d815d82";
  static const String _authority =
      "https://login.microsoftonline.com/274313da-18e1-40ab-97e0-/oauth2/authorize";
  static const String _redirectUri =
      "https://attendance.nottingham.edu.my/redirect";

  AuthenticationProvider() {
    initializePca();
  }

  Future<void> initializePca() async {
    pca = await PublicClientApplication.createPublicClientApplication(
      _clientId,
      authority: _authority,
      iosRedirectUri: _redirectUri,
    );
    notifyListeners();
  }

  Future<void> signIn() async {
    try {
      final result = await pca.acquireTokenSilent(
          ["https://msalfluttertest.onmicrosoft.com/msaltesterapi/All"]);
      if (result != null) {
        _isAuthenticated = true;
        notifyListeners();
      } else {
        final loginResult = await pca.acquireToken(
            ["https://msalfluttertest.onmicrosoft.com/msaltesterapi/All"]);
        if (loginResult != null) {
          _isAuthenticated = true;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error during sign-in: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await pca.logout();
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      print('Error during sign-out: $e');
    }
  }
}
