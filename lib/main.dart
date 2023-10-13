import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AudioPlayer(
        auidoUrl:
            'https://github.com/rafaelreis-hotmart/Audio-Sample-files/blob/master/sample2.mp3',
        title: 'Test audio',
        imageUrl: 'https://www.w3schools.com/w3css/img_lights.jpg',
        onFavouriteTap: () {},
        onRepeatTap: () {},
        onPlayTap: () {},
        onAudioEndTap: () {},
      ),
    );
  }
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
  });

  final String auidoUrl;
  final String title;
  final String imageUrl;
  final VoidCallback onFavouriteTap;
  final VoidCallback onRepeatTap;
  final VoidCallback onPlayTap;
  final VoidCallback onAudioEndTap;

  @override
  State<AudioPlayer> createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<AudioPlayer> {
  double value = 0.44;

  BorderRadius get imageRadius => const BorderRadius.all(
        Radius.circular(64),
      );

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
                  Slider(
                    value: value,
                    onChanged: (_) {},
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
}
