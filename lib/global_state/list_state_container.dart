import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ws/database/channel_favorite_entity.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/database_manager.dart';
import 'package:flutter_ws/platform_channels/download_manager.dart';
import 'package:flutter_ws/platform_channels/video_preview_manager.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

class VideoListState {
  VideoListState(this.extendetListTiles, this.previewImages);
  Set<String> extendetListTiles;
  Map<String, Image> previewImages;
}

class AppState {
  AppState(this.downloadManager, this.databaseManager, this.videoPreviewManager,
      this.downloadedVideos, this.currentDownloads, this.favoritChannels);
  DownloadManager downloadManager;
  DatabaseManager databaseManager;
  VideoPreviewManager videoPreviewManager;
  Map<String, VideoEntity> downloadedVideos;
  Map<String, Video> currentDownloads;
  Map<String, ChannelFavoriteEntity> favoritChannels;
}

class _InheritedWidget extends InheritedWidget {
  final AppSharedState data;

  _InheritedWidget({
    Key key,
    @required this.data,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedWidget old) {
    return true;
  }
}

class AppSharedStateContainer extends StatefulWidget {
  final Widget child;
  final VideoListState videoListState;
  final AppState appState;

  AppSharedStateContainer(
      {@required this.child, this.videoListState, this.appState});

  static AppSharedState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_InheritedWidget)
            as _InheritedWidget)
        .data;
  }

  @override
  AppSharedState createState() => new AppSharedState();
}

class AppSharedState extends State<AppSharedStateContainer> {
  final Logger logger = new Logger('VideoWidget');
  VideoListState videoListState;
  AppState appState;

  void initializeState(BuildContext context) {
    if (appState == null) {
      appState = new AppState(
          new DownloadManager(context),
          new DatabaseManager(),
          new VideoPreviewManager(context),
          new Map(),
          new Map(),
          new Map());
      getAllDownloadsFromDatabase();
    }
    if (videoListState == null) {
      _initializeListState();
    }
  }

  void getAllDownloadsFromDatabase() async {
    await initializeDownloadDb();
    //VIDEOS
    Set<VideoEntity> videos =
        await appState.databaseManager.getAllDownloadedVideos();
    logger.fine("Currently there are " +
        videos.length.toString() +
        " downloaded videos in the database");
    videos.forEach((entity) =>
        appState.downloadedVideos.putIfAbsent(entity.id, () => entity));

    //FAV Channels
    Set<ChannelFavoriteEntity> channels =
        await appState.databaseManager.getAllChannelFavorites();
    logger.fine("There are " +
        channels.length.toString() +
        " favorited channels in the database");
    channels.forEach((entity) =>
        appState.favoritChannels.putIfAbsent(entity.name, () => entity));
  }

  initializeDownloadDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "demo.db");
//   appState.databaseManager.deleteDb(path);
    await appState.databaseManager.open(path).then(
        (dynamic) => logger.fine("Successfully opened database"),
        onError: (e) => logger.fine("Error when opening database"));
  }

  void _initializeListState() {
    videoListState = new VideoListState(new Set(), new Map());
  }

  void addImagePreview(String videoId, Image preview) {
    logger.fine("Adding preview image to state for video with id " + videoId);
    videoListState.previewImages.putIfAbsent(videoId, () => preview);
  }

  void updateExtendetListTile(String videoId) {
    videoListState.extendetListTiles.contains(videoId)
        ? videoListState.extendetListTiles.remove(videoId)
        : videoListState.extendetListTiles.add(videoId);
  }

  @override
  Widget build(BuildContext context) {
    logger.fine("Rendering StateContainerState");
    return new _InheritedWidget(
      data: this,
      child: widget.child,
    );
  }
}