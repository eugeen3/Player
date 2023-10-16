import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart' as ap;
import 'package:just_audio_background/just_audio_background.dart';
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
      home: AudioPlayer(
        auidoUrl: 'https://samplelib.com/lib/preview/mp3/sample-15s.mp3',
        title: 'Test audio',
        imageUrl:
            'https://cdn3.vectorstock.com/i/1000x1000/70/87/abstract-polygonal-square-background-blue-vector-21357087.jpg',
        onFavouriteTap: () {},
        onRepeatTap: () {},
        onPlayTap: () {},
        onAudioEndTap: () {},
        isFavourite: false,
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

class AudioPlayer extends StatefulWidget {
  const AudioPlayer({
    super.key,
    required this.auidoUrl,
    required this.title,
    required this.imageUrl,
    required this.onFavouriteTap,
    required this.onRepeatTap,
    required this.onPlayTap,
    required this.onAudioEndTap,
    required this.isFavourite,
  });

  final String auidoUrl;
  final String title;
  final String imageUrl;
  final VoidCallback onFavouriteTap;
  final VoidCallback onRepeatTap;
  final VoidCallback onPlayTap;
  final VoidCallback onAudioEndTap;
  final bool isFavourite;

  @override
  State<AudioPlayer> createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<AudioPlayer> {
  late bool isFavourite;
  bool repeat = false;
  late ap.AudioPlayer _audioPlayer;

  late final _playlist;

  BorderRadius get imageRadius => const BorderRadius.all(
        Radius.circular(64),
      );

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest2<Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.durationStream,
        (position, duration) => PositionData(
          position,
          duration ?? Duration.zero,
        ),
      );

  ValueNotifier<int> progressNotifier = ValueNotifier(0);

  @override
  void initState() {
    isFavourite = widget.isFavourite;
    _audioPlayer = ap.AudioPlayer();
    _playlist = ap.ConcatenatingAudioSource(children: [
      ap.AudioSource.uri(
        Uri.parse(widget.auidoUrl),
        tag: MediaItem(
          id: '0',
          title: widget.title,
          artUri: Uri.parse(widget.imageUrl),
        ),
      ),
    ]);
    _audioPlayer.setAudioSource(_playlist);

    super.initState();
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
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.fill,
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: SvgPicture.asset('assets/icons/arrow_down.svg'),
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
                        child: Image.network(
                          widget.imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      height: 28 / 24,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
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
                                      inactiveTrackColor:
                                          Colors.white.withOpacity(0),
                                      thumbColor: Colors.white,
                                      overlayColor:
                                          Colors.white.withOpacity(0.08),
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 7,
                                        disabledThumbRadius: 7,
                                        elevation: 0,
                                        pressedElevation: 0,
                                      ),
                                      trackShape: CustomTrackShape(),
                                    ),
                                    child: StreamBuilder(
                                      stream: _positionDataStream,
                                      builder: (context, snapshot) {
                                        final positionData = snapshot.data;
                                        double sliderValue = 0;
                                        if (positionData != null) {
                                          if (positionData.duration !=
                                              Duration.zero) {
                                            sliderValue = positionData
                                                    .position.inMilliseconds /
                                                positionData
                                                    .duration.inMilliseconds;
                                          }
                                        }

                                        if (sliderValue > 1) {
                                          sliderValue = 1;
                                        }

                                        return Slider(
                                          value: sliderValue,
                                          onChanged: (position) {
                                            setState(() {
                                              late Duration newPosition;
                                              if (positionData != null) {
                                                if (positionData.duration !=
                                                    Duration.zero) {
                                                  newPosition = Duration(
                                                      milliseconds: (position *
                                                              positionData
                                                                  .duration
                                                                  .inMilliseconds)
                                                          .toInt());
                                                }
                                              } else {
                                                newPosition = Duration.zero;
                                              }
                                              _audioPlayer.seek(newPosition);
                                            });
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
                      stream: _positionDataStream,
                      builder: (context, snapshot) {
                        final positionData = snapshot.data;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _printDuration(
                                  positionData?.position ?? Duration.zero),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 18 / 14,
                                color: Colors.white.withOpacity(0.65),
                              ),
                            ),
                            Text(
                              _printDuration(
                                  positionData?.duration ?? Duration.zero),
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
                                  ? const Icon(
                                      Icons.favorite,
                                      color: Colors.white,
                                    )
                                  : const Icon(
                                      Icons.favorite_outline,
                                      color: Colors.white,
                                    ),
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
                                _audioPlayer.setLoopMode(ap.LoopMode.one);
                              } else {
                                _audioPlayer.setLoopMode(ap.LoopMode.off);
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
                                    ? SvgPicture.asset(
                                        'assets/icons/repeat_on.svg')
                                    : SvgPicture.asset(
                                        'assets/icons/repeat_off.svg'),
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
                                  child:
                                      SvgPicture.asset('assets/icons/play.svg'),
                                );
                              } else if (proccessingState !=
                                  ap.ProcessingState.completed) {
                                return GestureDetector(
                                  onTap: () {
                                    _audioPlayer.pause();
                                  },
                                  child: SvgPicture.asset(
                                      'assets/icons/pause.svg'),
                                );
                              }
                              return GestureDetector(
                                onTap: () {
                                  _audioPlayer.seek(Duration.zero);
                                  _audioPlayer.play();
                                },
                                child:
                                    SvgPicture.asset('assets/icons/play.svg'),
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
                                      child: SvgPicture.asset(
                                        'assets/icons/end_track.svg',
                                      ),
                                    ),
                                  ),
                                );
                              }),
                        ),
                        SizedBox.square(
                          dimension: 40,
                          child: ValueListenableBuilder(
                            valueListenable: progressNotifier,
                            builder: (context, progress, child) {
                              print(progress);
                              return RepaintBoundary(
                                child: CustomPaint(
                                  painter: CustomCircle(
                                    progress: progress.toDouble(),
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      Timer.periodic(
                                          const Duration(milliseconds: 200),
                                          (timer) {
                                        if (progressNotifier.value >= 100) {
                                          progressNotifier.value = 0;
                                        }
                                        progressNotifier.value =
                                            progressNotifier.value + 1;
                                      });
                                    },
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/icons/download.svg',
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _printDuration(Duration duration) {
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

class CustomCircle extends CustomPainter {
  final double progress;

  CustomCircle({
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
