import 'package:myhero/game/component/hero_component.dart';
import 'package:flame/components.dart';
import 'package:myhero/game/my_game.dart';
import 'package:flame/collisions.dart';

class ThornComponent extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  String status;
  late RectangleHitbox _hitbox;

  double _elapsed = 0;
  double period = 2.0;
  bool hurted = false;
  ThornComponent({super.position, required super.size, required this.status});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load(
      status == 'on' ? 'thorn_on.png' : 'thorn_off.png',
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
      attemptDamage(other);
    }
  }

  void attemptDamage(HeroComponent hero) {
    if (status == 'on' && !hurted) {
      hero.loseHp(1);
      hurted = true;
    }
  }

  void _toggle() async {
    if (status == 'on') {
      status = 'off';
    } else {
      status = 'on';
      hurted = false;
    }
    sprite = await Sprite.load(
      status == 'on' ? 'thorn_on.png' : 'thorn_off.png',
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= period) {
      _elapsed = 0;
      _toggle();
    }
  }
}
