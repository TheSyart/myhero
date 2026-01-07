import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'dart:ui';

abstract class BlockerComponent extends SpriteComponent
    with CollisionCallbacks {
  late final RectangleHitbox hitbox;

  BlockerComponent({
    super.position,
    required super.size,
    bool addHitbox = true,
  }) {
    hitbox = RectangleHitbox.relative(
      Vector2(1.0, 1.0),
      parentSize: size,
    );
    if (addHitbox) add(hitbox);
  }


  @override
  Future<void> onLoad() async {
    // 创建一个 1x1 透明图片作为占位 sprite，满足 SpriteComponent 要求
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0x00000000);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    sprite = Sprite(image);
  }

  bool collidesWith(Rect heroRect) {
    return hitbox.toAbsoluteRect().overlaps(heroRect);
  }
}
