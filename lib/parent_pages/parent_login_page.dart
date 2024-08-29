import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import '../main.dart';
import 'package:test_app/auth_logic.dart';
import 'package:test_app/child_pages/child_login_page.dart';

Map<String, String> users = {"kavya": "password2", "nihanth": "password3"};

class ParentLoginID {
  String username;
  String password;
  String accountType;

  String? email;

  ParentLoginID(this.username, this.password, this.accountType, {this.email});
}

class ParentLoginPage extends StatelessWidget {
  ParentLoginPage({super.key});

  final AuthService _auth = AuthService();

//done
  Future<String?> _authUser(LoginData data) async {
    try {
      _auth.signInParent(data.name, data.password);
    } on UserNotParentException {
      return 'User is not parent';
    } on UserDoesNotExistException {
      return 'Username or password is incorrect';
    } catch (e) {
      return 'error';
    }
    ParentLoginID currentUser = ParentLoginID(data.name, data.password, "child");
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }

  Future<String?> _recoverPassword(String name) async {
    return null;
  }

  Future<String?> _signUp(SignupData data) async {
    print(data.additionalSignupData);
    print(data.name);
    print(data.password);
    try {
      _auth.registerParent(
          data.additionalSignupData!["username"]!,
          "${data.additionalSignupData!["First name"]!} ${data.additionalSignupData!["Last name"]!}",
          data.name!,
          data.password!);
    } on UsernameAlreadyExistsException {
      return "Username already exists";
    } catch (e) {
      print(e);
      return "failed";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      FlutterLogin(
        onLogin: _authUser,
        onRecoverPassword: _recoverPassword,
        onSignup: _signUp,
        additionalSignupFields: [
          UserFormField(keyName: "First name", userType: LoginUserType.firstName),
          UserFormField(keyName: "Last name", userType: LoginUserType.lastName),
          UserFormField(keyName: "username", userType: LoginUserType.name)],
        title: "Parent Login",
        userType: LoginUserType.email,
        theme: LoginTheme(primaryColor: Color(0xFF56B1FB),),
        onSubmitAnimationCompleted: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => BasePage(),
          ));
        },
      ),
      Positioned(
        top: 20,
        right: 20,
        child: ElevatedButton(
          onPressed:(){ _navigateToChildLogin(context);},
          child: Text("Child Login"),
        ),
      )
    ]);
  }
  void _navigateToChildLogin(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChildLoginPage()),
    );
  }
}


