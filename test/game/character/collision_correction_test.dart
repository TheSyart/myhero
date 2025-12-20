import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/component/wall_component.dart';
import 'package:myhero/game/character/character_component.dart';

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
  group('Collision Correction Tests', () {
    testWithGame<TestMyGame>('Character pushed out of wall (X axis)', () {
      return TestMyGame();
    }, (game) async {
      game.joystick = JoystickComponent(
        knob: CircleComponent(),
        background: CircleComponent(),
      );
      
      final heroImg = await generateImage(96, 96);
      game.images.add('character/Satyr.png', heroImg);

      // Create a wall at (100, 100) with size (50, 50)
      final wall = WallComponent(
        position: Vector2(100, 100),
        size: Vector2(50, 50),
      );
      game.blockers.add(wall);
      await game.world.ensureAdd(wall);

      // Create a character overlapping the wall from the left
      // Wall x range: 100-150. Character width approx 32 (hitbox).
      // Place character at 90. Overlap starts at 100.
      // Character center ~ 90 + 16 = 106?
      // HeroComponent hitbox is usually smaller than the sprite.
      // Let's assume hitbox is centered.
      
      final character = TestCharacter(Vector2(95, 110)); 
      await game.world.ensureAdd(character);
      game.hero = character;

      // Force update to run collision detection
      // character.update(0.1); 
      // We need to wait for hitboxes to be computed.
      await game.ready();
      
      // Manually trigger resolveOverlaps or wait for update
      character.update(0.016);
      
      // Character should be pushed to the left (x < 95)
      // Because shallowest axis is X.
      // Overlap X: Character Right > Wall Left.
      // Character Right ~ 95 + width. Wall Left = 100.
      // If character is deep enough, it should be pushed out.
      
      // Let's check initial position vs corrected position.
      // We expect position.x to decrease.
      expect(character.position.x, lessThan(95));
      expect(character.position.y, equals(110)); // Y shouldn't change
    });

    testWithGame<TestMyGame>('Character pushed out of wall (Y axis)', () {
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

      // Character overlapping from top
      // Wall y range: 100-150.
      final character = TestCharacter(Vector2(110, 95)); 
      await game.world.ensureAdd(character);
      game.hero = character;

      await game.ready();
      character.update(0.016);

      // Character should be pushed up (y < 95)
      expect(character.position.y, lessThan(95));
      expect(character.position.x, equals(110));
    });

    testWithGame<TestMyGame>('Characters push each other apart (X axis preference)', () {
      return TestMyGame();
    }, (game) async {
      game.joystick = JoystickComponent(
        knob: CircleComponent(),
        background: CircleComponent(),
      );
      final heroImg = await generateImage(96, 96);
      game.images.add('character/Satyr.png', heroImg);

      // Char1 at (100, 100)
      // Hitbox X range: ~92.5 to 117.5 (width 25)
      // Hitbox Y range: ~120 to 140 (height 20)
      final char1 = TestCharacter(Vector2(100, 100));
      
      // Char2 at (110, 100)
      // Hitbox X range: ~102.5 to 127.5
      // Overlap X: 117.5 - 102.5 = 15
      // Overlap Y: 20 (Full height)
      // 15 < 20 -> X axis correction
      final char2 = TestCharacter(Vector2(110, 100)); 
      
      await game.world.ensureAdd(char1);
      await game.world.ensureAdd(char2);
      game.hero = char1;

      await game.ready();
      
      final initialX1 = char1.position.x;
      final initialX2 = char2.position.x;

      char1.update(0.016);
      char2.update(0.016);

      // Char1 should move left, Char2 should move right
      expect(char1.position.x, lessThan(initialX1));
      expect(char2.position.x, greaterThan(initialX2));
      
      // Y should not change
      expect(char1.position.y, equals(100));
      expect(char2.position.y, equals(100));
    });

    testWithGame<TestMyGame>('Corner Collision (Slide around corner)', () {
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

      // Hitbox Size: 25x20. Center offset roughly (0, 20) from pos?
      // Pos (100, 100) -> Hitbox (92.5, 120).
      
      // Place character near top-left corner of wall
      // Wall Top-Left: (100, 100).
      // We want to hit the corner such that X overlap < Y overlap or vice versa.
      // If we come from diagonal (-1, -1).
      
      // Let's try to position such that X overlap is small, Y overlap is large.
      // Wall X: 100.
      // Char Hitbox Right needs to penetrate 100 slightly.
      // Hitbox Right = PosX - 50 + 42.5 + 25 = PosX + 17.5.
      // Set PosX + 17.5 = 105 -> PosX = 87.5.
      // Overlap X = 5.
      
      // Wall Y: 100.
      // Char Hitbox Bottom needs to penetrate 100 deeply.
      // Hitbox Bottom = PosY - 50 + 70 + 20 = PosY + 40.
      // Set PosY + 40 = 110 -> PosY = 70.
      // Overlap Y = 10.
      
      // Overlap X (5) < Overlap Y (10). Should push Left (X).
      
      final character = TestCharacter(Vector2(87.5, 70));
      await game.world.ensureAdd(character);
      game.hero = character;

      await game.ready();
      character.update(0.016);
      
      // Should push Left
      expect(character.position.x, lessThan(87.5));
      // Y should stay same (slide)
      expect(character.position.y, equals(70));
    });

    testWithGame<TestMyGame>('Multiple Walls Collision (Over-correction safe)', () {
      return TestMyGame();
    }, (game) async {
      game.joystick = JoystickComponent(
        knob: CircleComponent(),
        background: CircleComponent(),
      );
      final heroImg = await generateImage(96, 96);
      game.images.add('character/Satyr.png', heroImg);

      // Wall A: (100, 100) to (150, 150)
      final wallA = WallComponent(position: Vector2(100, 100), size: Vector2(50, 50));
      // Wall B: (100, 150) to (150, 200)
      final wallB = WallComponent(position: Vector2(100, 150), size: Vector2(50, 50));
      
      game.blockers.add(wallA);
      game.blockers.add(wallB);
      await game.world.ensureAdd(wallA);
      await game.world.ensureAdd(wallB);

      // Character at intersection seam
      // PosX such that overlaps both walls on X (shallow).
      // Hitbox Right = PosX + 17.5.
      // Wall Left = 100.
      // PosX = 85 -> Hitbox Right = 102.5. Overlap X = 2.5.
      
      // PosY such that overlaps both walls on Y.
      // Hitbox Top = PosY + 20. Hitbox Bottom = PosY + 40.
      // Wall A Bottom = 150. Wall B Top = 150.
      // Hitbox needs to straddle 150.
      // PosY = 120 -> Top 140, Bottom 160.
      // Overlap A Y: 140-150 (10).
      // Overlap B Y: 150-160 (10).
      
      // For Wall A: Overlap X (2.5) < Overlap Y (10). Push Left 2.5.
      // totalCorrection becomes (-2.5, 0).
      // For Wall B: _solveCollision uses myRect.shift(totalCorrection).
      // Shifted Rect X Right becomes 102.5 - 2.5 = 100.
      // Wall B Left is 100. Overlap is 0. No further correction needed.
      // Total X Correction: -2.5.
      
      final character = TestCharacter(Vector2(85, 120));
      await game.world.ensureAdd(character);
      game.hero = character;

      await game.ready();
      character.update(0.016);
      
      // Should be pushed left
      expect(character.position.x, lessThan(85));
      // Should be pushed exactly 2.5 to clear the wall
      expect(character.position.x, closeTo(82.5, 0.1));
    });

    testWithGame<TestMyGame>('Low FPS Stability (Large DT)', () {
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

      // Character deeply inside wall (e.g. due to lag spike)
      // Pos (100, 100).
      final character = TestCharacter(Vector2(100, 100));
      await game.world.ensureAdd(character);
      game.hero = character;

      await game.ready();
      
      // Update with large DT (e.g. 1.0 second)
      // Should still resolve correctly without flying off
      character.update(1.0);
      
      // Should be pushed out
      expect(character.position.x, lessThan(100));
      // Should be just outside
      // Overlap X: 92.5 to 117.5 vs 100 to 150. Overlap 17.5.
      // Overlap Y: 120 to 140 vs 100 to 150. Overlap 20.
      // X is shallowest. Push Left 17.5.
      // New X: 100 - 17.5 = 82.5.
      expect(character.position.x, closeTo(82.5, 0.1));
    });



  });
}
