import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
// import 'package:provider/provider.dart';

class PhotoProvider extends ChangeNotifier {
  List<AssetPathEntity>? _pathList;
  List<AssetEntity> _checked = [];

  List<AssetPathEntity>? get assetPathList => _pathList;
  List<AssetEntity> get checked => _checked;

  Future<void> refreshGalleryList() async {
    print('2');
    _pathList = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    print('3 $_pathList');
    notifyListeners();
  }


  void addToChecked(AssetEntity asset) {
    if (!_checked.contains(asset)) {
      _checked.add(asset);
      notifyListeners();
    }
  }

  void removeFromChecked(AssetEntity asset) {
    if (_checked.contains(asset)) {
      _checked.remove(asset);
      notifyListeners();
    }
  }

  void clearChecked() {
    _checked.clear();
    notifyListeners();
  }
}