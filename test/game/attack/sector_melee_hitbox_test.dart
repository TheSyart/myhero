import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/attack/component/sector_melee_hitbox.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import 'package:myhero/game/my_game.dart';
import 'package:flame/components.dart';
import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:myhero/game/state/character_state.dart';

class TestGame extends MyGame {
  @override
  Future<void> onLoad() async {
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 10),
      background: CircleComponent(radius: 30),
    );
  }
}

class TestHero extends HeroComponent {
  TestHero(Vector2 pos) : super(birthPosition: pos, heroId: 'hero_default');
  @override
  Future<void> onLoad() async {
    position = birthPosition ?? Vector2.zero();
    size = Vector2(50, 50);
    hitbox = RectangleHitbox(size: size);
    add(hitbox);
    state = CharacterState.idle;
  }

  @override
  void loseHp(int amount) {
    hp -= amount;
  }
}

class TestMonster extends MonsterComponent {
  TestMonster(Vector2 pos) : super(pos, 'elite_orc');
  @override
  Future<void> onLoad() async {
    position = birthPosition;
    hp = 100;
    size = Vector2(50, 50);
    hitbox = RectangleHitbox(size: size);
    add(hitbox);
    state = CharacterState.idle;
  }

  @override
  void loseHp(int amount) {
    hp -= amount;
  }
  @override
  void update(double dt) {
    // Disable AI
  }
}

void main() {
  final withGame = FlameTester(TestGame.new);

  group('SectorMeleeHitbox', () {
    withGame.testGameWidget(
      'hits target in sector',
      setUp: (game, tester) async {
        final owner = TestHero(Vector2(0, 0));
        await game.world.ensureAdd(owner);

        final target = TestMonster(Vector2(50, 0)); // In front (0 degrees)
        await game.world.ensureAdd(target);

        final sector = SectorMeleeHitbox.obtain(
          owner: owner,
          radius: 100,
          arcAngle: math.pi / 2, // 90 degrees
          facingAngle: 0,
          damage: 10,
          targetType: MonsterComponent,
        );
        await game.world.ensureAdd(sector);

        game.update(0.1);

        expect(target.hp, lessThan(100));
      },
    );

    withGame.testGameWidget(
      'does not hit target outside sector',
      setUp: (game, tester) async {
        final owner = TestHero(Vector2(0, 0));
        await game.world.ensureAdd(owner);

        final target = TestMonster(Vector2(-50, 0)); // Behind (180 degrees)
        await game.world.ensureAdd(target);

        final sector = SectorMeleeHitbox.obtain(
          owner: owner,
          radius: 100,
          arcAngle: math.pi / 2,
          facingAngle: 0,
          damage: 10,
          targetType: MonsterComponent,
        );
        await game.world.ensureAdd(sector);

        game.update(0.1);

        expect(target.hp, equals(100));
      },
    );
  });
}
