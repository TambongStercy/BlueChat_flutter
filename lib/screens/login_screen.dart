import 'package:blue_chat_v1/api_call.dart';
import 'package:blue_chat_v1/common/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:blue_chat_v1/components/auth_button.dart';
import 'package:blue_chat_v1/constants.dart';
// import 'package:blue_chat_v1/screens/chats.dart';

class LoginScreen extends StatefulWidget {
  static const id = 'login_screen';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email = '';

  String password = '';

  bool waiting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log in'),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: ListView(
                  children: [
                    const SizedBox(height: 50.0),
                    const SizedBox(
                      child: Hero(
                        tag: 'logo',
                        child: Image(
                          image: AssetImage('assets/images/icon.png'),
                          height: 200.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    TextField(
                      decoration:
                          kTextFielDecoration.copyWith(hintText: 'Email'),
                      onChanged: (newValue) {
                        setState(() {
                          email = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20.0),
                    TextField(
                      decoration:
                          kTextFielDecoration.copyWith(hintText: 'Password'),
                      onChanged: (newValue) {
                        setState(() {
                          password = newValue;
                        });
                      },
                    ),
                    AuthButton(
                      title: 'Log in',
                      onPress: () async {
                        try {
                          if (email == '' || password == '') {
                            showPopupMessage(
                              context,
                              'fill in all the infos please',
                            );
                            return;
                          }

                          setState(() {
                            waiting = true;
                          });

                          await login(
                            context: context,
                            email: email,
                            password: password,
                          );

                          setState(() {
                            waiting = false;
                          });
                        } on Exception catch (e) {
                          print(e);
                          setState(() {
                            waiting = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (waiting) const Loader(),
          ],
        ),
      ),
    );
  }
}
