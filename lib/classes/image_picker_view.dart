import 'package:flutter/material.dart';
import 'package:blue_chat_v1/classes/photo_provider.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';

class ImagePickerView extends StatefulWidget {
  final AssetPathEntity path;
  final Function(AssetEntity) addToChecked;
  final Function(AssetEntity) removeFromChecked;

  ImagePickerView({
    required this.path,
    required this.addToChecked,
    required this.removeFromChecked,
  });

  @override
  _ImagePickerViewState createState() => _ImagePickerViewState();
}

class _ImagePickerViewState extends State<ImagePickerView> {
  List<AssetEntity> ?_assetList;
  ScrollController ?_scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // WidgetsBinding.instance.addPostFrameCallback((_){
    //   // Async method here
    // });
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final assetList = await widget.path.getAssetListRange(
      start: 0,
      end: await widget.path.assetCountAsync - 1,
      // refresh:
    );
    if (mounted) {
      setState(() {
        _assetList = assetList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _assetList?.length,
      itemBuilder: (context, index) {
        return FutureBuilder(
          future: _loadAssets(),
          builder: (context, snapshot) {
            if(snapshot.hasData||_assetList!=null){
              return GestureDetector(
                onTap: () {
                  if (widget.addToChecked != null) {
                    widget.addToChecked(_assetList![index]);
                  }
                },
                onLongPress: () {
                  if (widget.removeFromChecked != null) {
                    widget.removeFromChecked(_assetList![index]);
                  }
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image(
                        image: AssetEntityImageProvider(_assetList![index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                    widget.removeFromChecked != null &&
                            widget.addToChecked != null
                        ? Positioned(
                            top: 0,
                            right: 0,
                            child: Checkbox(
                              value: Provider.of<PhotoProvider>(context)
                                  .checked
                                  .contains(_assetList![index]),
                              onChanged: (bool? value) {
                                if (value != null) {
                                  if (value) {
                                    widget.addToChecked(_assetList![index]);
                                  } else {
                                    widget.removeFromChecked(_assetList![index]);
                                  }
                                }
                              },
                            ),
                          )
                        : const SizedBox(),
                  ],
                ),
              );
              
            }else{
              return const Center(child: CircularProgressIndicator(),);
            }
          }
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }
}