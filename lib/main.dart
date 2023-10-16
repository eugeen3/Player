import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

Future<void> main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PlayerScreen(
        auidoUrl:
            'https://firebasestorage.googleapis.com/v0/b/test-d3b93.appspot.com/o/Blue%20Moon%20%20%20Frank%20Sinatra.mp3?alt=media&token=54e7d046-2c67-468e-b5ee-17eee27e83ea&_gl=1*1mp5mxf*_ga*MTkzMDUyNjQ5MS4xNjY4NjI1MTA5*_ga_CW55HF8NVT*MTY5NzQ3MTA5My4zNy4xLjE2OTc0NzEzODEuNjAuMC4w',
        title: 'Test audio',
        imageUrl:
            'https://cdn3.vectorstock.com/i/1000x1000/70/87/abstract-polygonal-square-background-blue-vector-21357087.jpg',
        onFavouriteTap: () {},
        onRepeatTap: () {},
        onPlayTap: () {},
        onAudioEndTap: () {},
        onCloseTap: () {},
        isFavourite: false,
        closeIcon: SvgPicture.asset('assets/icons/arrow_down.svg'),
        downloadIcon: SvgPicture.asset('assets/icons/download.svg'),
        endTrackIcon: SvgPicture.asset('assets/icons/end_track.svg'),
        addToFavouritesIcon: const Icon(
          Icons.favorite,
          color: Colors.white,
        ),
        removeFromFavouritesIcon: const Icon(
          Icons.favorite_outline,
          color: Colors.white,
        ),
        loaderIcon: Image.asset('assets/icons/loader.png'),
        pauseIcon: SvgPicture.asset('assets/icons/pause.svg'),
        playIcon: SvgPicture.asset('assets/icons/play.svg'),
        repeatOnIcon: SvgPicture.asset('assets/icons/repeat_on.svg'),
        repeatOffIcon: SvgPicture.asset('assets/icons/repeat_off.svg'),
        trashCanIcon: SvgPicture.asset('assets/icons/trash_can.svg'),
      ),
    );
  }
}

class PositionData {
  final Duration position;
  final Duration duration;

