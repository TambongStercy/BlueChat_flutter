import 'package:blue_chat_v1/src/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:blue_chat_v1/components/auth_button.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/screens/login_screen.dart';
import 'package:blue_chat_v1/screens/registration_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
  });

  static const id = 'welcome_screen';

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // @override
  // void initState() {
  //   super.initState();
  // }

  // @override
  // void dispose() {
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarColor(Colors.blue);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Flexible(
                      child: Hero(
                        tag: 'logo',
                        child: Image(
                          image: AssetImage('assets/images/icon.png'),
                          height: 70.0,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 50.0,
                    ),
                    const Text(
                      'Welcome to Blue Chat',
                      style: kTitleStyle,
                    ),
                    const SizedBox(
                      height: 30.0,
                    ),
                    AuthButton(
                      title: 'Log in',
                      onPress: () {
                        FlutterStatusbarcolor.setStatusBarColor(
                          Colors.transparent,
                        );
                        Navigator.pushNamed(context, LoginScreen.id)
                            .then((value) {
                          FlutterStatusbarcolor.setStatusBarColor(
                            Colors.blue,
                          );
                        });
                      },
                    ),
                    AuthButton(
                      title: 'Register',
                      onPress: () {
                        FlutterStatusbarcolor.setStatusBarColor(
                          Colors.transparent,
                        );

                        Navigator.pushNamed(
                          context,
                          RegistrationScreen.id,
                        ).then((value) {
                          FlutterStatusbarcolor.setStatusBarColor(
                            Colors.blue,
                          );
                        });
                      },
                    ),
                    // AuthButton(
                    //   title: 'Auth Screens',
                    //   onPress: () {
                    //     FlutterStatusbarcolor.setStatusBarColor(
                    //       Colors.transparent,
                    //     );

                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(builder: (context) => const SplashScreen()),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
