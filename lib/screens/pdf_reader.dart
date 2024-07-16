import 'dart:async';
import 'dart:io';
import 'package:blue_chat_v1/api_call.dart';
import 'package:blue_chat_v1/classes/levels.dart';
// import 'package:blue_chat_v1/components/course_tile.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Signature for the [SearchToolbar.onTap] callback.
typedef SearchTapCallback = void Function(Object item);

/// SearchToolbar widget.
class SearchToolbar extends StatefulWidget {
  ///Describes the search toolbar constructor.
  SearchToolbar({
    required this.controller,
    required this.onTap,
    this.showTooltip = true,
    super.key,
  });

  /// Indicates whether the tooltip for the search toolbar items should be shown or not.
  final bool showTooltip;

  /// An object that is used to control the [SfPdfViewer].
  final PdfViewerController controller;

  /// Called when the search toolbar item is selected.
  final SearchTapCallback onTap;

  @override
  SearchToolbarState createState() => SearchToolbarState();
}

/// State for the SearchToolbar widget.
class SearchToolbarState extends State<SearchToolbar> {
  int _textLength = 0;

  /// Define the focus node. To manage the life cycle, create the FocusNode in the initState method, and clean it up in the dispose method.
  late FocusNode _focusNode;

  /// An object that is used to control the Text Form Field.
  final TextEditingController _editingController = TextEditingController();

  Timer? _noMatchTimer;

