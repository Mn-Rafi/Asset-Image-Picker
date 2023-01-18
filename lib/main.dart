import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;
  List<AssetEntity>? _entities;
  AssetPathEntity? _path;
  int _totalEntitiesCount = 0;
  int _sizePerPage = 50;
  bool _isLoadingMore = false;
  bool _hasMoreToLoad = true;
  int _page = 0;
  List<AssetEntity> _assetsSelected = [];

  final FilterOptionGroup _filterOptionGroup = FilterOptionGroup(
    imageOption: const FilterOption(
      sizeConstraint: SizeConstraint(ignoreSize: true),
    ),
  );

  _fetchAssets() async {
    setState(() {
      _isLoading = true;
    });
    await PhotoManager.requestPermissionExtend().then((_ps) async {
      if (!mounted) {
        return;
      }
      if (!_ps.hasAccess) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permission is not accessible.')));
        return;
      }
      if (_ps.isAuth) {
        await PhotoManager.setIgnorePermissionCheck(true);
        final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          filterOption: _filterOptionGroup,
        );
        if (paths.isNotEmpty)
          setState(() {
            _path = paths.first;
          });
        if (_path != null) _totalEntitiesCount = await _path!.assetCountAsync;
        final List<AssetEntity> entities = await _path!.getAssetListPaged(
          page: 0,
          size: _sizePerPage,
        );
        setState(() {
          _entities = entities;
          _isLoading = false;
          _hasMoreToLoad = _entities!.length < _totalEntitiesCount;
        });
      } else {
        await PhotoManager.openSetting();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _loadMoreAsset() async {
    final List<AssetEntity> entities = await _path!.getAssetListPaged(
      page: _page + 1,
      size: _sizePerPage,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _entities!.addAll(entities);
      _page++;
      _hasMoreToLoad = _entities!.length < _totalEntitiesCount;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CupertinoActivityIndicator()));
    }
    if (_path == null) {
      return const Center(child: Text('Request paths first.'));
    }
    if (_entities?.isNotEmpty != true) {
      return const Center(child: Text('No assets found on this device.'));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Multi Images'),
        centerTitle: true,
        actions: [
          Center(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${_assetsSelected.length}/5',
              style: TextStyle(fontSize: 20),
            ),
          ))
        ],
      ),
      body: Column(children: [
        Expanded(
          child: GridView.custom(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            childrenDelegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                if (index == _entities!.length - 8 &&
                    !_isLoadingMore &&
                    _hasMoreToLoad) {
                  _loadMoreAsset();
                }
                final AssetEntity entity = _entities![index];
                return InkWell(
                  onTap: () {
                    if (_assetsSelected.contains(entity)) {
                      setState(() {
                        _assetsSelected.remove(entity);
                      });
                      return;
                    }
                    if (_assetsSelected.length < 5) {
                      setState(() {
                        _assetsSelected.add(entity);
                      });
                    } else {
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('You can not add more than 5 images')));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Stack(
                      children: [
                        ImageItemWidget(
                          key: ValueKey<int>(index),
                          entity: entity,
                          option: const ThumbnailOption(
                              size: ThumbnailSize.square(200)),
                        ),
                        if (_assetsSelected.contains(entity))
                          Center(
                            child: Container(
                              height: 300,
                              width: 300,
                              color: Colors.grey.withOpacity(0.8),
                              child: Icon(
                                Icons.clear,
                                color: Colors.red,
                                size: 25,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _entities!.length,
              findChildIndexCallback: (Key key) {
                if (key is ValueKey<int>) {
                  return key.value;
                }
                return null;
              },
            ),
          ),
        ),
        if (_assetsSelected.isNotEmpty)
          Divider(
            height: 4,
            thickness: 3,
          ),
        if (_assetsSelected.isNotEmpty)
          SizedBox(
            height: 100,
            child: Material(
              elevation: 10,
              color: Colors.white,
              child: Stack(
                children: [
                  GridView.custom(
                    scrollDirection: Axis.horizontal,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                    ),
                    childrenDelegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final AssetEntity entity = _assetsSelected[index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Stack(
                            children: [
                              Material(
                                borderRadius: BorderRadius.circular(5),
                                color: Colors.white,
                                elevation: 10,
                                borderOnForeground: true,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: ImageItemWidget(
                                    key: ValueKey<int>(index),
                                    entity: entity,
                                    option: const ThumbnailOption(
                                        size: ThumbnailSize.square(200)),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _assetsSelected.removeAt(index);
                                    });
                                  },
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.white70,
                                    child: Icon(
                                      Icons.clear,
                                      color: Colors.red,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                      childCount: _assetsSelected.length,
                      findChildIndexCallback: (Key key) {
                        if (key is ValueKey<int>) {
                          return key.value;
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                          setState(() {});
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ]),
    );
  }
}

class ImageItemWidget extends StatelessWidget {
  const ImageItemWidget({
    Key? key,
    required this.entity,
    required this.option,
    this.onTap,
  }) : super(key: key);

  final AssetEntity entity;
  final ThumbnailOption option;
  final GestureTapCallback? onTap;

  Widget buildContent(BuildContext context) {
    if (entity.type == AssetType.audio) {
      return const Center(
        child: Icon(Icons.audiotrack, size: 30),
      );
    }
    return _buildImageWidget(context, entity, option);
  }

  Widget _buildImageWidget(
    BuildContext context,
    AssetEntity entity,
    ThumbnailOption option,
  ) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: AssetEntityImage(
            entity,
            isOriginal: false,
            thumbnailSize: option.size,
            thumbnailFormat: option.format,
            fit: BoxFit.cover,
          ),
        ),
        PositionedDirectional(
          bottom: 4,
          start: 0,
          end: 0,
          child: Row(
            children: [
              if (entity.isFavorite)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (entity.isLivePhoto)
                      Container(
                        margin: const EdgeInsetsDirectional.only(end: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                          color: Theme.of(context).cardColor,
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    Icon(
                      () {
                        switch (entity.type) {
                          case AssetType.other:
                            return Icons.abc;
                          case AssetType.image:
                            return Icons.image;
                          case AssetType.video:
                            return Icons.video_file;
                          case AssetType.audio:
                            return Icons.audiotrack;
                        }
                      }(),
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: buildContent(context),
    );
  }
}
