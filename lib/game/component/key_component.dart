import 'package:myhero/game/character/hero_component.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:myhero/game/my_game.dart';

class KeyComponent extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  final String keyId;

  KeyComponent({
    required this.keyId,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load('key.png'); // 直接加载 assets/key.png
    add(RectangleHitbox());
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is HeroComponent) {
      other.addKey(keyId);
      removeFromParent(); // 拾取后移除当前 tile
    }
  }
}
