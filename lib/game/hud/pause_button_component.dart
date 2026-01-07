import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'dart:ui' as ui;
import 'package:myhero/game/my_game.dart';

class PauseButtonComponent extends SpriteButtonComponent
    with HasGameReference<MyGame> {
  SpriteComponent? _icon;

  PauseButtonComponent()
      : super(
          size: Vector2.all(30),
          priority: 20001,
          onPressed: null,
        );

  @override
  Future<void> onLoad() async {
    // 创建透明的基础按钮，避免背景被拉伸
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    button = Sprite(image);

    onPressed = () {
      if (game.isPaused) {
        game.resumeGame();
      } else {
        game.pauseGame();
      }
      _updateIcon();
    };

    await _updateIcon();
  }

  Future<void> _updateIcon() async {
    final name = game.isPaused ? 'ui/Next.png' : 'ui/Pause.png';
    final image = await game.images.load(name);
    final sprite = Sprite(image);
    _icon?.removeFromParent();
    _icon = SpriteComponent(
      sprite: sprite,
      size: size,
      position: Vector2.zero(),
    );
    add(_icon!);
  }
}
