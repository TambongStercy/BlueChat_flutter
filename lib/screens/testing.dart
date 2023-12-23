import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class StickyFirstItemListView extends StatefulWidget {
  @override
  _StickyFirstItemListViewState createState() =>
      _StickyFirstItemListViewState();
}

class _StickyFirstItemListViewState extends State<StickyFirstItemListView> {
  late ScrollController _scrollController;
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_showAppBar) {
        setState(() {
          _showAppBar = false;
        });
      }
    } else {
      if (!_showAppBar) {
        setState(() {
          _showAppBar = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Sticky Item', style: TextStyle(color: Colors.black45),),
              background: Image.asset(
                'assets/images/BG1.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return _StickyItem(scrollController: _scrollController);
                } else {
                  return ListTile(
                    title: Text('Item $index'),
                  );
                }
              },
              childCount: 50, // Replace with your actual item count
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyItem extends StatefulWidget {
  final ScrollController scrollController;

  const _StickyItem({required this.scrollController});
  @override
  _StickyItemState createState() => _StickyItemState();
}

class _StickyItemState extends State<_StickyItem> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (widget.scrollController.offset < 200) {
      double opacity = 1.0 - (widget.scrollController.offset / 200);
      if (opacity != _opacity) {
        setState(() {
          _opacity = opacity;
        });
      }
    } else if (_opacity != 0.0) {
      setState(() {
        _opacity = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _opacity,
      child: ListTile(
        title: Text('Visible Item'),
      ),
    );
  }
}
