import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import 'package:myhero/game/state/character_state.dart';
import 'package:myhero/utils/ai_util.dart';

class TestMyGame extends MyGame {
  @override
  Future<void> onLoad() async {
    // Skip loading
  }
}

class TestHero extends HeroComponent {
  TestHero({String heroId = 'hero_default', Vector2? birthPosition})
      : super(heroId: heroId, birthPosition: birthPosition ?? Vector2.zero());
}

class TestMonster extends MonsterComponent {
  TestMonster(Vector2 position, String id) : super(position, id);
}

void main() {
  group('AiUtil Tests', () {
    testWithGame<TestMyGame>('updateSummonAI follows owner', () {
      return TestMyGame();
    }, (game) async {
      // Setup joystick for HeroComponent (needed for update logic if not overridden)
      game.joystick = JoystickComponent(
        knob: CircleComponent(),
        background: CircleComponent(),
      );

      final heroImg = await generateImage(96, 96);
      game.images.add('character/Satyr.png', heroImg);

      final owner = TestHero(birthPosition: Vector2(0, 0));
      await game.world.ensureAdd(owner);
      game.hero = owner;

      final summon = TestHero(birthPosition: Vector2(200, 0));
      summon.isGenerate = true;
      summon.summonOwner = owner;
      await game.world.ensureAdd(summon);
      
      // Override speed/params if needed, or rely on config
      // Default followDistance is likely small.
      // Distance is 200.
      
      AiUtil.updateSummonAI(summon, 0.1);
      
      // Should move towards owner (left)
      expect(summon.state, CharacterState.run);
      // Face left
      expect(summon.scale.x, lessThan(0)); 
    });

    testWithGame<TestMyGame>('updateMonsterAI chases hero', () {
      return TestMyGame();
    }, (game) async {
      final heroImg = await generateImage(96, 96);
      final monsterImg = await generateImage(300, 300);
      game.images.add('character/Satyr.png', heroImg);
      game.images.add('character/Elite Orc.png', monsterImg);

      final hero = TestHero(birthPosition: Vector2(0, 0));
      await game.world.ensureAdd(hero);
      game.hero = hero;

      final monster = TestMonster(Vector2(100, 0), 'elite_orc');
      await game.world.ensureAdd(monster);

      // Distance is 100.
      // Assuming detectRadius > 100 and attackRange < 100.
      
      AiUtil.updateMonsterAI(monster, 0.1);

      // Should chase
      expect(monster.state, CharacterState.run);
      // Face left (hero is at 0, monster at 100)
      expect(monster.scale.x, lessThan(0));
    });
  });
}
