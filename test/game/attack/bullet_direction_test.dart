import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/weapon/component/weapon_component.dart';
import 'package:myhero/game/attack/component/bullet_hitbox.dart';
import 'dart:math';

class TestGame extends MyGame {
  @override
  Future<void> onLoad() async {
    // Skip full game load
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Bullet Direction and Rotation', () {
    testWithGame<TestGame>('Bullet inherits weapon direction and rotation', () {
      return TestGame();
    }, (game) async {
      // Load necessary images
      final img = await generateImage(32, 32);
      game.images.add('character/Satyr.png', img);
      game.images.add('weapon/AK47/AK47.png', img);
      game.images.add('bullet/bullet.png', img);

      final hero = HeroComponent(heroId: 'hero_default');
      await game.ensureAdd(hero);
      
      // Equip AK47 which has rotationOffset = -pi/2
      // WeaponConfig.byId('AK47')
      hero.equipWeapon('AK47');
      await game.ready(); // Wait for weapon to load
      
      final weapon = hero.weapon!;
      expect(weapon, isNotNull);
      
      // Case 1: Aim Right (0 rad)
      // Visual Angle = 0 + (-pi/2) = -pi/2
      // We set weapon angle manually to simulate aiming
      weapon.angle = -pi / 2;
      
      weapon.attack();
      await game.ready();
      
      // Find the bullet
      final bullet = game.world.children.whereType<BulletHitbox>().last;
      
      // Bullet direction should be (1, 0) (Right)
      // Because Visual Angle (-pi/2) - Offset (-pi/2) = 0
      expect(bullet.direction.x, closeTo(1.0, 0.001));
      expect(bullet.direction.y, closeTo(0.0, 0.001));
      
      // Bullet update should set angle
      bullet.update(0.016);
      expect(bullet.angle, closeTo(0.0, 0.001));
      
      // Clean up
      bullet.removeFromParent();
      await game.ready();
      
      // Case 2: Aim Down (pi/2 rad)
      // Visual Angle = pi/2 + (-pi/2) = 0
      weapon.angle = 0;
      
      weapon.attack();
      await game.ready();
      
      final bullet2 = game.world.children.whereType<BulletHitbox>().last;
      
      // Bullet direction should be (0, 1) (Down)
      // Visual Angle (0) - Offset (-pi/2) = pi/2
      expect(bullet2.direction.x, closeTo(0.0, 0.001));
      expect(bullet2.direction.y, closeTo(1.0, 0.001));
      
      bullet2.update(0.016);
      expect(bullet2.angle, closeTo(pi / 2, 0.001));
      
      // Clean up
      bullet2.removeFromParent();
      await game.ready();
      
      // Case 3: Aim Left (pi) with Parent Flipped
      // Facing Left
      hero.flipHorizontallyAroundCenter(); // scale.x = -1
      hero.facingRight = false;
      
      // To Aim Left (World), we want Local Angle = 0 (because Local Right -> World Left)
      // rotateToWorldAngle(pi) with Flipped Parent:
      // worldAngle = pi.
      // scale.x < 0 -> worldAngle = pi - pi = 0.
      // angle = 0 + offset.
      
      // So let's simulate input Aim Left
      weapon.rotateToWorldAngle(pi);
      
      // Expect weapon.angle to be offset (since worldAngle=0)
      // offset = -pi/2. angle = -pi/2.
      expect(weapon.angle, closeTo(-pi / 2, 0.001));
      
      weapon.attack();
      await game.ready();
      
      final bullet3 = game.world.children.whereType<BulletHitbox>().last;
      
      // Bullet Direction should be Left (-1, 0)
      // Calculation:
      // shootingAngle = angle (-pi/2) - offset (-pi/2) = 0.
      // vx = cos(0) = 1.
      // !facingRight -> vx = -1.
      // dir = (-1, 0).
      
      expect(bullet3.direction.x, closeTo(-1.0, 0.001));
      expect(bullet3.direction.y, closeTo(0.0, 0.001));
      
      bullet3.update(0.016);
      // Angle should be pi (or -pi)
      expect(bullet3.angle.abs(), closeTo(pi, 0.001));
    });
  });
}
