import 'package:flame/components.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/hero_component.dart';
import '../interaction/promptable_interactable_mixin.dart';

import 'package:flame/collisions.dart';
import '../weapon/component/weapon_component.dart';

class TreasureComponent extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks, PromptableInteractable {
  String status;
  late RectangleHitbox _hitbox;

  TreasureComponent({
    required this.status,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  String get promptText => '宝箱';

  @override
  bool get show => status == 'closed';

  @override
  void onInteract(HeroComponent hero) {
    _open();
    if (!show) {
      hero.setInteractable(null);
      onExitInteraction(hero);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = await Sprite.load(
      status == 'closed'
          ? 'closed_treasure.png'
          : 'empty_treasure.png',
    );

    _hitbox = RectangleHitbox();
    add(_hitbox);
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

  Future<void> _open() async {
    if (status == 'closed') {
      status = 'empty';
      sprite = await Sprite.load('empty_treasure.png');

      // 生成随机武器并添加到场景中
      final weaponDrop = WeaponComponent.generateRandomWeapon(position.clone());
      game.world.add(weaponDrop);
    }
  }

  // Future<void> _collect(HeroComponent hero) async {
  //   if (status == 'full') {
  //     status = 'empty';
  //     sprite = await Sprite.load('empty_treasure.png');
  //     UiNotify.showToast(game, '获得宝物');
  //   }
  // }

  // void attemptOpen(HeroComponent hero) {
  //   if (hero.isGenerate) return;

  //   if (status == 'closed') {
  //     _open();
  //   } else if (status == 'full') {
  //     final exists = game.camera.viewport.children
  //         .query<DialogComponent>()
  //         .isNotEmpty;
  //     if (!exists) {
  //       final dialog = DialogComponent.confirm(
  //         message: '是否拿取宝物',
  //         onConfirm: () => _collect(hero),
  //         onCancel: () {},
  //       );
  //       game.camera.viewport.add(dialog);
  //     }
  //   }
  // }
}
