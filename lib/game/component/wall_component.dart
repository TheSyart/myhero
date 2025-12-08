import 'package:flame/components.dart';
import 'package:flame/collisions.dart';


class WallComponent extends PositionComponent with CollisionCallbacks {
  WallComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }
}
