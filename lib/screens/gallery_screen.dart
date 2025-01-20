import 'dart:io';
import 'dart:typed_data';
import 'package:blue_chat_v1/components/video_trim.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class AlbumsPage extends StatefulWidget {
  static const id = 'album_gallery';

  @override
  _AlbumsPageState createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  List<AssetPathEntity> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final albums =
        await PhotoManager.getAssetPathList(type: RequestType.common);
    final cameraAlbum =
        albums.firstWhere((album) => album.name.toLowerCase() == 'camera');
    final allMediaAlbum =
        AssetPathEntity(id: '', name: 'All Media', type: RequestType.all);
    final allVideosAlbum =
        AssetPathEntity(id: '', name: 'All Videos', type: RequestType.video);
    final otherAlbums =
        albums.where((album) => album.name.toLowerCase() != 'camera').toList();
    otherAlbums.sort((a, b) => a.name.compareTo(b.name));

    setState(() {
      _albums = [cameraAlbum, allMediaAlbum, allVideosAlbum, ...otherAlbums];
      _isLoading = false;
    });
  }

  Future<Uint8List?> _loadFirstThumbnail(AssetPathEntity album) async {
    List<AssetEntity> mediaFiles;
    if (album.name == 'All Media') {
      final albums =
          await PhotoManager.getAssetPathList(type: RequestType.common);
      mediaFiles = await Future.wait(
              albums.map((a) => a.getAssetListRange(start: 0, end: 1)))
          .then((value) => value.expand((x) => x).toList());
    } else if (album.name == 'All Videos') {
      final albums =
          await PhotoManager.getAssetPathList(type: RequestType.video);
      mediaFiles = await Future.wait(
              albums.map((a) => a.getAssetListRange(start: 0, end: 1)))
          .then((value) => value.expand((x) => x).toList());
    } else {
      mediaFiles = await album.getAssetListRange(start: 0, end: 1);
    }
    return mediaFiles.isNotEmpty
        ? mediaFiles.first.thumbnailDataWithSize(ThumbnailSize(200, 200))
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Albums')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
              itemCount: _albums.length,
              itemBuilder: (context, index) {
                final album = _albums[index];
                return FutureBuilder(
                  future: _loadFirstThumbnail(album),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MediaGallery(album: album),
                          ),
                        ),
                        child: GridTile(
                          child:
                              Image.memory(snapshot.data!, fit: BoxFit.cover),
                          footer: GridTileBar(
                            backgroundColor: Colors.black54,
                            title: Text(album.name),
                          ),
                        ),
                      );
                    } else {
                      return Container(
                        color: Colors.black45,
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}

class MediaGallery extends StatefulWidget {
  final AssetPathEntity album;

  MediaGallery({required this.album});

  @override
  _MediaGalleryState createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> {
  final List<AssetEntity> _mediaFiles = [];
  Map<String, List<AssetEntity>> _groupedMediaFiles = {};
  final Set<AssetEntity> _selectedMedia = {};
  bool _selectionMode = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 6;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMediaFiles();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMediaFiles() async {
    setState(() {
      _isLoading = true;
    });

    List<AssetEntity> mediaFiles;
    if (widget.album.name == 'All Media') {
      mediaFiles = await _getAllMedia();
    } else if (widget.album.name == 'All Videos') {
      mediaFiles = await _getAllVideos();
    } else {
      mediaFiles = await widget.album
          .getAssetListPaged(page: _currentPage, size: _pageSize);
    }

    mediaFiles.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

    _groupMediaFilesByDate(mediaFiles);

    setState(() {
      _mediaFiles.addAll(mediaFiles);
      _isLoading = false;
    });
  }

  Future<List<AssetEntity>> _getAllMedia() async {
    final albums =
        await PhotoManager.getAssetPathList(type: RequestType.common);
    final Set<AssetEntity> mediaFiles = {};

    for (var album in albums) {
      final List<AssetEntity> assets =
          await album.getAssetListPaged(page: _currentPage, size: _pageSize);
      mediaFiles.addAll(assets);
    }

    return mediaFiles.toList();
  }

  Future<List<AssetEntity>> _getAllVideos() async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.video);
    final Set<AssetEntity> videoFiles = {};

    for (var album in albums) {
      final List<AssetEntity> assets =
          await album.getAssetListPaged(page: _currentPage, size: _pageSize);
      videoFiles.addAll(assets);
    }

    return videoFiles.toList();
  }

  void _groupMediaFilesByDate(List<AssetEntity> mediaFiles) {
    Map<String, List<AssetEntity>> groupedMedia = {};

    DateTime now = DateTime.now();
    for (var asset in mediaFiles) {
      DateTime date = asset.createDateTime;
      String groupKey = '';

      if (date.isAfter(now.subtract(Duration(days: 7)))) {
        groupKey = 'Recent';
      } else if (date.isAfter(now.subtract(Duration(days: 14)))) {
        groupKey = 'Last Week';
      } else if (date.isAfter(now.subtract(Duration(days: 30)))) {
        groupKey = DateFormat('MMMM').format(date);
      } else if (date.isAfter(now.subtract(Duration(days: 60)))) {
        groupKey = DateFormat('MMMM').format(date);
      } else if (date.isAfter(now.subtract(Duration(days: 90)))) {
        groupKey = DateFormat('MMMM').format(date);
      } else if (date.isAfter(now.subtract(Duration(days: 365)))) {
        groupKey = DateFormat('MMMM').format(date);
      } else {
        groupKey = DateFormat('yyyy').format(date);
      }

      if (!groupedMedia.containsKey(groupKey)) {
        groupedMedia[groupKey] = [];
      }
      groupedMedia[groupKey]!.add(asset);
    }

    setState(() {
      _groupedMediaFiles = groupedMedia;
    });
  }

  Future<Uint8List?> _loadThumbnail(AssetEntity asset) async {
    return await asset.thumbnailDataWithSize(ThumbnailSize(200, 200));
  }

  Future<void> _generateThumbnailsInBackground() async {
    await FlutterIsolate.spawn(_generateThumbnails, _mediaFiles);
  }

  static void _generateThumbnails(List<AssetEntity> mediaFiles) async {
    for (var asset in mediaFiles) {
      await asset.thumbnailDataWithSize(ThumbnailSize(200, 200));
    }
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 500 && !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _currentPage += 1;
      });
      _loadMoreMediaFiles();
    }
  }

  Future<void> _loadMoreMediaFiles() async {
    List<AssetEntity> mediaFiles;
    if (widget.album.name == 'All Media') {
      mediaFiles = await _getAllMedia();
    } else if (widget.album.name == 'All Videos') {
      mediaFiles = await _getAllVideos();
    } else {
      mediaFiles = await widget.album
          .getAssetListPaged(page: _currentPage, size: _pageSize);
    }

    mediaFiles.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

    _groupMediaFilesByDate(mediaFiles);

    setState(() {
      _mediaFiles.addAll(mediaFiles);
      _isLoadingMore = false;
    });
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedMedia.contains(asset)) {
        _selectedMedia.remove(asset);
      } else {
        _selectedMedia.add(asset);
      }
      if (_selectedMedia.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMedia.clear();
      _selectionMode = false;
    });
  }

  void _previewSelectedMedias() async {
    final List<String> paths = [];
    final List<File> files = [];
    for (var asset in _selectedMedia) {
      final file = await asset.file;
      if (file == null) continue;
      final path = file.path;


      paths.add(path);
      files.add(file);

      print('Media selected ${path}');
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (builder) => TrimmerPageView(
          mediaFiles: files,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode
            ? '${_selectedMedia.length} selected'
            : widget.album.name),
        leading: _selectionMode
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _clearSelection,
              )
            : null,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Scrollbar(
                  controller: _scrollController,
                  thickness: 12.0,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _groupedMediaFiles.length,
                    itemBuilder: (context, index) {
                      String key = _groupedMediaFiles.keys.elementAt(index);
                      List<AssetEntity> assets = _groupedMediaFiles[key]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              key,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                            ),
                            itemCount: assets.length,
                            itemBuilder: (context, index) {
                              return FutureBuilder(
                                future: _loadThumbnail(assets[index]),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      snapshot.hasData) {
                                    bool isSelected =
                                        _selectedMedia.contains(assets[index]);
                                    return GestureDetector(
                                      onTap: () async {
                                        if (_selectionMode) {
                                          _toggleSelection(assets[index]);
                                        } else {
                                          final file = await assets[index].file;
                                          final path = file?.path;
                                          if (file == null || path == null) {
                                            return;
                                          }

                                          print('Media selected ${path}');
                                          // ignore: use_build_context_synchronously
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  TrimmerPageView(
                                                mediaFiles: [file],
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      onLongPress: () {
                                        setState(() {
                                          _selectionMode = true;
                                          _toggleSelection(assets[index]);
                                        });
                                      },
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          GridTile(
                                            footer: (assets[index].type ==
                                                    AssetType.video)
                                                ? const Align(
                                                    alignment:
                                                        Alignment.bottomLeft,
                                                    child: Icon(
                                                      Icons.videocam_outlined,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : null,
                                            child: Image.memory(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          if (isSelected)
                                            Positioned.fill(
                                              child: Container(
                                                color: Colors.blue
                                                    .withOpacity(0.5),
                                                child: Icon(Icons.check,
                                                    color: Colors.white),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return Container(
                                      color: Colors.black45,
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (_isLoadingMore)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
      floatingActionButton: _selectionMode
          ? FloatingActionButton(
              onPressed: _previewSelectedMedias,
              child: const Icon(Icons.arrow_forward_outlined),
            )
          : null,
    );
  }
}
