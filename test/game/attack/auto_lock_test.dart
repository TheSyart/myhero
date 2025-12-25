import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import 'package:myhero/game/attack/component/melee_hitbox.dart';
import 'package:myhero/game/attack/component/bullet_hitbox.dart';
import 'package:myhero/game/config/bullet_config.dart';

class TestMyGame extends MyGame {
  @override
  Future<void> onLoad() async {
    // 简化测试环境：不加载地图与其他资源
  }
}

class DummyMonster extends MonsterComponent {
  DummyMonster(Vector2 birth, String id) : super(birth, id);
  @override
  void update(double dt) {
    // 测试用：不移动，不攻击
  }
}

void main() {
  group('Auto Lock Attack Tests', () {
    testWithGame<TestMyGame>('AttackHitbox rotates toward nearest enemy in range', () {
      return TestMyGame();
    }, (game) async {
      // 准备角色贴图
      // 保证贴图尺寸是 cellSize 的整数倍，避免动画分片错误
      final heroImg = await generateImage(96, 96); // hero cellSize: 32x32
      final monsterImg = await generateImage(300, 300); // elite_orc cellSize: 100x100
      game.images.add('character/Satyr.png', heroImg);
      game.images.add('character/Elite Orc.png', monsterImg);

      // 初始化摇杆以避免 HeroComponent.update 访问未初始化对象
      game.joystick = JoystickComponent(
        knob: CircleComponent(radius: 1),
        background: CircleComponent(radius: 2),
      );

      // 添加英雄与怪物
      final hero = HeroComponent(heroId: 'hero_default')..position = Vector2(100, 100);
      await game.ensureAdd(hero);
      game.hero = hero;

      final m1 = DummyMonster(Vector2(200, 100), 'elite_orc');
      final m2 = DummyMonster(Vector2(260, 120), 'elite_orc');
      await game.ensureAdd(m1);
      await game.ensureAdd(m2);

      // 在英雄前方生成一个攻击矩形（给予较大尺寸以覆盖两个怪）
      final attackSize = Vector2(120, 60);
      final topLeft = Vector2(140, 70); // 接近两个怪物的区域
      final attack = MeleeHitbox(
        owner: hero,
        position: topLeft,
        size: attackSize,
        damage: 1,
        targetType: MonsterComponent,
      );
      await game.ensureAdd(attack);

      // 推进一帧，让自动锁定生效
      game.update(0.016);

      // 期待旋转指向最近怪物 m1
      final center = attack.position.clone(); // AttackHitbox 的 position 为中心点
      final expectedAngle = math.atan2(m1.position.y - center.y, m1.position.x - center.x);
      expect(attack.angle, closeTo(expectedAngle, 1e-3));
    });

    testWithGame<TestMyGame>('BulletHitbox locks path from owner to nearest enemy', () {
      return TestMyGame();
    }, (game) async {
      // 准备贴图
      final heroImg = await generateImage(96, 96); // 32x32 的整数倍
      final monsterImg = await generateImage(300, 300); // 100x100 的整数倍
      final bulletImg = await generateImage(512, 16); // 16x16 * 32 帧
      game.images.add('character/Satyr.png', heroImg);
      game.images.add('character/Elite Orc.png', monsterImg);
      game.images.add('bullet/fire_ball.png', bulletImg);

      game.joystick = JoystickComponent(
        knob: CircleComponent(radius: 1),
        background: CircleComponent(radius: 2),
      );

      final hero = HeroComponent(heroId: 'hero_default')..position = Vector2(50, 50);
      await game.ensureAdd(hero);
      game.hero = hero;

      final m1 = DummyMonster(Vector2(150, 50), 'elite_orc');
      final m2 = DummyMonster(Vector2(300, 50), 'elite_orc');
      await game.ensureAdd(m1);
      await game.ensureAdd(m2);

      final cfg = BulletConfig.byId('fire_ball')!;
      final bullet = BulletHitbox(
        config: cfg,
        direction: Vector2(1, 0), // 初始方向将被自动锁定覆盖
        owner: hero,
        targetType: MonsterComponent,
        damage: 2,
        position: hero.position.clone(),
      );
      await game.ensureAdd(bullet);

      // 推进一帧以锁定最近目标
      game.update(0.016);

      // 再推进一段时间，子弹应向目标靠近（距离减小）
      final prevX = bullet.position.x;
      game.update(0.1);
      expect(bullet.position.x > prevX, isTrue);
    });

    testWithGame<TestMyGame>('Bullet ignores joystick and keeps initial direction', () {
      return TestMyGame();
    }, (game) async {
       // 准备贴图
      final heroImg = await generateImage(96, 96);
      final monsterImg = await generateImage(300, 300);
      final bulletImg = await generateImage(512, 16);
      game.images.add('character/Satyr.png', heroImg);
      game.images.add('character/Elite Orc.png', monsterImg);
      game.images.add('bullet/fire_ball.png', bulletImg);

      game.joystick = JoystickComponent(
        knob: CircleComponent(radius: 1),
        background: CircleComponent(radius: 2),
      );

      final hero = HeroComponent(heroId: 'hero_default')..position = Vector2(0, 0);
      await game.ensureAdd(hero);
      game.hero = hero;

      // 放置一个超出默认锁定距离(300)的怪物
      final farMonster = DummyMonster(Vector2(400, 0), 'elite_orc');
      await game.ensureAdd(farMonster);

      // 模拟摇杆向下方输入
       // 手动设置 delta 才是最稳妥的测试方式
       // 因为 JoystickComponent.update 依赖于事件输入或复杂的 update 逻辑
       game.joystick.delta.setValues(0, 1);
       
       final cfg = BulletConfig.byId('fire_ball')!;
      final bullet = BulletHitbox(
        config: cfg,
        direction: Vector2(1, 0), // 初始向右
        owner: hero,
        targetType: MonsterComponent,
        damage: 2,
        position: hero.position.clone(),
      );
      // 手动设置最大锁定距离小于怪物距离
      // BulletHitbox 不会索敌，且忽略摇杆方向，应保持初始方向

      await game.ensureAdd(bullet);
      game.update(0.016);

      // 验证：忽略摇杆，保持初始方向 (1, 0)
      final expectedDir = Vector2(1, 0);
      expect(bullet.direction.x, closeTo(expectedDir.x, 0.001));
      expect(bullet.direction.y, closeTo(expectedDir.y, 0.001));
    });

    testWithGame<TestMyGame>('Bullet locks direction on first frame even without input', () {
      return TestMyGame();
    }, (game) async {
      await game.images.load('character/Satyr.png');
      game.joystick = JoystickComponent(knob: CircleComponent(radius: 1), background: CircleComponent(radius: 2));
      // 不要 add joystick，以便手动控制 delta 而不被 update 重置
      // await game.ensureAdd(game.joystick);

      final hero = HeroComponent(heroId: 'hero_default')..position = Vector2(100, 100);
      await game.ensureAdd(hero);
      game.hero = hero;

      // 1. 初始状态：无敌人，摇杆无输入
      game.joystick.delta.setValues(0, 0);

      final cfg = BulletConfig.byId('fire_ball')!;
      final initialDirection = Vector2(1, 0); // 假设初始向右
      final bullet = BulletHitbox(
        config: cfg,
        owner: hero,
        targetType: DummyMonster,
        damage: 10,
        position: hero.position.clone(),
        direction: initialDirection,
      );
      await game.ensureAdd(bullet);

      // 2. 第一帧更新：应该尝试锁定。没敌人，没摇杆 -> 应该锁定初始方向
      game.update(0.016);
      
      expect(bullet.direction.x, closeTo(initialDirection.x, 0.001));
      expect(bullet.direction.y, closeTo(initialDirection.y, 0.001));

      // 3. 模拟摇杆输入：向下
      game.joystick.delta.setValues(0, 1);
      
      // 4. 第二帧更新：子弹方向不应改变
      game.update(0.016);

      // 期望：方向仍然是 (1, 0)，而不是 (0, 1)
      // 如果 bug 存在，这里会变成 (0, 1)
      expect(bullet.direction.x, closeTo(initialDirection.x, 0.001));
      expect(bullet.direction.y, closeTo(initialDirection.y, 0.001));
    });
  });
}
