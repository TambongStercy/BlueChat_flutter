import 'dart:convert';
import 'dart:io';

import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/level_hive_box.dart';
import 'package:blue_chat_v1/classes/levels.dart';
// import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/constants.dart';
// import 'package:blue_chat_v1/screens/chat_screen.dart';
import 'package:blue_chat_v1/screens/chats.dart';
import 'package:blue_chat_v1/screens/pdf_reader.dart';
import 'package:blue_chat_v1/screens/pp_uploading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

Future<void> signup({
  required BuildContext context,
  required String name,
  required String email,
  required String password,
}) async {
  final url = Uri.parse('$kServerURL/user/signup');
  try {
    final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

    final body = {
      'username': name,
      'email': email,
      'password': password,
    };

    final response = await http.post(url, body: body);

    final data = json.decode(response.body);
    final token = data['token'];
    final message = data['message'];

    if (response.statusCode == 200) {
      final id = data['userInfo']['id'];
      // ignore: use_build_context_synchronously
      Provider.of<UserHiveBox>(context, listen: false).saveToken(token);

      await chatBox.emptyBox();

      // ignore: use_build_context_synchronously
      Provider.of<UserHiveBox>(context, listen: false).updateUser(
        id: id,
        name: name,
        email: email,
        avatar: '',
      );

      // ignore: use_build_context_synchronously
      Navigator.pushNamed(context, PpUpload.id);
    } else {
      print('request failed with status: ${response.statusCode}');
    }
    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  } on Exception catch (e) {
    print(e);
    // TODO
  }
}

Future<void> login({
  required BuildContext context,
  required String email,
  required String password,
}) async {
  final url = Uri.parse('$kServerURL/user/login');

  print('#');

  // ignore: use_build_context_synchronously
  final userBox = Provider.of<UserHiveBox>(context, listen: false);
  final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

  final body = {
    'email': email,
    'password': password,
  };

  final response = await http.post(url, body: body);

  final data = json.decode(response.body);
  final token = data['token'];
  final message = data['message'];

  if (response.statusCode == 200) {
    // ignore: use_build_context_synchronously
    showPopupMessage(context, 'Login successfull');

    final userInfo = data['userInfo'];

    final username = userInfo['username'];
    final userEmail = userInfo['email'];
    final avatar = userInfo['avatar'];
    final id = userInfo['id'];

    print('userID: $id');

    await userBox.saveToken(token);

    // ignore: use_build_context_synchronously
    await userBox.updateUser(
      id: id,
      name: username,
      email: userEmail,
      avatar: getMobilePath(avatar),
    );

    // ignore: use_build_context_synchronously
    showPopupMessage(context, 'Searching for your chats\n ...');
    await chatBox.emptyBox();

    Provider.of<SocketIo>(context, listen: false).context = (context);

    // ignore: use_build_context_synchronously
    await getUserChats(context: context);

    // ignore: use_build_context_synchronously
    Navigator.pushNamed(context, ChatsScreen.id);
  } else {
    print('request failed with status: ${response.statusCode}');

    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  }
}

