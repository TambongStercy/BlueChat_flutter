import 'package:blue_chat_v1/api_call.dart';
import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/level_hive_box.dart';
import 'package:blue_chat_v1/classes/levels.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/providers/file_download.dart';
import 'package:blue_chat_v1/providers/file_upload.dart';
import 'package:blue_chat_v1/providers/socket_io.dart';
import 'package:blue_chat_v1/screens/account_setting.dart';
import 'package:blue_chat_v1/screens/display_settings.dart';
import 'package:blue_chat_v1/screens/pp_uploading.dart';
import 'package:blue_chat_v1/screens/profile_screen.dart';
import 'package:blue_chat_v1/screens/user_settings.dart';
import 'package:blue_chat_v1/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:blue_chat_v1/screens/welcome_screen.dart';
import 'package:blue_chat_v1/screens/login_screen.dart';
import 'package:blue_chat_v1/screens/registration_screen.dart';
import 'package:blue_chat_v1/screens/chats.dart';
import 'package:blue_chat_v1/screens/camera_screen.dart';
import 'package:blue_chat_v1/screens/gallery_screen.dart';
import 'package:blue_chat_v1/screens/unused_screens/animationed_screen.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:blue_chat_v1/classes/photo_provider.dart';
import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// Create a class to extend RouteObserver
class RouteObserverProvider extends RouteObserver<Route<dynamic>> {
  String currentRoute = '/';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    currentRoute = route.settings.name ?? '/';
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    currentRoute = previousRoute?.settings.name ?? '/';
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    currentRoute = newRoute?.settings.name ?? '/';
  }
}

// Create an instance of RouteObserverProvider
final RouteObserverProvider routeObserver = RouteObserverProvider();
List<CameraDescription>? cameras;

// function to listen to background changes
@pragma('vm:entry-point')
Future _firebaseBackgroundMessage(RemoteMessage? message) async {
  kAppDirectory = await getApplicationDocumentsDirectory();
  kTempDirectory = await getTemporaryDirectory();
  await Hive.initFlutter('bluechat_database');

  if (!Hive.isAdapterRegistered(ChatAdapter().typeId)) {
    Hive.registerAdapter(ChatAdapter());
  }
  if (!Hive.isAdapterRegistered(MessageModelAdapter().typeId)) {
    Hive.registerAdapter(MessageModelAdapter());
  }
  if (!Hive.isAdapterRegistered(MessageTypeAdapter().typeId)) {
    Hive.registerAdapter(MessageTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(MessageStatusAdapter().typeId)) {
    Hive.registerAdapter(MessageStatusAdapter());
  }

  if (message != null) {
    final payloadData = (message.data);

    print(payloadData);

    await PushNotifications.handlePayload(payloadData);

  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  kAppDirectory = await getApplicationDocumentsDirectory();
  kTempDirectory = await getTemporaryDirectory();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // initialize firebase messaging
  await PushNotifications.init();

  if (!kIsWeb) {
    await PushNotifications.localNotiInit();
  }

  // on background notification received
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessage);

  // // on background notification tapped
  // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
  //   if (message != null) {
  //     _tapNotification(message);
  //   }
  // });

  // for handling in terminated state
  // FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
  //   if (message != null) {
  //     // Handle the notification that launched the app
  //     _terminatedHandler(message);
  //   }
  // });

  await Hive.initFlutter('bluechat_database');

  Hive.registerAdapter(ChatAdapter());
  Hive.registerAdapter(MessageModelAdapter());
  Hive.registerAdapter(MessageTypeAdapter());
  Hive.registerAdapter(MessageStatusAdapter());
  Hive.registerAdapter(LevelAdapter());
  Hive.registerAdapter(CourseAdapter());
  Hive.registerAdapter(QuestionAdapter());
  await Hive.openBox('uploadBox');
  // Hive.registerAdapter(UploadItemAdapter());

  final chatBox = ChatHiveBox(await Hive.openBox('chats'));
  final userBox = UserHiveBox(await Hive.openBox('user'));
  final levelBox = LevelHiveBox(await Hive.openBox('levels'));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => (userBox),
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
          create: (context) => SocketIo(),
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // to handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
      if (message != null) {
        _foregroundHandler(message);
      }
    });
    super.initState();
  }

  Future<void> _foregroundHandler(RemoteMessage message) async {
    // final payloadData = (message.data);
    //use this for alert notifications and more.
  }

  @override
  Widget build(BuildContext context) {
    final userBox = Provider.of<UserHiveBox>(context, listen: false);

    // final useContext = context;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: userBox.token != '' ? ChatsScreen.id : WelcomeScreen.id,
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      routes: {
        WelcomeScreen.id: (context) => WelcomeScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        RegistrationScreen.id: (context) => RegistrationScreen(),
        ChatsScreen.id: (context) {
          // if (isNewUser) {
          //   getUserChats(context: context);
          //   return ChatsScreen();
          // } else {
          //   print('doing some stuff');
          //   Provider.of<SocketIo>(useContext).connectSocket(useContext);
          //   Provider.of<FileUploadProvider>(useContext, listen: false)
          //       .resetUploadItems();
          //   Provider.of<DownloadProvider>(useContext, listen: false)
          //       .resetDownloadItems();
          //   return ChatsScreen();
          // }

          return ChatsScreen();
        },
        AlbumsPage.id: (context) => AlbumsPage(),
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
    );
  }
}
