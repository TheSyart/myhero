import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import 'package:myhero/game/attack/factory/generate_factory.dart';
import 'package:myhero/game/state/character_state.dart';

class TestMyGame extends MyGame {
  @override
  Future<void> onLoad() async {
    // Skip loading
  }
}

class DummyMonster extends MonsterComponent {
  DummyMonster(Vector2 birth, String id) : super(birth, id);
  @override
  void update(double dt) {
    super.update(dt);
  }
}

void main() {
  group('Summon AI Tests', () {
    testWithGame<TestMyGame>('Hero summons HeroComponent minion', () {
      return TestMyGame();
    }, (game) async {
      // Setup joystick for HeroComponent
      game.joystick = JoystickComponent(
        knob: CircleComponent(),
        background: CircleComponent(),
      );
      
      final heroImg = await generateImage(96, 96);
      game.images.add('character/Satyr.png', heroImg);
      
      final owner = HeroComponent(heroId: 'hero_default');
      await game.world.ensureAdd(owner);
      owner.position = Vector2(0, 0);
      game.hero = owner;

      final summon = GenerateFactory.create(
        position: Vector2(10, 10),
        generateId: 'hero_default',
        owner: owner,
        enemyType: MonsterComponent,
      );
      await game.world.ensureAdd(summon);

      expect(summon, isA<HeroComponent>());
      expect(summon.isGenerate, isTrue);
      expect(summon.summonOwner, owner);
    });

    testWithGame<TestMyGame>('Monster summons MonsterComponent minion', () {
      return TestMyGame();
    }, (game) async {
      final monsterImg = await generateImage(300, 300);
      game.images.add('character/Elite Orc.png', monsterImg);
      
      final owner = DummyMonster(Vector2(0, 0), 'elite_orc');
      await game.world.ensureAdd(owner);

      final summon = GenerateFactory.create(
        position: Vector2(10, 10),
        generateId: 'elite_orc',
        owner: owner,
        enemyType: HeroComponent,
      );
      await game.world.ensureAdd(summon);

      expect(summon, isA<MonsterComponent>());
      expect(summon.isGenerate, isTrue);
      expect(summon.summonOwner, owner);
    });

    testWithGame<TestMyGame>('Summon targets enemy correctly', () {
      return TestMyGame();
    }, (game) async {
      game.joystick = JoystickComponent(
        knob: CircleComponent(),
        background: CircleComponent(),
      );

      final heroImg = await generateImage(96, 96);
      final monsterImg = await generateImage(300, 300);
      game.images.add('character/Satyr.png', heroImg);
      game.images.add('character/Elite Orc.png', monsterImg);

      // Setup Owner (Hero)
      final owner = HeroComponent(heroId: 'hero_default', birthPosition: Vector2(0, 0));
      await game.world.ensureAdd(owner);
      game.hero = owner;

      // Setup Summon (Hero Minion)
      final summon = GenerateFactory.create(
        position: Vector2(100, 100),
        generateId: 'hero_default',
        owner: owner,
        enemyType: MonsterComponent,
      );
      await game.world.ensureAdd(summon);
      
      // Setup Enemy (Monster)
      final enemy = DummyMonster(Vector2(200, 100), 'elite_orc');
      await game.world.ensureAdd(enemy);

      // Update to trigger AI
      game.update(0.1);

      // Summon should move towards enemy
      // Initial dist to enemy: 100.
      // After update, should be closer.
      
      // Check state
      expect(summon.state, CharacterState.run);
      
      // Check movement
      // Assuming speed > 0
      final newDist = (summon.position - enemy.position).length;
      expect(newDist, lessThan(100));
    });

    testWithGame<TestMyGame>('Summon follows owner when no enemy', () {
      return TestMyGame();
    }, (game) async {
      game.joystick = JoystickComponent(
        knob: CircleComponent(),
        background: CircleComponent(),
      );

      final heroImg = await generateImage(96, 96);
      game.images.add('character/Satyr.png', heroImg);

      // Setup Owner (Hero)
      final owner = HeroComponent(heroId: 'hero_default');
      await game.world.ensureAdd(owner);
      owner.position = Vector2(0, 0);
      game.hero = owner;

      // Setup Summon (Hero Minion) at distance 300 (followDistance is 150)
      final summon = GenerateFactory.create(
        position: Vector2(300, 0),
        generateId: 'hero_default',
        owner: owner,
        enemyType: MonsterComponent,
        followDistance: 150,
      );
      await game.world.ensureAdd(summon);

      // Update
      game.update(0.1);

      // Summon should move towards owner
      expect(summon.state, CharacterState.run);
      expect(summon.position.x, lessThan(300));
    });
  });
}
