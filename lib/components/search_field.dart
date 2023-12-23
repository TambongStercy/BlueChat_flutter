import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required FocusNode focusNode,
    required this.onCancel,
    required this.onChanged,
  }) : _focusNode = focusNode;

  final FocusNode _focusNode;
  final Function onCancel;
  final Function onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _focusNode,
      textAlignVertical: TextAlignVertical.center,
      cursorColor: Colors.white,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        isCollapsed: true,
        fillColor: Colors.white,
        hoverColor: Colors.black,
        prefixIcon: IconButton(
          padding: const EdgeInsets.only(right: 20.0),
          onPressed: () {
            onCancel();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        prefixIconColor: Colors.white,
        hintText: 'Search a Chat.',
        hintStyle: const TextStyle(color: Colors.white30),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 0.0,
          horizontal: 0.0,
        ),
        disabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent, width: 0.0),
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent, width: 0.0),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent, width: 0.0),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent, width: 1.0),
        ),
      ),
      onChanged: (newValue) {
        print(newValue);
        onChanged(newValue);
      },
    );
  }
}
