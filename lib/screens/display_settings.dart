import 'package:blue_chat_v1/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DisplaySettings extends StatefulWidget {
  const DisplaySettings({super.key});

  static const String id = 'display_settings';

  @override
  State<DisplaySettings> createState() => _DisplaySettingsState();
}

class _DisplaySettingsState extends State<DisplaySettings> {

  String? selectedOption;

  selected(String? val) {
    setState(() {
      selectedOption = val;
    });
    print('setState $selectedOption');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Display'),
        ),
        body: Column(
          children: [
            ListTile(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return OptionDialogButton(
                      onOptionSelected: (String? selectedOption) {
                        Navigator.pop(context, selectedOption);
                        selected(selectedOption);
                      },
                    );
                  },
                );
              },
              leading: const Padding(
                padding: EdgeInsets.all(5.0),
                child: Icon(
                  Icons.sunny,
                  size: 28.0,
                ),
              ),
              title: const Text('Theme'),
              subtitle: Text('$selectedOption'),
            ),
            ListTile(
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                if (result == null) {
                  return;
                } else {


                  Provider.of<ConstantAppData>(context, listen: false).changeWallPaper(result.files.first.path);
                  // final List<String> paths = [];

                  // for (PlatformFile file in result.files) {
                  //   paths.add(file.path!);
                  // }

                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => PreviewScreen(
                  //       mediaPaths: paths,
                  //     ),
                  //   ),
                  // );
                }
              },
              leading: const Padding(
                padding: EdgeInsets.all(5.0),
                child: Icon(
                  Icons.wallpaper_rounded,
                  size: 28.0,
                ),
              ),
              title: Text('Wallpaper'),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionDialogButton extends StatefulWidget {
  final ValueChanged<String?>? onOptionSelected;

  const OptionDialogButton({Key? key, this.onOptionSelected}) : super(key: key);

  @override
  _OptionDialogButtonState createState() => _OptionDialogButtonState();
}

class _OptionDialogButtonState extends State<OptionDialogButton> {
  String? selectedOption;

  setSelectedRadio(String? val) {
    setState(() {
      selectedOption = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose your theme'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            contentPadding: const EdgeInsets.all(0.0),
            title: const Text('Light theme'),
            value: 'Light theme',
            groupValue: selectedOption,
            onChanged: (value) {
              setSelectedRadio(value);
            },
          ),
          RadioListTile<String>(
            title: const Text('Dark theme'),
            contentPadding: const EdgeInsets.all(0.0),
            value: 'Dark theme',
            groupValue: selectedOption,
            onChanged: (value) {
              setSelectedRadio(value);
            },
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (widget.onOptionSelected != null) {
              widget.onOptionSelected!(selectedOption);
            }
          },
          child: Text('Select'),
        ),
      ],
    );
  }
}
