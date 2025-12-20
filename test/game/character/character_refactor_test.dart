import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/state/character_state.dart';
import 'package:myhero/game/config/character_config.dart';

class TestMyGame extends MyGame {
  @override
  Future<void> onLoad() async {
    // Override to avoid loading map and other assets
  }
}

void main() {
  group('CharacterComponent Refactoring Tests', () {
    late TestMyGame game;

    setUp(() {
      game = TestMyGame();
    });

    testWithGame<TestMyGame>('HeroComponent initializes correctly with config and animations', () {
      return TestMyGame();
    }, (game) async {
      // Mock the sprite image
      final image = await generateImage(100, 100);
      game.images.add('character/Satyr.png', image);

      final hero = HeroComponent(heroId: 'hero_default');
      await game.ensureAdd(hero);

      // Verify basic properties from config
      final cfg = CharacterConfig.byId('hero_default')!;
      expect(hero.maxHp, equals(cfg.maxHp));
      expect(hero.attackValue, equals(cfg.attackValue));
      expect(hero.speed, equals(cfg.speed));
      expect(hero.size, equals(cfg.componentSize));

      // Verify animations loaded
      expect(hero.animations, isNotEmpty);
      expect(hero.animations.containsKey(CharacterState.idle), isTrue);
      expect(hero.animations.containsKey(CharacterState.run), isTrue);
      expect(hero.animations[CharacterState.idle], isNotNull);
    });

    testWithGame<TestMyGame>('MonsterComponent initializes correctly with config and animations', () {
      return TestMyGame();
    }, (game) async {
      // Mock the sprite image
      final image = await generateImage(100, 100);
      game.images.add('character/Elite Orc.png', image);

      final monster = MonsterComponent(Vector2.zero(), 'elite_orc');
      await game.ensureAdd(monster);

      // Verify basic properties from config
      final cfg = CharacterConfig.byId('elite_orc')!;
      expect(monster.maxHp, equals(cfg.maxHp));
      expect(monster.attackValue, equals(cfg.attackValue));
      expect(monster.speed, equals(cfg.speed));
      expect(monster.size, equals(cfg.componentSize));

      // Verify animations loaded
      expect(monster.animations, isNotEmpty);
      expect(monster.animations.containsKey(CharacterState.idle), isTrue);
      expect(monster.animations.containsKey(CharacterState.run), isTrue);
      expect(monster.animations[CharacterState.idle], isNotNull);
    });
  });
}
