import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/level_hive_box.dart';
import 'package:blue_chat_v1/classes/levels.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/screens/account_setting.dart';
import 'package:blue_chat_v1/screens/display_settings.dart';
import 'package:blue_chat_v1/screens/pp_uploading.dart';
import 'package:blue_chat_v1/screens/profile_screen.dart';
import 'package:blue_chat_v1/screens/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:blue_chat_v1/screens/welcome_screen.dart';
import 'package:blue_chat_v1/screens/login_screen.dart';
import 'package:blue_chat_v1/screens/registration_screen.dart';
import 'package:blue_chat_v1/screens/chats.dart';
import 'package:blue_chat_v1/screens/camera_screen.dart';
import 'package:blue_chat_v1/screens/unused_screens/gallery_screen.dart';
import 'package:blue_chat_v1/screens/unused_screens/animationed_screen.dart';
import 'package:blue_chat_v1/constants.dart';
// import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:blue_chat_v1/screens/album_screen.dart';
import 'package:blue_chat_v1/classes/photo_provider.dart';
import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:hive_flutter/hive_flutter.dart';


List<CameraDescription>? cameras;

Future<void> main() async {
  // SystemChrome.setSystemUIOverlayStyle(
  //   SystemUiOverlayStyle(
  //     statusBarColor: Colors.transparent,
  //     statusBarBrightness: Brightness.light,
  //   ),
  // );

  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  kAppDirectory = await getApplicationDocumentsDirectory();
  kTempDirectory = await getTemporaryDirectory();

  // Directory appDocDir = await getApplicationDocumentsDirectory();
  // var path = appDocDir.path;

  await Hive.initFlutter('bluechat_database');

  Hive.registerAdapter(ChatAdapter());
  Hive.registerAdapter(MessageModelAdapter());
  Hive.registerAdapter(MessageTypeAdapter());
  Hive.registerAdapter(MessageStatusAdapter());
  Hive.registerAdapter(LevelAdapter());
  Hive.registerAdapter(CourseAdapter());
  Hive.registerAdapter(QuestionAdapter());

  final chatBox = ChatHiveBox(await Hive.openBox('chats'));
  final levelBox = LevelHiveBox(await Hive.openBox('levels'));
  final userBox = (await Hive.openBox('user'));

  await userBox.put(
    'values',
    {
      'id': '',
      'name': '',
      'email': '',
      'avatar': '',
      'token': '',
    },
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserHiveBox(userBox),
        ),
        ChangeNotifierProvider(
          create: (context) => chatBox,
        ),
        ChangeNotifierProvider(
          create: (context) => levelBox,
        ),
        ChangeNotifierProvider(
          create: (context) => FilesToSend(),
        ),
        ChangeNotifierProvider(
          create: (context) => PhotoProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => CurrentChat(),
        ),
        ChangeNotifierProvider(
          create: (context) => RepliedMessage(),
        ),
        ChangeNotifierProvider(
          create: (context) => ConstantAppData(),
        ),
        ChangeNotifierProvider(
          create: (context) => Selection(),
        ),
        ChangeNotifierProvider(
          create: (context) => Updater(),
        ),
        ChangeNotifierProvider<SocketIo>(
          create: (context) => SocketIo(context),
        ),
        ChangeNotifierProvider(
          create: (context) => FileUploadProvider(context),
        ),
        ChangeNotifierProvider(
          create: (context) => DownloadProvider(context),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: WelcomeScreen.id,
      routes: { 
        WelcomeScreen.id: (context) => WelcomeScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        RegistrationScreen.id: (context) => RegistrationScreen(),
        ChatsScreen.id: (context) {
          Provider.of<SocketIo>(context).context = (context);
          // Provider.of<SocketIo>(context).initGeneralListeners();
          Provider.of<FileUploadProvider>(context, listen: false).resetUploadItems();
          Provider.of<DownloadProvider>(context, listen: false).resetDownloadItems();
          return ChatsScreen();
        },
        GalleryPage.id: (context) => GalleryPage(),
        AlbumPageView.id: (context) => AlbumPageView(),
        AnimatedScreen.id: (context) => AnimatedScreen(),
        UserSettings.id: (context) => UserSettings(),
        DisplaySettings.id: (context) => DisplaySettings(),
        UserProfileScreen.id: (context) => UserProfileScreen(),
        AccountSettings.id: (context) => AccountSettings(),
        PpUpload.id: (context) => PpUpload(),
        CameraScreen.id: (context) => CameraScreen(
              cameras: cameras!,
            ),
      },
      // theme: ThemeData.dark(),
    );
  }
}
