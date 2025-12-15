import 'package:flame/components.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/component/dialog_component.dart';
import 'package:myhero/game/component/hero_component.dart';
import 'package:flame/collisions.dart';


class TreasureComponent extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  String status;
  late RectangleHitbox _hitbox;

  TreasureComponent({
    required this.status,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = await Sprite.load(
      status == 'closed'
          ? 'closed_treasure.png'
          : status == 'full'
              ? 'full_treasure.png'
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
      attemptOpen(other);
    }
  }

  Future<void> open() async {
    if (status == 'closed') {
      status = 'full';
      sprite = await Sprite.load('full_treasure.png');
    }
  }

  Future<void> collect(HeroComponent hero) async {
    if (status == 'full') {
      status = 'empty';
      sprite = await Sprite.load('empty_treasure.png');
      UiNotify.showToast(game, '获得宝物');
    }
  }

  void attemptOpen(HeroComponent hero) {
    if (status == 'closed') {
      open();
    } else if (status == 'full') {
      final exists = game.camera.viewport.children
          .query<DialogComponent>()
          .isNotEmpty;
      if (!exists) {
        final dialog = DialogComponent.confirm(
          message: '是否拿取宝物',
          onConfirm: () => collect(hero),
          onCancel: () {},
        );
        game.camera.viewport.add(dialog);
      }
    }
  }
}