  /// An object that is used to retrieve the text search result.
  PdfTextSearchResult _pdfTextSearchResult = PdfTextSearchResult();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
  }

  ///Clear the text search result.
  void clearSearch() {
    _pdfTextSearchResult.clear();
    _pdfTextSearchResult.removeListener(_onTextSearchResultChanged);
    _noMatchTimer?.cancel();
    _pdfTextSearchResult = PdfTextSearchResult();
  }

  void _onTextSearchResultChanged() {
    setState(() {
      print('Done!!!');
    });
  }

  void onChanged(text) {
    if (_textLength < _editingController.value.text.length) {
      _textLength = _editingController.value.text.length;
    }
    if (_editingController.value.text.length < _textLength) {
      setState(() {});
    }
    if (_editingController.value.text.length > 0) {
      _pdfTextSearchResult =
          widget.controller.searchText(_editingController.text);

      _pdfTextSearchResult.addListener(_onTextSearchResultChanged);

      _noMatchTimer = Timer(const Duration(seconds: 5), () {
        // Code to run after 5 seconds
        if (_pdfTextSearchResult.totalInstanceCount == 0) {
          widget.onTap.call('onSubmit');
        }
      });
    } else {
      clearSearch();
    }
  }

  void onSubmit(value) async {
    _pdfTextSearchResult =
        widget.controller.searchText(_editingController.text);

    _pdfTextSearchResult.addListener(_onTextSearchResultChanged);

    _noMatchTimer = Timer(const Duration(seconds: 5), () {
      // Code to run after 5 seconds
      if (_pdfTextSearchResult.totalInstanceCount == 0) {
        widget.onTap.call('onSubmit');
      }
    });
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    clearSearch();
    _focusNode.dispose();
    super.dispose();
    print('dispose');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Color(0xFFFFFF).withOpacity(0.54),
              size: 24,
            ),
            onPressed: () {
              widget.onTap.call('Cancel Search');
              _editingController.clear();
              _pdfTextSearchResult.clear();
            },
          ),
        ),
        Flexible(
          child: TextFormField(
            cursorColor: Colors.white10,
            style: TextStyle(
                color: Color(0xf2f2f2).withOpacity(0.87), fontSize: 16),
            enableInteractiveSelection: false,
            focusNode: _focusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            controller: _editingController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Find...',
              hintStyle: TextStyle(color: Color(0xFFFFFF).withOpacity(0.34)),
            ),
            onChanged: (text) {
              onChanged(text);
            },
            onFieldSubmitted: (value) {
              onSubmit(value);
            },
          ),
        ),
        Visibility(
          visible: _editingController.text.isNotEmpty,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(
                Icons.clear,
                color: Color.fromRGBO(255, 255, 255, 0.884),
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _editingController.clear();
                  clearSearch();
                  widget.controller.clearSelection();
                  _focusNode.requestFocus();
                });
                widget.onTap.call('Clear Text');
              },
              tooltip: widget.showTooltip ? 'Clear Text' : null,
            ),
          ),
        ),
        Row(
          children: [
            Text(
              '${_pdfTextSearchResult.currentInstanceIndex} of ${_pdfTextSearchResult.totalInstanceCount}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(
                  Icons.navigate_before,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  setState(() {
                    _pdfTextSearchResult.previousInstance();
                  });
                  widget.onTap.call('Previous Instance');
                },
                tooltip: widget.showTooltip ? 'Previous' : null,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(
                  Icons.navigate_next,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  setState(() {
                    widget.controller.clearSelection();
                    _pdfTextSearchResult.nextInstance();
                  });
                  widget.onTap.call('Next Instance');
                },
                tooltip: widget.showTooltip ? 'Next' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PdfReader extends StatefulWidget {
  const PdfReader(
      {super.key,
      required this.question,
      required this.course,
      required this.semester,
      required this.level});

  final Question question;
  final Course course;
  final String semester;
  final String level;

  static const String id = 'pdf-reader';

  @override
  State<PdfReader> createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SearchToolbarState> _textSearchKey = GlobalKey();

  bool _showToast = false;
  bool _showScrollHead = true;
  bool _showSearchToolbar = false;

  // Ensure the entry history of text search.
  LocalHistoryEntry? _localHistoryEntry;

  void _ensureHistoryEntry() {
    if (_localHistoryEntry == null) {
      final ModalRoute<Object?>? route = ModalRoute.of(context);
      if (route != null) {
        _localHistoryEntry =
            LocalHistoryEntry(onRemove: _handleHistoryEntryRemoved);
        route.addLocalHistoryEntry(_localHistoryEntry!);
      }
    }
  }

  void _handleHistoryEntryRemoved() {
    _textSearchKey.currentState?.clearSearch();
    setState(() {
      _showSearchToolbar = false;
      _localHistoryEntry = null;
    });
  }


  void updatePage() {
    if (mounted) {
      print('updating pdfPage');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final question = widget.question;
    final level = widget.level;
    final semester = widget.semester;
    final courseCode = course.courseCode;
    final courseTitle = course.title;
    final questionTitle =
        '${widget.question.name} ${widget.question.type} ${widget.question.year}';
    final path = widget.question.path;
    final pdfFile = File(path);

    
    Provider.of<Updater>(context, listen: false)
        .addUpdater(PdfReader.id, updatePage);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        body: FutureBuilder<void>(
            future: downloadQuestion(
              context: context,
              course: course,
              question: question,
              level: level,
              semester: semester,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                     Center(
                       child: CircularProgressIndicator(
                        color: Colors.green,
                                         ),
                     ),
                  ],
                ); // Show a loading indicator.
              } else {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (pdfFile.existsSync())
                      Container(
                        padding: const EdgeInsets.only(top: 5.0),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15.0),
                            bottomRight: Radius.circular(15.0),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Center(
                              child: Text(
                                courseCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _showSearchToolbar
                                ? AppBar(
                                    elevation: 0,
                                    flexibleSpace: SearchToolbar(
                                      key: _textSearchKey,
                                      showTooltip: true,
                                      controller: _pdfViewerController,
                                      onTap: (Object toolbarItem) async {
                                        if (toolbarItem.toString() ==
                                            'Cancel Search') {
                                          setState(() {
                                            _showSearchToolbar = false;
                                            _showScrollHead = true;
                                            if (Navigator.canPop(context)) {
                                              Navigator.maybePop(context);
                                            }
                                          });
                                        }
                                        if (toolbarItem.toString() ==
                                            '(text){}') {
                                          setState(() {
                                            _showToast = true;
                                          });
                                          await Future.delayed(
                                              const Duration(seconds: 2));
                                          setState(() {
                                            _showToast = false;
                                          });
                                        }
                                      },
                                    ),
                                    automaticallyImplyLeading: false,
                                    backgroundColor: Colors.blue,
                                  )
                                : AppBar(
                                    elevation: 0,
                                    title: Text(
                                      questionTitle,
                                    ),
                                    actions: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.search,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showScrollHead = false;
                                            _showSearchToolbar = true;
                                            _ensureHistoryEntry();
                                          });
                                        },
                                      ),
                                    ],
                                    backgroundColor: Colors.blue,
                                    leadingWidth: 30.0,
                                  ),
                          ],
                        ),
                      ),
                    if (pdfFile.existsSync())
                      Expanded(
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15.0),
                              topRight: Radius.circular(15.0),
                            ),
                          ),
                          margin: const EdgeInsets.only(
                            left: 20.0,
                            right: 20.0,
                            bottom: 10.0,
                            top: 25.0,
                          ),
                          child: Stack(
                            children: [
                              SfPdfViewer.file(
                                File(path),
                                controller: _pdfViewerController,
                                canShowScrollHead: _showScrollHead,
                              ),
                              Visibility(
                                visible: _showToast,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Flex(
                                    direction: Axis.horizontal,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.only(
                                            left: 15,
                                            top: 7,
                                            right: 15,
                                            bottom: 7),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[600],
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(16.0),
                                          ),
                                        ),
                                        child: const Text(
                                          'No matches found',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!pdfFile.existsSync())
                      const Center(
                        child: Text(
                          'This file does not exist 😔',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black38,
                          ),
                        ),
                      ),
                  ],
                );
              }
            }),
      ),
    );
  }
}
