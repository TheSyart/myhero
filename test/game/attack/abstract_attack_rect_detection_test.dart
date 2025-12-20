import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import 'package:myhero/game/attack/component/melee_hitbox.dart';

class TestMyGame extends MyGame {
  @override
  Future<void> onLoad() async {}
}

class DummyMonster extends MonsterComponent {
  DummyMonster(Vector2 birth, String id) : super(birth, id);
  @override
  void update(double dt) {}
}

Future<(HeroComponent, DummyMonster)> _prepareActors(TestMyGame game) async {
  final heroImg = await generateImage(96, 96);
  final monsterImg = await generateImage(300, 300);
  game.images.add('character/Satyr.png', heroImg);
  game.images.add('character/Elite Orc.png', monsterImg);

  game.joystick = JoystickComponent(
    knob: CircleComponent(radius: 1),
    background: CircleComponent(radius: 2),
  );

  final hero = HeroComponent(heroId: 'hero_default')..position = Vector2(100, 100);
  await game.ensureAdd(hero);
  game.hero = hero;

  final m = DummyMonster(Vector2(200, 120), 'elite_orc');
  await game.ensureAdd(m);
  return (hero, m);
}

void main() {
  group('AbstractAttackRect geometry detection', () {
    testWithGame<TestMyGame>('完全包含：攻击矩形完全包含目标矩形', () {
      return TestMyGame();
    }, (game) async {
      final (hero, m) = await _prepareActors(game);
      final targetRect = m.hitbox.toAbsoluteRect();
      final expanded = ui.Rect.fromLTWH(
        targetRect.left,
        targetRect.top,
        targetRect.width,
        targetRect.height,
      );

      final attack = MeleeHitbox(
        owner: hero,
        position: Vector2(expanded.left, expanded.top),
        size: Vector2(expanded.width, expanded.height),
        damage: 7,
        targetType: MonsterComponent,
      );
      await game.ensureAdd(attack);

      final hpBefore = m.hp;
      game.update(0.016);
      expect(m.hp, hpBefore - 7);
      game.update(0.016);
      expect(attack.parent, isNull);
    });

    testWithGame<TestMyGame>('目标包含：目标矩形完全包含攻击矩形', () {
      return TestMyGame();
    }, (game) async {
      final (hero, m) = await _prepareActors(game);
      final targetRect = m.hitbox.toAbsoluteRect();
      final inner = ui.Rect.fromLTWH(
        targetRect.left,
        targetRect.top,
        targetRect.width,
        targetRect.height,
      );

      final attack = MeleeHitbox(
        owner: hero,
        position: Vector2(inner.left, inner.top),
        size: Vector2(inner.width, inner.height),
        damage: 5,
        targetType: MonsterComponent,
      );
      await game.ensureAdd(attack);

      final hpBefore = m.hp;
      game.update(0.016);
      final attackRectActual = attack.getAttackRect();
      expect(attackRectActual.left >= targetRect.left, isTrue);
      expect(attackRectActual.top >= targetRect.top, isTrue);
      expect(attackRectActual.right <= targetRect.right, isTrue);
      expect(attackRectActual.bottom <= targetRect.bottom, isTrue);
      expect(m.hp, hpBefore - 5);
      game.update(0.016);
      expect(attack.parent, isNull);
    });

    testWithGame<TestMyGame>('部分重叠：边界有交叠', () {
      return TestMyGame();
    }, (game) async {
      final (hero, m) = await _prepareActors(game);
      final targetRect = m.hitbox.toAbsoluteRect();
      final partial = ui.Rect.fromLTWH(
        targetRect.left - 20,
        targetRect.top + 5,
        40,
        math.max(10, targetRect.height - 10),
      );

      final attack = MeleeHitbox(
        owner: hero,
        position: Vector2(partial.left, partial.top),
        size: Vector2(partial.width, partial.height),
        damage: 3,
        targetType: MonsterComponent,
      );
      await game.ensureAdd(attack);

      final hpBefore = m.hp;
      game.update(0.016);
      expect(m.hp, hpBefore - 3);
      game.update(0.016);
      expect(attack.parent, isNull);
    });

    testWithGame<TestMyGame>('完全不接触：无重叠无包含', () {
      return TestMyGame();
    }, (game) async {
      final (hero, m) = await _prepareActors(game);
      final targetRect = m.hitbox.toAbsoluteRect();
      final far = ui.Rect.fromLTWH(
        targetRect.left - 200,
        targetRect.top - 200,
        30,
        30,
      );

      final attack = MeleeHitbox(
        owner: hero,
        position: Vector2(far.left, far.top),
        size: Vector2(far.width, far.height),
        damage: 9,
        targetType: MonsterComponent,
      );
      await game.ensureAdd(attack);

      final hpBefore = m.hp;
      game.update(0.016);
      expect(m.hp, hpBefore);
      game.update(0.016);
      expect(attack.parent, isNotNull);
    });

    testWithGame<TestMyGame>('边缘接触：共享边界也应判定为命中', () {
      return TestMyGame();
    }, (game) async {
      final (hero, m) = await _prepareActors(game);
      final targetRect = m.hitbox.toAbsoluteRect();
      final width = 20.0;
      final edge = ui.Rect.fromLTWH(
        targetRect.left - width,
        targetRect.top,
        width,
        targetRect.height,
      );

      final attack = MeleeHitbox(
        owner: hero,
        position: Vector2(edge.left, edge.top),
        size: Vector2(edge.width, edge.height),
        damage: 4,
        targetType: MonsterComponent,
      );
      await game.ensureAdd(attack);

      final hpBefore = m.hp;
      game.update(0.016);
      expect(m.hp, hpBefore - 4);
      game.update(0.016);
      expect(attack.parent, isNull);
    });
  });
}
