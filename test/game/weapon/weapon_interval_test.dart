import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/attack/component/bullet_hitbox.dart';
import 'package:myhero/game/weapon/component/weapon_component.dart';

import 'package:myhero/game/character/monster_component.dart';

class TestMyGame extends MyGame {
  @override
  Future<void> onLoad() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Weapon auto fire interval', () {
    testWithGame<TestMyGame>('fires bullets respecting AttackSpec.interval when target is present', () {
      return TestMyGame();
    }, (game) async {
      // Preload required images
      final heroImg = await generateImage(1024, 1024); // Make it large enough for sprite sheets
      final weaponImg = await generateImage(96, 48);
      final bulletImg = await generateImage(16, 16);
      game.images.add('character/Satyr.png', heroImg);
      game.images.add('character/Armored Axeman.png', heroImg);
      game.images.add('weapon/AK47/AK47.png', weaponImg);
      game.images.add('weapon/Revolver-Colt45/Revolver-Colt45.png', weaponImg);
      game.images.add('bullet/bullet.png', bulletImg);

      // Minimal joystick to avoid nulls in character update
      game.joystick = JoystickComponent(
        knob: CircleComponent(radius: 1),
        background: CircleComponent(radius: 2),
      );

      final hero = HeroComponent(heroId: 'hero_default', birthPosition: Vector2(100, 100));
      await game.ensureAdd(hero);
      game.hero = hero;

      // Add a monster target nearby
      final monster = MonsterComponent(Vector2(150, 100), 'armored_axeman');
      await game.ensureAdd(monster);

      // Equip weapon with interval = 0.5s (AK47)
      hero.equipWeapon('AK47');
      // Allow weapon to load
      await game.ready();
      
      // Initial update to find target and fire
      game.update(0.01);
      await game.ready(); // Wait for bullet to be added

      // After first update, should fire immediately because we have a target
      int bullets = game.world.children.whereType<BulletHitbox>().length;
      expect(bullets, greaterThanOrEqualTo(1));

      // Advance 0.49s, still 1 bullet (cooldown is 0.5s)
      game.update(0.49);
      bullets = game.world.children.whereType<BulletHitbox>().length;
      expect(bullets, equals(1));

      // Cross 0.5s threshold -> 2 bullets
      game.update(0.02);
      bullets = game.world.children.whereType<BulletHitbox>().length;
      expect(bullets, equals(2));

      // Another 0.5s -> 3 bullets
      game.update(0.5);
      bullets = game.world.children.whereType<BulletHitbox>().length;
      expect(bullets, equals(3));
    });
  });
}
