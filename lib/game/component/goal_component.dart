import 'package:myhero/game/character/hero_component.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import 'package:myhero/game/my_game.dart';
import '../../component/dialog_component.dart';
import '../../manager/audio_manager.dart';
class GoalComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  GoalComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final image = await game.images.load('flag.png');
    final sheet = SpriteSheet(image: image, srcSize: Vector2(60, 60));
    animation = sheet.createAnimation(
      row: 0,
      stepTime: 0.12,
      from: 0,
      to: 4,
      loop: true,
    );
    add(RectangleHitbox());
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is HeroComponent) {
      AudioManager.playWhistle();
      UiNotify.showToast(game, '恭喜你完成了游戏！');
      other.onDead();
    }
  }
}
