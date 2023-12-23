import 'package:flutter/material.dart';
import 'package:blue_chat_v1/classes/photo_provider.dart';
import 'package:blue_chat_v1/classes/image_picker_view.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class AlbumPageView extends StatefulWidget {
  static const String id = 'album_screen';
  @override
  _AlbumPageViewState createState() => _AlbumPageViewState();
}

class _AlbumPageViewState extends State<AlbumPageView> {
  late PhotoProvider photoProvider;
  AssetPathEntity? assetsPathEntity;

  @override
  void initState() {
    super.initState();
    // photoProvider = Provider.of<PhotoProvider>(context, listen: true);
    Provider.of<PhotoProvider>(context, listen: false).refreshGalleryList().then((value) {
      print('7s');
      setState(() {
        assetsPathEntity = Provider.of<PhotoProvider>(context, listen: false).assetPathList![0];
      });
      print('adding $assetsPathEntity');
    });
      print('1 $assetsPathEntity ');

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(assetsPathEntity?.name ?? ''),
      ),
      body: Consumer<PhotoProvider>(
        builder: (context, provider, child) {
          if (provider.assetPathList == null) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.assetPathList!.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(provider.assetPathList![index].name),
                        onTap: () {
                          setState(() {
                            assetsPathEntity = provider.assetPathList![index];
                          });
                        },
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: assetsPathEntity != null
                      ? ImagePickerView(
                          path: assetsPathEntity!,
                          addToChecked: (asset) {
                            provider.addToChecked(asset);
                          },
                          removeFromChecked: (asset) {
                            provider.removeFromChecked(asset);
                          },
                        )
                      : const Center(child: Text('No assets found.')),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: Consumer<PhotoProvider>(
        builder: (context, provider, child) {
          return provider.checked.length > 0
              ? FloatingActionButton(
                  onPressed: () {
                    // do something with selected items
                    provider.clearChecked();
                  },
                  child: Icon(Icons.check),
                )
              : SizedBox();
        },
      ),
    );
  }
}