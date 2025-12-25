import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/attack/component/bullet_hitbox.dart';
import 'package:myhero/game/attack/component/abstract_attack_rect.dart';
import 'package:myhero/game/config/bullet_config.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import 'package:myhero/game/attack/factory/attack_hitbox_factory.dart';
import 'package:myhero/game/attack/spec/attack_spec.dart';
import 'package:myhero/game/state/attack_type.dart';

class TestGame extends MyGame {
  @override
  Future<void> onLoad() async {}
}

void main() {
  group('Unified target passing', () {
    testWithGame<TestGame>('Factory passes target into BulletHitbox', () {
      return TestGame();
    }, (game) async {
      final hero = HeroComponent(heroId: 'hero_default', birthPosition: Vector2(0, 0));
      final monster = MonsterComponent(Vector2(100, 0), 'orc');
      await game.ensureAdd(hero);
      await game.ensureAdd(monster);

    final spec = AttackSpec(
      id: 'test_bullet',
      damage: 1,
      duration: 1.0,
      type: AttackType.ranged,
      sizeRel: Vector2(1, 1),
      centerOffsetRel: Vector2.zero(),
      bullet: BulletConfig(
        speed: 100,
        maxRange: 200,
        size: Vector2(4, 4),
        textureSize: null,
        spritePath: null,
        animation: null,
        penetrate: false,
      ),
      interval: 0.2,
    );

    final hitbox = AttackHitboxFactory.create(
      spec: spec,
      owner: hero,
      targetType: MonsterComponent,
      target: monster,
      facingRight: true,
    );

    await game.ensureAdd(hitbox);

    final bullet = hitbox as BulletHitbox;
    expect(bullet.target, isNotNull);
    expect(bullet.target, equals(monster));

    // First update should lock direction towards target
    bullet.update(0.016);
    expect(bullet.position.x >= hero.position.x, isTrue);
    });
  });
}
