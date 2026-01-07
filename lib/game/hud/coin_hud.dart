import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:myhero/game/my_game.dart';

class CoinHud extends PositionComponent with HasGameReference<MyGame> {
  late TextComponent _textComponent;

  CoinHud() : super(priority: 10000);

  @override
  Future<void> onLoad() async {
    size = Vector2(80, 30);
    final iconImage = await game.images.load('hud/coin.png');
    final icon = SpriteComponent(
      sprite: Sprite(iconImage),
      size: Vector2(24, 24),
      position: Vector2(0, 3),
    );
    add(icon);

    // Coin Count Text
    _textComponent = TextComponent(
      text: '0',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'PixelFont',
        ),
      ),
      position: Vector2(30, 5),
    );
    add(_textComponent);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10)),
      Paint()..color = Colors.black.withOpacity(0.4),
    );
    super.render(canvas);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _textComponent.text = '${game.hero.coins}';
  }
}
