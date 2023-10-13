import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
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
        title: 'Test',
        imageUrl: 'https://www.w3schools.com/w3css/img_lights.jpg',
        onFavouriteTap: () {},
        onRepeatTap: () {},
        onPlayTap: () {},
        onAudioEndTap: () {},
      ),
    );
  }
}

class AudioPlayer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 30,
              sigmaY: 30,
            ),
          ),
        ),
        Positioned.fill(
          child: Column(
            children: [
              const SizedBox(height: 14),
              SvgPicture.asset('assets/icons/arrow_down.svg'),
              const SizedBox(height: 32),
              DecoratedBox(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(64),
                  ),
                  color: Color(0xFF260E49),
                ),
                child: CachedNetworkImage(imageUrl: imageUrl),
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
          ),
        ),
      ],
    );
  }
}
