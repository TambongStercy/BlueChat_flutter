import 'dart:convert';

import 'package:http/http.dart' as http;

void fetchBlogs() async {
  const url = 'https://intent-kit-16.hasura.app/api/blogs';
  const adminSecret = 'the key here';
  
  try {
    final response = await http.get(Uri.parse(url),headers: {
      'x-hasura-admin-secret': adminSecret,
    });

    // Let's assume that below is the json the api responds with 
    // {
    //   'message': 'my money is finished',
    //   'sender': 'Sterling Black',
    // }

    
    final data = json.decode(response.body);
    final message = data['message'];
    final sender = data['sender'];

    if(response.statusCode == 200){
      print(message);
      // my money is finished
      print(sender);
      // Sterling Black
    }else{
      print('Request failed with status code: ${response.statusCode}');
    }
  } on Exception catch (e) {
    // TODO
    print(e);
  }
}
