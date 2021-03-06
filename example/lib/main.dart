import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_vk/flutter_login_vk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  final plugin = VKLogin(debug: true);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _sdkVersion;
  VKAccessToken _token;
  VKUserProfile _profile;
  String _email;
  bool _sdkInitialized = false;

  @override
  void initState() {
    super.initState();

    _getSdkVersion();
    _initSdk();
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _token != null && _profile != null;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Login via VK example'),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
          child: Builder(
            builder: (context) => Center(
              child: Column(
                children: <Widget>[
                  if (_sdkVersion != null) Text("SDK v$_sdkVersion"),
                  if (isLogin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildUserInfo(context, _profile, _token, _email),
                    ),
                  isLogin
                      ? OutlineButton(
                          child: Text('Log Out'),
                          onPressed: _onPressedLogOutButton,
                        )
                      : OutlineButton(
                          child: Text('Log In'),
                          onPressed: () => _onPressedLogInButton(context),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, VKUserProfile profile,
      VKAccessToken accessToken, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('User: '),
        Text(
          '${profile.firstName} ${profile.lastName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          'Online: ${profile.online}, Online mobile: ${profile.onlineMobile}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (profile.photo200 != null) Image.network(profile.photo200),
        Text('AccessToken: '),
        Container(
          child: Text(
            accessToken.token,
            softWrap: true,
          ),
        ),
        Text('Created: ${accessToken.created}'),
        Text('Expires in: ${accessToken.expiresIn}'),
        if (email != null) Text('Email: $email'),
      ],
    );
  }

  void _onPressedLogInButton(BuildContext context) async {
    final res = await widget.plugin.logIn(scope: [
      VKScope.email,
    ]);

    if (res.isError) {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text('Log In failed: ${res.asError.error}'),
        ),
      );
    } else {
      final loginResult = res.asValue.value;
      if (!loginResult.isCanceled) _updateLoginInfo();
    }
  }

  void _onPressedLogOutButton() async {
    await widget.plugin.logOut();
    _updateLoginInfo();
  }

  void _initSdk() async {
    await widget.plugin.initSdk('7503887');
    _sdkInitialized = true;
    _updateLoginInfo();
  }

  void _getSdkVersion() async {
    final sdkVersion = await widget.plugin.sdkVersion;
    setState(() {
      _sdkVersion = sdkVersion;
    });
  }

  void _updateLoginInfo() async {
    if (!_sdkInitialized) return;

    final plugin = widget.plugin;
    final token = await plugin.accessToken;
    final profileRes = token != null ? await plugin.getUserProfile() : null;
    final email = token != null ? await plugin.getUserEmail() : null;

    setState(() {
      _token = token;
      _profile = profileRes?.asValue?.value;
      _email = email;
    });
  }
}
