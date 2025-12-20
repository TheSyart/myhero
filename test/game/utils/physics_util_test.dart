import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/character_component.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/component/wall_component.dart';
import 'package:myhero/utils/physics_util.dart';

class TestMyGame extends MyGame {
  @override
  Future<void> onLoad() async {
    // Skip loading
  }
}

class TestCharacter extends HeroComponent {
  TestCharacter(Vector2 position) : super(birthPosition: position);
}

void main() {
  group('PhysicsUtil Tests', () {
    testWithGame<TestMyGame>('resolveOverlaps pushes character out of wall', () {
      return TestMyGame();
    }, (game) async {
      game.joystick = JoystickComponent(
        knob: CircleComponent(),
        background: CircleComponent(),
      );
      
      final heroImg = await generateImage(96, 96);
      game.images.add('character/Satyr.png', heroImg);

      final wall = WallComponent(
        position: Vector2(100, 100),
        size: Vector2(50, 50),
      );
      game.blockers.add(wall);
      await game.world.ensureAdd(wall);

      final character = TestCharacter(Vector2(95, 110)); 
      await game.world.ensureAdd(character);
      game.hero = character;

      await game.ready();
      
      // Initial state check
      expect(character.position.x, equals(95));
      
      // Call Util directly
      PhysicsUtil.resolveOverlaps(character, 0.016);
      
      // Character should be pushed to the left
      expect(character.position.x, lessThan(95));
      expect(character.lastCorrection, isNotNull);
      expect(character.lastCorrection!.x, lessThan(0));
    });

    testWithGame<TestMyGame>('resolveOverlaps pushes two characters apart', () {
      return TestMyGame();
    }, (game) async {
      game.joystick = JoystickComponent(
        knob: CircleComponent(),
        background: CircleComponent(),
      );
      final heroImg = await generateImage(96, 96);
      game.images.add('character/Satyr.png', heroImg);

      final c1 = TestCharacter(Vector2(100, 100));
      final c2 = TestCharacter(Vector2(110, 100)); // Overlap X = 15, Y = 20. Should resolve X.
      
      await game.world.ensureAdd(c1);
      await game.world.ensureAdd(c2);
      
      await game.ready();

      // Debug check
      final chars = game.world.children.query<CharacterComponent>();
      print('Test: Found ${chars.length} characters');
      for (final c in chars) {
         print('Test: Char at ${c.position}, hitbox: ${c.hitbox.size}, absoluteRect: ${c.hitbox.toAbsoluteRect()}');
      }

      // Call for c1
      PhysicsUtil.resolveOverlaps(c1, 0.016);
      
      // c1 should move left (away from c2)
      // Note: In dynamic collision, we only move self by 50% correction.
      expect(c1.position.x, lessThan(100));
      expect(c1.lastCorrection!.x, lessThan(0));
    });
  });
}
