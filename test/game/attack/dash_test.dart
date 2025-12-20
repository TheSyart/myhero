import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import 'package:myhero/game/state/character_state.dart';
import 'package:myhero/game/attack/component/dash_hitbox.dart';

class TestMyGame extends MyGame {
  @override
  Future<void> onLoad() async {
    // 简化测试环境
  }
}

class DummyMonster extends MonsterComponent {
  DummyMonster(Vector2 birth, String id) : super(birth, id);
  @override
  void update(double dt) {
    // 不移动
  }
}

class MockJoystick extends JoystickComponent {
  final Vector2 fixedDelta;
  MockJoystick(this.fixedDelta) : super(knob: CircleComponent(), background: CircleComponent());

  @override
  void update(double dt) {
    // Force delta to fixed value every frame
    delta.setFrom(fixedDelta);
  }
}

void main() {
  group('Dash Hitbox Tests', () {
    testWithGame<TestMyGame>('Dash follows joystick direction (Priority)', () {
      return TestMyGame();
    }, (game) async {
      // Setup resources
      final heroImg = await generateImage(96, 96);
      final monsterImg = await generateImage(300, 300);
      game.images.add('character/Satyr.png', heroImg);
      game.images.add('character/Elite Orc.png', monsterImg);

      // Use MockJoystick with UP direction (0, -1)
      game.joystick = MockJoystick(Vector2(0, -1));
      await game.ensureAdd(game.joystick);

      // Add hero
      final hero = HeroComponent(heroId: 'hero_default');
      await game.ensureAdd(hero);
      hero.position = Vector2(100, 100); 
      game.hero = hero;

      // Add monster nearby (Right side)
      // If it were auto-locking, it might go Right (1, 0).
      // But we want it to go UP (0, -1) because of Joystick.
      final m1 = DummyMonster(Vector2(200, 100), 'elite_orc');
      await game.ensureAdd(m1);

      hero.state = CharacterState.attack;

      // Create DashHitbox
      final dash = DashHitbox(
        owner: hero,
        size: Vector2(32, 32),
        damage: 10,
        targetType: MonsterComponent,
        speed: 1000,
        duration: 1.0,
      );
      await game.ensureAdd(dash);

      // Update 0.1s
      game.update(0.1);

      // Should move UP (y decreases)
      // Delta = 1000 * 0.1 = 100.
      // New y = 100 - 100 = 0.
      expect(hero.position.y, closeTo(0, 1.0));
      expect(hero.position.x, closeTo(100, 1.0)); // X shouldn't change
      
      // Also check dash hitbox position synced
      expect(dash.position.y, closeTo(0, 1.0));
    });

    testWithGame<TestMyGame>('Dash follows facing direction if no joystick', () {
      return TestMyGame();
    }, (game) async {
      final heroImg = await generateImage(96, 96);
      game.images.add('character/Satyr.png', heroImg);
      
      // Joystick Zero
      game.joystick = MockJoystick(Vector2.zero());
      await game.ensureAdd(game.joystick);
      
      final hero = HeroComponent(heroId: 'hero_default');
      await game.ensureAdd(hero);
      hero.position = Vector2(100, 100);
      hero.facingRight = false; // Face Left
      game.hero = hero;

      final dash = DashHitbox(
        owner: hero,
        size: Vector2(32, 32),
        damage: 10,
        targetType: MonsterComponent,
        speed: 1000,
        duration: 1.0,
      );
      await game.ensureAdd(dash);

      game.update(0.1);

      // Should move LEFT (x decreases)
      // Delta = 1000 * 0.1 = 100.
      // New x = 100 - 100 = 0.
      expect(hero.position.x, closeTo(0, 1.0));
      expect(hero.position.y, closeTo(100, 1.0));
    });
  });
}
