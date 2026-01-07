import 'package:myhero/game/character/hero_component.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import 'package:myhero/game/interaction/promptable_interactable_mixin.dart';
import 'package:myhero/game/my_game.dart';
import '../../component/dialog_component.dart';
import '../../manager/audio_manager.dart';

class PortalComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame>, CollisionCallbacks, PromptableInteractable {
  final String mapId;
  PortalComponent({
    required Vector2 position,
    required Vector2 size,
    required this.mapId,
  }) : super(position: position, size: size);

  @override
  String get promptText => '传送门';

  @override
  bool get show => true;

  @override
  void onInteract(HeroComponent hero) {
    AudioManager.playWhistle();
    UiNotify.showToast(game, '传送中...');
    game.levelLoader.load(mapId).then((_) {
      final bp = game.levelLoader.heroBirthPoint;
      if (bp != null) {
        game.hero.position = bp;
      }
    });

    if (!show) {
      hero.setInteractable(null);
      onExitInteraction(hero);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final image = await game.images.load('portal.png');
    final sheet = SpriteSheet(image: image, srcSize: Vector2(282, 282));
    animation = sheet.createAnimation(
      row: 0,
      stepTime: 0.12,
      from: 0,
      to: 14,
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
      if (show) {
        other.setInteractable(this); // 通知 Hero
        onEnterInteraction(other);
      }
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    if (other is HeroComponent) {
      other.setInteractable(null);
      onExitInteraction(other); // 隐藏提示
    }
  }
}