/// After login only(Cause signedup user has no chat)
Future<void> getUserChats({required BuildContext context}) async {
  print('Getting your chats ...');
  final userBox = Provider.of<UserHiveBox>(context, listen: false);
  final chatBox = Provider.of<ChatHiveBox>(context, listen: false);
  final currentToken = userBox.token;
  final email = userBox.email;
  final avatar = userBox.avatar;

  final url = Uri.parse('$kServerURL/user/chats/?email=$email');

  final headers = {
    'Authorization': 'Bearer $currentToken',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  final response = await http.get(url, headers: headers);

  final data = json.decode(response.body);
  final token = data['token'] ?? userBox.token;
  final chatsJson = data['userChats'] ?? [];
  final String avatar64 = data['avatar64'];

  userBox.saveToken(token);

  print(chatsJson);
  print(avatar64);
  print(data);
  print(response.toString());

  final ppFile = File(avatar);

  if (!ppFile.existsSync()) {
    final Uint8List bytes = base64Decode(avatar64);
    ppFile.writeAsBytesSync(bytes);
  }

  if (response.statusCode == 200) {
    for (final chatJson in chatsJson) {
      print(chatJson);
      final chat = Chat.fromJson(chatJson, context);
      await chatBox.addUpdateChat(chat);
    }

    // Navigator.pushNamed(context, ChatsScreen.id);
  } else {
    print('request failed with status: ${response.statusCode}');

    // ignore: use_build_context_synchronously
    showPopupMessage(context, 'Unable to get Chats');
  }
}

Future<void> uploadPP({
  required BuildContext context,
  required String path,
}) async {
  final userBox = Provider.of<UserHiveBox>(context, listen: false);

  final currentToken = userBox.token;
  final localEmail = userBox.email;

  final url = Uri.parse('$kServerURL/user/upload-avatar?email=$localEmail');

  final request = http.MultipartRequest('POST', url);

  request.headers['Authorization'] = 'Bearer $currentToken';
  request.fields['email'] = localEmail;

  request.files.add(await http.MultipartFile.fromPath('file', path));

  final response = await request.send();

  final data = json.decode(await response.stream.bytesToString());

  final token = data['token'] ?? currentToken;
  final message = data['message'] ?? '';
  final userInfo = data['userInfo'];

  userBox.saveToken(token);

  if (response.statusCode == 200) {
    final username = userInfo['username'] ?? '';
    final serverPp = userInfo['avatar'];
    print('Server path of pp : $serverPp');
    final mobilePp = (getMobilePath(serverPp));

    print('Mobile path of pp : $mobilePp');
    print('Mobile path of pp : $path');
    final email = userInfo['email'] ?? '';

    userBox.updateUser(
      id: userBox.id,
      name: username,
      email: email,
      avatar: path,
    );

    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  } else {
    print('request failed with status: ${response.statusCode}');
  }
  // ignore: use_build_context_synchronously
  showPopupMessage(context, message);
}

Future<void> downloadAvatar({
  required BuildContext context,
  required Chat chat,
}) async {
  try {
    final chatEmail = chat.email;
    final avatarPath = chat.avatar;

    final ppFile = File(avatarPath);
    if (ppFile.existsSync()) {
      return print('Already Downloaded');
    }

    final userBox = Provider.of<UserHiveBox>(context, listen: false);

    final currentToken = userBox.token;
    final email = userBox.email;

    final headers = {
      'Authorization': 'Bearer $currentToken',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final url = Uri.parse(
        '$kServerURL/user/download-avatar?email=$email&chatEmail=$chatEmail');

    final response = await http.get(url, headers: headers);

    final token = response.headers['x-token'] ?? currentToken;

    print(token);

    userBox.saveToken(token);

    if (response.statusCode == 200) {
      final imageBytes = response.bodyBytes;
      // print(response.bodyBytes);

      // Write the image data to the specified path
      final imageFile = File(avatarPath);
      await imageFile.writeAsBytes(imageBytes);

      // Now, you have saved the image to the specified path
      print('Image saved to: $avatarPath');
      // after this the avatar file path now exist and the avatar image won't be blur any more
    } else {
      // Handle errors, e.g., image not found
      print('Image request failed with status code ${response.statusCode}');
    }
  } on Exception catch (e) {
    print(e);
  }
}

void restartApp() {
  // Send a signal to the Flutter framework to restart the app
  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
}

Future<void> logout({required BuildContext context}) async {
  try {
    final url = Uri.parse('$kServerURL/user/logout');

    final userBox = Provider.of<UserHiveBox>(context, listen: false);
    final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

    final currentToken = userBox.token;
    final email = userBox.email;

    final headers = {
      'Authorization': 'Bearer $currentToken',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final body = {
      'email': email,
    };

    final response = await http.post(url, headers: headers, body: body);

    final data = json.decode(response.body);
    final message = data['message'];

    if (response.statusCode == 200) {
      await userBox.logoutUser();
      await chatBox.emptyBox();

      // ignore: use_build_context_synchronously
      showPopupMessage(context, '$email logged out successfully');
      // ignore: use_build_context_synchronously
      Provider.of<SocketIo>(context, listen: false).disconnect();
      restartApp();
    } else {
      print('request failed with status: ${response.statusCode}');

      // ignore: use_build_context_synchronously
      showPopupMessage(context, message);
    }
  } catch (e) {
    print(e);
  }
}

Future<void> searchChats({
  required BuildContext context,
  required String name,
}) async {
  try {
    final userBox = Provider.of<UserHiveBox>(context, listen: false);
    final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

    final currentToken = userBox.token;
    final email = userBox.email;

    final url = Uri.parse('$kServerURL/user/search?email=$email&name=$name');

    final headers = {
      'Authorization': 'Bearer $currentToken',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final response = await http.get(url, headers: headers);

    final data = json.decode(response.body);
    final message = data['message'];
    final token = data['token'] ?? currentToken;

    userBox.saveToken(token);

    if (response.statusCode == 200) {
      // final chatInfoList = [];
      final chatJsons = data['searchedChats'];

      print('chatJsons: ${chatJsons[0]}');

      for (final chatJson in chatJsons) {
        print('id: ${chatJson['id']}');
        print('email: ${chatJson['email']}');
        print('description: ${chatJson['description']}');
        final chatID = chatJson['id'];

        /// Check if chat is already found locally
        if (chatBox.isChat(chatID)) {
          continue;
        }
        // ignore: use_build_context_synchronously
        await saveSearchChat(chatJson, context);
      }
    } else {
      print('request failed with status: ${response.statusCode}');
      // ignore: use_build_context_synchronously
      showPopupMessage(context, message);
    }
  } catch (e) {
    print(e);
  }
}

Future<void> getLevelCourses({
  required BuildContext context,
  required String level,
  required String semester,
}) async {
  try {
    final userBox = Provider.of<UserHiveBox>(context, listen: false);
    final levelBox = Provider.of<LevelHiveBox>(context, listen: false);

    final foundLevel = levelBox.getLevel(level)!;

    final currentToken = userBox.token;
    final email = userBox.email;

    final url = Uri.parse(
        '$kServerURL/user/level-courses?email=$email&level=$level&semester=$semester');

    final headers = {
      'Authorization': 'Bearer $currentToken',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final response = await http.get(url, headers: headers);

    final data = json.decode(response.body);
    final message = data['message'];
    final token = data['token'] ?? currentToken;

    userBox.saveToken(token);

    if (response.statusCode == 200) {
      final jsonCourses = data['courses'];

      for (final jsonCourse in jsonCourses) {
        final course = Course.fromJson(jsonCourse);

        // print(course.questions);

        //if level has this course
        if (foundLevel.hasThisCourse(course, semester)) {
          await foundLevel.updateCourse(course, semester);
          continue;
        }
        //else we add a course

        await foundLevel.addCourse(course, semester);
      }
    } else {
      print('request failed with status: ${response.statusCode}');
      // ignore: use_build_context_synchronously
      showPopupMessage(context, message);
    }
  } catch (e) {
    print(e);
  }
}

Future<void> uploadQuestion({
  required BuildContext context,
  required String level,
  required String semester,
  required Question question,
  required Course course,
}) async {
  final userBox = Provider.of<UserHiveBox>(context, listen: false);

  final currentToken = userBox.token;
  final localEmail = userBox.email;

  final name = question.name;
  final code = course.courseCode;
  final courseTitle = course.title;
  final departments = course.departments;
  final year = question.year;
  final type = question.type;

  final quesParams = {
    'name': name,
    'code': code,
    'year': year,
    'type': type,
    'level': level,
    'semester': semester,
    'courseTitle': courseTitle,
    'departments': jsonEncode(departments),
  };

  try {
    final path = question.path;

    final url = Uri.parse('$kServerURL/user/upload-question?email=$localEmail');

    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $currentToken';
    request.fields['email'] = localEmail;

    request.files.add(await http.MultipartFile.fromPath('file', path));

    request.fields.addAll(quesParams);

    final response = await request.send();

    final data = json.decode(await response.stream.bytesToString());

    final token = data['token'] ?? currentToken;
    final message = data['message'] ?? '';

    userBox.saveToken(token);

    if (response.statusCode == 200) {
      print('Question uploaded successfully');
    } else {
      print('request failed with status: ${response.statusCode}');
    }
    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  } on Exception catch (e) {
    print(e);
  }
}

Future<void> downloadQuestion({
  required BuildContext context,
  required Course course,
  required Question question,
  required String level,
  required String semester,
}) async {
  try {
    final questionPath = question.path;
    final pdfFile = File(questionPath);

    final dio = Dio();

    if (!pdfFile.existsSync()) {
      pdfFile.createSync(recursive: true);
      print('PDF file already exists');
      return;
    }
    print(questionPath);

    int receivedBytes = 0;

    final userBox = Provider.of<UserHiveBox>(context, listen: false);

    final currentToken = userBox.token;
    final email = userBox.email;

    final name = question.name;
    final code = course.courseCode;
    final year = question.year;

    final head = {
      'Authorization': 'Bearer $currentToken',
    };

    final response = await dio.get('$kServerURL/user/download-question',
        options: Options(
          responseType: ResponseType.stream,
          headers: head,
        ),
        queryParameters: {
          'email': email,
          'name': name,
          'code': code,
          'year': year,
          'level': level,
          'semester': semester,
        });

    final headers = response.headers
      ..forEach((name, values) {
        print(name);
        values.forEach((element) {
          print('|| $element');
        });
      });

    final contentLength = int.parse(headers.value('content-length')!);
    final token = headers.value('x-token') ?? currentToken;

    userBox.saveToken(token);

    final fileSize = pdfFile.lengthSync();
    print(fileSize);

    if (contentLength != fileSize) {
      pdfFile.deleteSync();
      print('deleted the pdf');
      pdfFile.createSync();
      print('created back the pdf');

      final receivedStream = response.data.stream;

      receivedStream.listen((List<int> data) {
        pdfFile.writeAsBytesSync(data, mode: FileMode.append);
        receivedBytes += data.length;
      }, onDone: () {
        print('Download completed');
        print('Question saved to: $questionPath');

        final updaters = Provider.of<Updater>(context, listen: false).updaters;

        if (updaters.keys.contains(PdfReader.id)) {
          final updatePage = updaters[PdfReader.id];
          updatePage!();
        }
      });
    } else {
      final updaters = Provider.of<Updater>(context, listen: false).updaters;

      if (updaters.keys.contains(PdfReader.id)) {
        final updatePage = updaters[PdfReader.id];
        updatePage!();
      }
      print('PDF already exists');
    }
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> createCourse({
  required BuildContext context,
  required String level,
  required String semester,
  required String code,
  required String title,
  required List<String> departments,
}) async {
  try {
    final userBox = Provider.of<UserHiveBox>(context, listen: false);

    final currentToken = userBox.token;
    final localEmail = userBox.email;

    final url = Uri.parse('$kServerURL/user/create-course/?email=$localEmail');

    final headers = {
      'Authorization': 'Bearer $currentToken',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final body = {
      'level': level,
      'semester': semester,
      'code': code,
      'title': title,
      'departments': jsonEncode(departments),
    };

    final response = await http.post(url, headers: headers, body: body);

    final data = json.decode(response.body);

    final token = data['token'] ?? currentToken;
    final message = data['message'] ?? '';

    userBox.saveToken(token);

    if (response.statusCode == 200) {
      print('Question was created successfully');
    } else {
      print('request failed with status: ${response.statusCode}');
    }
    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  } on Exception catch (e) {
    print(e);
  }
}

//Groups API
Future<void> createGroup({
  required BuildContext context,
  required String name,
  required String description,
  required String avatar,
  required List<String> participants,
}) async {
  final userBox = Provider.of<UserHiveBox>(context, listen: false);

  participants.add(userBox.id);

  final currentToken = userBox.token;
  final localEmail = userBox.email;

  final url =
      Uri.parse('$kServerURL/user/group/create-group/?email=$localEmail');

  print('name:= $name');

  final body = {
    'name': name,
    'description': description,
    'email': '$name@gmail.com',
    'avatar': getServerPath(avatar),
    'participants': jsonEncode(participants),
  };

  final headers = {
    'Authorization': 'Bearer $currentToken',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  try {
    final response = await http.post(
      url,
      body: body,
      headers: headers,
    );

    final data = json.decode(response.body);

    final token = data['token'] ?? currentToken;
    final message = data['message'] ?? '';
    final jsonGroup = data['group'];

    userBox.saveToken(token);

    if (response.statusCode == 200) {
      print('Group was created successfully');

      final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

      final group = Chat.fromJson(jsonGroup, context);

      await chatBox.addUpdateChat(group);
    } else {
      print('request failed with status: ${response.statusCode}');
    }
    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  } on Exception catch (e) {
    print(e);
  }
}

Future<void> exitGroup({
  required BuildContext context,
  required String groupId,
}) async {
  try {
    final userBox = Provider.of<UserHiveBox>(context, listen: false);
    final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

    final currentToken = userBox.token;
    final localEmail = userBox.email;

    final headers = {
      'Authorization': 'Bearer $currentToken',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final url =
        Uri.parse('$kServerURL/user/group/exit-group/?email=$localEmail');

    final body = {
      'groupID': groupId,
    };

    final response = await http.post(
      url,
      body: body,
      headers: headers,
    );

    final data = json.decode(response.body);

    final token = data['token'] ?? currentToken;
    final message = data['message'] ?? '';
    userBox.saveToken(token);

    if (response.statusCode == 200) {
      print('User exited Group successfully');

      final group = chatBox.getChat(groupId)!;

      group.exitGroup(userId: userBox.id);
    } else {
      print('request failed with status: ${response.statusCode}');
    }
    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  } on Exception catch (e) {
    print(e);
  }
}

//Admin Group API
//
Future<void> addGroupParticipants({
  required BuildContext context,
  required String groupId,
  required List<String> newParticipants,
}) async {
  final userBox = Provider.of<UserHiveBox>(context, listen: false);
  final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

  final currentToken = userBox.token;
  final localEmail = userBox.email;

  final url =
      Uri.parse('$kServerURL/user/group/add-participants/?email=$localEmail');

  final body = {
    'groupID': groupId,
    'participants': jsonEncode(newParticipants),
  };
  final headers = {
    'Authorization': 'Bearer $currentToken',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  final response = await http.post(
    url,
    body: body,
    headers: headers,
  );

  final data = json.decode(response.body);

  final token = data['token'] ?? currentToken;
  final message = data['message'] ?? '';

  userBox.saveToken(token);

  if (response.statusCode == 200) {
    print('Participants where added successfully');

    final group = chatBox.getChat(groupId)!;
    group.addParticipants(chats: newParticipants, adminId: userBox.id);

    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  } else {
    print('request failed with status: ${response.statusCode}');
    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  }
}

Future<void> removeGroupParticipants({
  required BuildContext context,
  required String groupId,
  required List<String> participants,
}) async {
  final userBox = Provider.of<UserHiveBox>(context, listen: false);
  final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

  final currentToken = userBox.token;
  final localEmail = userBox.email;

  final url = Uri.parse(
      '$kServerURL/user/group/remove-participants/?email=$localEmail');

  final body = {
    'groupID': groupId,
    'participants': jsonEncode(participants),
  };

  final headers = {
    'Authorization': 'Bearer $currentToken',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  final response = await http.post(
    url,
    body: body,
    headers: headers,
  );

  final data = json.decode(response.body);

  final token = data['token'] ?? currentToken;
  final message = data['message'] ?? '';

  userBox.saveToken(token);

  if (response.statusCode == 200) {
    print('Participants where removed successfully');

    final group = chatBox.getChat(groupId)!;

    for (final participant in participants) {
      final chat = chatBox.getChat(participant)!;
      group.removeParticipant(chat: chat, adminId: userBox.id);
    }

    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  } else {
    print('request failed with status: ${response.statusCode}');
    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  }
}

Future<void> changeGroupDescription({
  required BuildContext context,
  required String groupId,
  required String description,
}) async {
  final userBox = Provider.of<UserHiveBox>(context, listen: false);
  final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

  final currentToken = userBox.token;
  final localEmail = userBox.email;

  final url =
      Uri.parse('$kServerURL/user/group/change-description/?email=$localEmail');

  final body = {
    'groupID': groupId,
    'description': description,
  };
  final headers = {
    'Authorization': 'Bearer $currentToken',
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  final response = await http.post(
    url,
    body: body,
    headers: headers,
  );

  final data = json.decode(response.body);

  final token = data['token'] ?? currentToken;
  final message = data['message'] ?? '';

  userBox.saveToken(token);

  if (response.statusCode == 200) {
    print('group discription was changed successfully');

    final group = chatBox.getChat(groupId)!;

    group.changeDescription(newDescription: description, adminId: userBox.id);

    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  } else {
    print('request failed with status: ${response.statusCode}');
    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  }
}

Future<void> changeGroupOnlyAdlin({
  required BuildContext context,
  required String groupId,
  required bool onlyAdmins,
}) async {
  final userBox = Provider.of<UserHiveBox>(context, listen: false);
  final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

  final currentToken = userBox.token;
  final localEmail = userBox.email;

  final url =
      Uri.parse('$kServerURL/user/group/only-admins/?email=$localEmail');

  final body = {
    'groupID': groupId,
    'onlyAdmins': onlyAdmins,
  };
  final headers = {
    'Authorization': 'Bearer $currentToken',
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  final response = await http.post(
    url,
    body: body,
    headers: headers,
  );

  final data = json.decode(response.body);

  final token = data['token'] ?? currentToken;
  final message = data['message'] ?? '';

  userBox.saveToken(token);

  if (response.statusCode == 200) {
    print('group onlyAdmins value was changed successfully to $onlyAdmins');

    final group = chatBox.getChat(groupId)!;

    group.changeAdminOnlyTo(onlyAdmins);

    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  } else {
    print('request failed with status: ${response.statusCode}');
    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  }
}

Future<void> makeParticipantsAdmin({
  required BuildContext context,
  required String groupId,
  required List<String> newAdmins,
}) async {
  final userBox = Provider.of<UserHiveBox>(context, listen: false);
  final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

  final currentToken = userBox.token;
  final localEmail = userBox.email;

  final url = Uri.parse('$kServerURL/user/group/add-admins/?email=$localEmail');

  final body = {
    'groupID': groupId,
    'participants': jsonEncode(newAdmins),
  };
  final headers = {
    'Authorization': 'Bearer $currentToken',
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  final response = await http.post(
    url,
    body: body,
    headers: headers,
  );

  final data = json.decode(response.body);

  final token = data['token'] ?? currentToken;
  final message = data['message'] ?? '';

  userBox.saveToken(token);

  if (response.statusCode == 200) {
    print('group new admins were successfully added');

    final group = chatBox.getChat(groupId)!;

    group.addAdmins(chats: newAdmins, adminId: userBox.id);

    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  } else {
    print('request failed with status: ${response.statusCode}');
    // ignore: use_build_context_synchronously
    showPopupMessage(context, message);
  }
}
