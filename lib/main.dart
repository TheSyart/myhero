import 'package:flutter/material.dart';
import 'game/my_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(GameWidget(game: MyGame()));
}