  PositionData(
    this.position,
    this.duration,
  );
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.auidoUrl,
    required this.title,
    required this.imageUrl,
    required this.onFavouriteTap,
    required this.onRepeatTap,
    required this.onPlayTap,
    required this.onAudioEndTap,
    required this.onCloseTap,
    required this.isFavourite,
    required this.closeIcon,
    required this.downloadIcon,
    required this.endTrackIcon,
    required this.addToFavouritesIcon,
    required this.removeFromFavouritesIcon,
    required this.loaderIcon,
    required this.pauseIcon,
    required this.playIcon,
    required this.repeatOnIcon,
    required this.repeatOffIcon,
    required this.trashCanIcon,
  });

  final String auidoUrl;
  final String title;
  final String imageUrl;
  final VoidCallback onFavouriteTap;
  final VoidCallback onRepeatTap;
  final VoidCallback onPlayTap;
  final VoidCallback onAudioEndTap;
  final VoidCallback onCloseTap;
  final bool isFavourite;
  final Widget closeIcon;
  final Widget downloadIcon;
  final Widget endTrackIcon;
  final Widget addToFavouritesIcon;
  final Widget removeFromFavouritesIcon;
  final Widget loaderIcon;
  final Widget pauseIcon;
  final Widget playIcon;
  final Widget repeatOnIcon;
  final Widget repeatOffIcon;
  final Widget trashCanIcon;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const String kAudioDirectory = 'audio';

  late bool isFavourite;
  bool repeat = false;
  late AudioPlayer _audioPlayer;

  late AudioSource _playlist;

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest2<Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.durationStream,
        (position, duration) => PositionData(
          position,
          duration ?? Duration.zero,
        ),
      ).asBroadcastStream();

  final ValueNotifier<double> _progressNotifier = ValueNotifier(.0);
  final ValueNotifier<bool> _isDownloadedNotifier = ValueNotifier(false);

  @override
  void initState() {
    isFavourite = widget.isFavourite;
    _audioPlayer = AudioPlayer();
    _isDownloadedNotifier.addListener(() async {
      if (_isDownloadedNotifier.value) {
        final filePath =
            await FileUtils.filePathFromUri(widget.auidoUrl, kAudioDirectory);
        _playlist = ConcatenatingAudioSource(children: [
          AudioSource.file(
            filePath,
            tag: MediaItem(
              id: '0',
              title: widget.title,
              artUri: Uri.parse(widget.imageUrl),
            ),
          ),
        ]);
      } else {
        _isDownloadedNotifier.value = false;
        _playlist = ConcatenatingAudioSource(children: [
          AudioSource.uri(
            Uri.parse(widget.auidoUrl),
            tag: MediaItem(
              id: '0',
              title: widget.title,
              artUri: Uri.parse(widget.imageUrl),
            ),
          ),
        ]);
      }

      final position = _audioPlayer.position;
      await _audioPlayer.setAudioSource(_playlist, initialPosition: position);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    final filePath =
        await FileUtils.filePathFromUri(widget.auidoUrl, kAudioDirectory);
    if (FileUtils.isFileExists(filePath)) {
      _isDownloadedNotifier.value = true;
    } else {
      _isDownloadedNotifier.value = false;
      _playlist = ConcatenatingAudioSource(children: [
        AudioSource.uri(
          Uri.parse(widget.auidoUrl),
          tag: MediaItem(
            id: '0',
            title: widget.title,
            artUri: Uri.parse(widget.imageUrl),
          ),
        ),
      ]);
      await _audioPlayer.setAudioSource(_playlist);

      _isDownloadedNotifier.value = false;
    }

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ),
              child: Transform.scale(
                scale: 1.2,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.fill,
                  placeholder: (context, url) =>
                      ColoredBox(color: Colors.black.withOpacity(0.4)),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.paddingOf(context).top,
                  ),
                  const SizedBox(height: 14),
                  _ImageAndTitle(
                    imageUrl: widget.imageUrl,
                    title: widget.title,
                    onCloseTap: widget.onCloseTap,
                    closeIcon: widget.closeIcon,
                  ),
                  const Spacer(),
                  _PlayerSlider(
                    positionDataStream: _positionDataStream,
                    onSeekPlayer: _audioPlayer.seek,
                  ),
                  const SizedBox(height: 36),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox.square(
                          dimension: 40,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isFavourite = !isFavourite;
                              });
                              widget.onFavouriteTap();
                            },
                            child: Center(
                              child: isFavourite
                                  ? widget.addToFavouritesIcon
                                  : widget.removeFromFavouritesIcon,
                            ),
                          ),
                        ),
                        SizedBox.square(
                          dimension: 40,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                repeat = !repeat;
                              });
                              if (repeat) {
                                _audioPlayer.setLoopMode(LoopMode.one);
                              } else {
                                _audioPlayer.setLoopMode(LoopMode.off);
                              }
                              widget.onRepeatTap();
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: repeat
                                    ? widget.repeatOnIcon
                                    : widget.repeatOffIcon,
                              ),
                            ),
                          ),
                        ),
                        SizedBox.square(
                          dimension: 56,
                          child: StreamBuilder(
                            stream: _audioPlayer.playerStateStream,
                            builder: (context, snapshot) {
                              final playerState = snapshot.data;
                              final proccessingState =
                                  playerState?.processingState;
                              final isPlaying = playerState?.playing;
                              if (!(isPlaying ?? false)) {
                                return GestureDetector(
                                  onTap: () {
                                    _audioPlayer.play();
                                  },
                                  child: widget.playIcon,
                                );
                              } else if (proccessingState !=
                                  ProcessingState.completed) {
                                return GestureDetector(
                                  onTap: () {
                                    _audioPlayer.pause();
                                  },
                                  child: widget.pauseIcon,
                                );
                              }
                              return GestureDetector(
                                onTap: () {
                                  _audioPlayer.seek(Duration.zero);
                                  _audioPlayer.play();
                                },
                                child: widget.playIcon,
                              );
                            },
                          ),
                        ),
                        SizedBox.square(
                          dimension: 40,
                          child: StreamBuilder(
                              stream: _positionDataStream,
                              builder: (context, snapshot) {
                                final duration = snapshot.data?.duration;
                                return GestureDetector(
                                  onTap: () {
                                    if (duration != null) {
                                      _audioPlayer.seek(duration);
                                    }
                                    widget.onAudioEndTap();
                                  },
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: widget.endTrackIcon,
                                    ),
                                  ),
                                );
                              }),
                        ),
                        SizedBox.square(
                            dimension: 40,
                            child: ValueListenableBuilder(
                              valueListenable: _isDownloadedNotifier,
                              builder: (_, downloaded, __) => downloaded
                                  ? GestureDetector(
                                      onTap: () async {
                                        await FileUtils.deleteFile(
                                          widget.auidoUrl,
                                          kAudioDirectory,
                                        );
                                        _isDownloadedNotifier.value = false;
                                      },
                                      child: Center(
                                        child: widget.trashCanIcon,
                                      ),
                                    )
                                  : ValueListenableBuilder(
                                      valueListenable: _progressNotifier,
                                      builder: (_, progress, __) {
                                        return RepaintBoundary(
                                          child: CustomPaint(
                                            painter: ProgressBorderPainter(
                                              progress: progress,
                                            ),
                                            child: GestureDetector(
                                              onTap: () async {
                                                final audioFilePath =
                                                    await FileUtils
                                                        .filePathFromUri(
                                                            widget.auidoUrl,
                                                            kAudioDirectory);
                                                final dio = Dio();
                                                setState(() {
                                                  _progressNotifier.value = 0.1;
                                                });
                                                dio.download(
                                                  widget.auidoUrl,
                                                  audioFilePath,
                                                  onReceiveProgress:
                                                      (count, total) {
                                                    _progressNotifier.value =
                                                        count / total * 100;
                                                    if (count / total == 1) {
                                                      _progressNotifier.value =
                                                          0;
                                                      _isDownloadedNotifier
                                                          .value = true;
                                                      setState(() {});
                                                    }
                                                  },
                                                );
                                              },
                                              child: Center(
                                                child: widget.downloadIcon,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            )),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          if (_progressNotifier.value > 0 && _progressNotifier.value < 100)
            Positioned(
              top: 62,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.center,
                child: Center(
                    child: LoadingPopup(
                  loaderIcon: widget.loaderIcon,
                )),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageAndTitle extends StatelessWidget {
  const _ImageAndTitle({
    required this.imageUrl,
    required this.title,
    required this.onCloseTap,
    required this.closeIcon,
  });

  final String imageUrl;
  final String title;
  final VoidCallback onCloseTap;
  final Widget closeIcon;

  BorderRadius get imageRadius => const BorderRadius.all(
        Radius.circular(64),
      );
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(onTap: () => onCloseTap(), child: closeIcon),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox.square(
          dimension: 260,
          child: ClipRRect(
            borderRadius: imageRadius,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(64),
                ),
                color: Color(0xFF260E49),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    ColoredBox(color: Colors.black.withOpacity(0.4)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            height: 28 / 24,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PlayerSlider extends StatelessWidget {
  const _PlayerSlider({
    required this.positionDataStream,
    required this.onSeekPlayer,
  });

  final Stream<PositionData> positionDataStream;
  final ValueChanged<Duration> onSeekPlayer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 14,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 7,
                        height: 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2,
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withOpacity(0),
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withOpacity(0.08),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                              disabledThumbRadius: 7,
                              elevation: 0,
                              pressedElevation: 0,
                            ),
                            trackShape: CustomTrackShape(),
                          ),
                          child: StreamBuilder(
                            stream: positionDataStream,
                            builder: (context, snapshot) {
                              final positionData = snapshot.data;
                              double sliderValue = 0;
                              if (positionData != null) {
                                if (positionData.duration != Duration.zero) {
                                  sliderValue =
                                      positionData.position.inMilliseconds /
                                          positionData.duration.inMilliseconds;
                                }
                              }

                              if (sliderValue > 1) {
                                sliderValue = 1;
                              }

                              return Slider(
                                value: sliderValue,
                                onChanged: (position) {
                                  late Duration newPosition;
                                  if (positionData != null) {
                                    if (positionData.duration !=
                                        Duration.zero) {
                                      newPosition = Duration(
                                          milliseconds: (position *
                                                  positionData
                                                      .duration.inMilliseconds)
                                              .toInt());
                                    }
                                  } else {
                                    newPosition = Duration.zero;
                                  }
                                  onSeekPlayer(newPosition);
                                },
                              );
                            },
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
        StreamBuilder(
            stream: positionDataStream,
            builder: (context, snapshot) {
              final positionData = snapshot.data;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _durationToTime(positionData?.position ?? Duration.zero),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 18 / 14,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                  Text(
                    _durationToTime(positionData?.duration ?? Duration.zero),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 18 / 14,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                ],
              );
            }),
      ],
    );
  }

  String _durationToTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const trackHeight = 2.0;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    super.paint(context, offset,
        parentBox: parentBox,
        sliderTheme: sliderTheme,
        enableAnimation: enableAnimation,
        textDirection: textDirection,
        thumbCenter: thumbCenter,
        isDiscrete: isDiscrete,
        isEnabled: isEnabled,
        additionalActiveTrackHeight: 0);
  }
}

class ProgressBorderPainter extends CustomPainter {
  final double progress;

  ProgressBorderPainter({
    required this.progress,
  });

  static const lineLength = 14;
  static const progressInLine = 10;
  static const progressInArc = 15;

  static const degrees90 = pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height != size.width) {
      throw Exception('Widget must have equal sides');
    }
    if (progress > 0) {
      final double width = size.width;
      final double height = size.height;

      const strokeWidth = 1.0;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = Colors.white;

      final Path path = Path()..moveTo(width / 2, 0);

      int progressToSubtract = 0;

      //First half of line
      path.relativeLineTo(
          (min(progress, progressInLine / 2) * (lineLength / 2)) /
              (progressInLine / 2),
          0);
      progressToSubtract = 5;

      //First rounded angle
      if (progress > progressToSubtract) {
        double angleMultiplyer = progressInArc.toDouble();
        if (progress < progressInArc + progressInLine / 2) {
          angleMultiplyer = progress - progressToSubtract.toDouble();
        }

        path.addArc(
          Rect.fromLTRB(
            width / 2 - (lineLength / 2),
            0,
            width,
            height / 2 + (lineLength / 2),
          ),
          3 * degrees90,
          (degrees90 * angleMultiplyer) / progressInArc,
        );
      }
      progressToSubtract += progressInArc; //20

      //Second line
      if (progress > progressToSubtract) {
        path.relativeLineTo(
          0,
          (min(
                    progressInLine,
                    progress - progressToSubtract,
                  ) *
                  lineLength) /
              progressInLine,
        );
      }
      progressToSubtract += progressInLine; //30

      //Second rounded angle
      if (progress > progressToSubtract) {
        double angleMultiplyer = progressInArc.toDouble();
        if (progress < progressToSubtract + progressInArc) {
          angleMultiplyer = progress - progressToSubtract.toDouble();
        }

        path.addArc(
          Rect.fromLTRB(
            lineLength.toDouble(),
            lineLength.toDouble(),
            width,
            height,
          ),
          0,
          (degrees90 * angleMultiplyer) / progressInArc,
        );
      }
      progressToSubtract += progressInArc; //45

      //Third line
      if (progress > progressToSubtract) {
        path.relativeLineTo(
          -(min(
                    progressInLine,
                    progress - progressToSubtract,
                  ) *
                  lineLength) /
              progressInLine,
          0,
        );
      }
      progressToSubtract += progressInLine; //55

      //Third rounded angle
      if (progress > progressToSubtract) {
        double angleMultiplyer = progressInArc.toDouble();
        if (progress < progressToSubtract + progressInArc) {
          angleMultiplyer = progress - progressToSubtract.toDouble();
        }

        path.addArc(
          Rect.fromLTRB(
            0,
            lineLength.toDouble(),
            lineLength * 2,
            height,
          ),
          degrees90,
          (degrees90 * angleMultiplyer) / progressInArc,
        );
      }
      progressToSubtract += progressInArc; //70

      //Fourth line
      if (progress > progressToSubtract) {
        path.relativeLineTo(
          0,
          -(min(
                    progressInLine,
                    progress - progressToSubtract,
                  ) *
                  lineLength) /
              progressInLine,
        );
      }
      progressToSubtract += progressInLine; //80

      //Fourth rounded angle
      if (progress > progressToSubtract) {
        double angleMultiplyer = progressInArc.toDouble();
        if (progress < progressToSubtract + progressInArc) {
          angleMultiplyer = progress - progressToSubtract.toDouble();
        }

        path.addArc(
          const Rect.fromLTRB(
            0,
            0,
            lineLength * 2,
            lineLength * 2,
          ),
          degrees90 * 2,
          (degrees90 * angleMultiplyer) / progressInArc,
        );
      }
      progressToSubtract += progressInArc; //95

      //Last half of line
      if (progress > progressToSubtract) {
        path.relativeLineTo(
            (min(progress, progressInLine / 2) * (lineLength / 2)) /
                (progressInLine / 2),
            0);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class LoadingPopup extends StatefulWidget {
  const LoadingPopup({super.key, required this.loaderIcon});

  final Widget loaderIcon;

  @override
  State<LoadingPopup> createState() => _LoadingPopupState();
}

class _LoadingPopupState extends State<LoadingPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animationController.repeat();
    _animation = Tween(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 192,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              RepaintBoundary(
                child: RotationTransition(
                  turns: _animation,
                  child: SizedBox.square(
                    dimension: 24,
                    child: Center(child: widget.loaderIcon),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Загружаем практику',
                style: TextStyle(
                  fontSize: 14,
                  height: 18 / 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract class FileUtils {
  static Future<String> filePathFromUri(
      String uri, String targetDirectory) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final endDirectory =
        Directory('${documentsDirectory.path}/$targetDirectory');
    final fileName = _getFileNameByType(uri);

    if (!endDirectory.existsSync()) {
      endDirectory.createSync();
    }

    final filePath = '${endDirectory.path}/$fileName';
    return filePath;
  }

  static Future<void> deleteFile(String uri, String targetDirectory) async {
    final filePath = await filePathFromUri(uri, targetDirectory);
    await File(filePath).delete();
  }

  static bool isFileExists(String path) {
    final isFileExists = File(path).existsSync();
    return isFileExists;
  }

  static String _getFileNameByType(String uri) {
    final linkWithType = uri.substring(0, uri.lastIndexOf('.mp3'));
    return (linkWithType.substring(linkWithType.lastIndexOf('/')))
        .replaceAll('/', '');
  }
}
