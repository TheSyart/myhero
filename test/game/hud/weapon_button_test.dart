import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/hud/attack/weapon_button.dart';
import 'package:myhero/game/character/hero_component.dart';

class TestGame extends MyGame {
  @override
  Future<void> onLoad() async {
    // Skip full game load
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('WeaponButton', () {
    testWithGame<TestGame>('scales weapon icon correctly', () {
      return TestGame();
    }, (game) async {
      // Create a mock image (e.g. 100x50)
      final img = await generateImage(100, 50);
      game.images.add('weapon_icon.png', img);
      
      final hero = HeroComponent(heroId: 'hero_default');
      // We don't need to add hero to game for this test, just pass it
      
      final button = WeaponButton(
        hero: hero,
        icon: 'weapon_icon.png',
        onPressed: () {},
      );
      
      await game.ensureAdd(button);
      
      // Find the SpriteComponent child
      final iconComponent = button.children.whereType<SpriteComponent>().first;
      
      // Target size is 48x48 box.
      // Original 100x50 (2:1 ratio).
      // Should scale to fit 48 width.
      // Scale = 48 / 100 = 0.48.
      // Width = 48.
      // Height = 50 * 0.48 = 24.
      
      expect(iconComponent.size.x, closeTo(48.0, 0.001));
      expect(iconComponent.size.y, closeTo(24.0, 0.001));
      
      // Check position is centered
      // Button size 72x72.
      // Icon 48x24.
      // X = (72 - 48) / 2 = 12.
      // Y = (72 - 24) / 2 = 24.
      // But anchor is center, position is center of button?
      // Wait, in code:
      // position: size / 2
      // anchor: Anchor.center
      // So position should be (36, 36).
      
      expect(iconComponent.position.x, closeTo(36.0, 0.001));
      expect(iconComponent.position.y, closeTo(36.0, 0.001));
      expect(iconComponent.anchor, Anchor.center);
    });
  });
}
