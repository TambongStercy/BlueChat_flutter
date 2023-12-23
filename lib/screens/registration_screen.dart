import 'package:blue_chat_v1/api_call.dart';
import 'package:blue_chat_v1/common/widgets/loader.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:flutter/material.dart';
import 'package:blue_chat_v1/components/auth_button.dart';

class RegistrationScreen extends StatefulWidget {
  static const id = 'registration_screen';

  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String name = '';
  String email = '';
  String password = '';
  String confirm = '';
  bool waiting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
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
                    const SizedBox(height: 30.0),
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
                          kTextFielDecoration.copyWith(hintText: 'Name'),
                      onChanged: (newValue) {
                        setState(() {
                          name = newValue;
                        });
                      },
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
                      obscureText: true,
                      decoration:
                          kTextFielDecoration.copyWith(hintText: 'Password'),
                      onChanged: (newValue) {
                        setState(() {
                          password = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20.0),
                    TextField(
                      obscureText: true,
                      decoration: kTextFielDecoration.copyWith(
                          hintText: 'Confirm Password'),
                      onChanged: (newValue) {
                        setState(() {
                          confirm = newValue;
                        });
                      },
                    ),
                    AuthButton(
                      title: 'Register',
                      onPress: () async {
                        // Navigator.pushNamed(context, PpUpload.id);

                        try {
                          if (email == '' || password == '' || name == '') {
                            showPopupMessage(
                              context,
                              'fill in all the infos please',
                            );
                            return;
                          }
                          if (password != confirm) {
                            showPopupMessage(
                              context,
                              'confirmed password not correct',
                            );
                            return;
                          }

                          setState(() {
                            waiting = true;
                          });

                          await signup(
                            context: context,
                            name: name,
                            email: email,
                            password: confirm,
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
