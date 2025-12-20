import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import '../../character/hero_component.dart';
import 'package:myhero/game/my_game.dart';

class AttackButton extends SpriteButtonComponent with HasGameReference<MyGame> {
  final HeroComponent hero;
  final String iconName;

  AttackButton({
    required this.hero,
    required String icon,
    required VoidCallback onPressed,
  }) : iconName = icon,
       super(
         onPressed: onPressed,
         size: Vector2.all(72),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    button = await Sprite.load(iconName);

    // 添加外部圆圈
    add(
      CircleComponent(
        radius: 36,
        position: size / 2,
        anchor: Anchor.center,
        paint: Paint()
          ..color = Colors.white38
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    final path = Path()..addOval(size.toRect());
    canvas.clipPath(path);
    super.render(canvas);
    canvas.restore();
  }
}
