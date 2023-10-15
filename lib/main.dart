import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart' as ap;
import 'package:rxdart/rxdart.dart';

void main() {
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

  @override
  void initState() {
    isFavourite = widget.isFavourite;
    _audioPlayer = ap.AudioPlayer()..setUrl(widget.auidoUrl);
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
                        const SizedBox.square(
                          dimension: 40,
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
