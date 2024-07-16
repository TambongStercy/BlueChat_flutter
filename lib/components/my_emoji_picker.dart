import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

class MyEmojiPicker extends StatefulWidget {
  final bool emojiShowing;
  final Function() onBackspacePressed;
  final TextEditingController textEditingController;
  final Function addEmoji;
  final String draft;

  MyEmojiPicker({
    required this.emojiShowing,
    required this.onBackspacePressed,
    required this.textEditingController,
    required this.draft,
    required this.addEmoji,
  });

  @override
  State<MyEmojiPicker> createState() => _MyEmojiPickerState();
}

class _MyEmojiPickerState extends State<MyEmojiPicker> {
  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !widget.emojiShowing,
      child: SizedBox(
        height: 250,
        child: EmojiPicker(
          textEditingController: widget.textEditingController,
          onBackspacePressed: widget.onBackspacePressed,
          onEmojiSelected: (category, emoji) {
            widget.addEmoji(emoji.emoji);
          },
          config: Config(
            height: 256,
            // bgColor: const Color(0xFFF2F2F2),
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              backgroundColor: const Color(0xFFF2F2F2),
              // Issue: https://github.com/flutter/flutter/issues/28894
              emojiSizeMax: 28 *
                  (foundation.defaultTargetPlatform == TargetPlatform.iOS
                      ? 1.20
                      : 1.0),
            ),
            swapCategoryAndBottomBar: false,
            skinToneConfig: const SkinToneConfig(),
            categoryViewConfig: const CategoryViewConfig(),
            bottomActionBarConfig: const BottomActionBarConfig(),
            searchViewConfig: const SearchViewConfig(),
          ),
          // Config(
          //   columns: 7,
          //   emojiSizeMax: 32 *
          //       (foundation.defaultTargetPlatform == TargetPlatform.iOS
          //           ? 1.30
          //           : 1.0),
          //   verticalSpacing: 0,
          //   horizontalSpacing: 0,
          //   gridPadding: EdgeInsets.zero,
          //   initCategory: Category.RECENT,
          //   bgColor: const Color(0xFFF2F2F2),
          //   indicatorColor: Colors.blue,
          //   iconColor: Colors.grey,
          //   iconColorSelected: Colors.blue,
          //   backspaceColor: Colors.blue,
          //   skinToneDialogBgColor: Colors.white,
          //   skinToneIndicatorColor: Colors.grey,
          //   enableSkinTones: true,
          //   recentTabBehavior: RecentTabBehavior.RECENT,
          //   recentsLimit: 28,
          //   replaceEmojiOnLimitExceed: false,
          //   noRecents: const Text(
          //     'No Recents',
          //     style: TextStyle(fontSize: 20, color: Colors.black26),
          //     textAlign: TextAlign.center,
          //   ),
          //   loadingIndicator: const SizedBox.shrink(),
          //   tabIndicatorAnimDuration: kTabScrollDuration,
          //   categoryIcons: const CategoryIcons(),
          //   buttonMode: ButtonMode.MATERIAL,
          //   checkPlatformCompatibility: true,
          // ),
        ),
      ),
    );
  }
}
