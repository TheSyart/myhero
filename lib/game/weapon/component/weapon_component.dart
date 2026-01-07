import 'package:flame/components.dart';
import 'package:myhero/game/config/weapon_config.dart';
import 'package:myhero/game/character/character_component.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import '../../attack/factory/attack_hitbox_factory.dart';
import 'dart:math';
import 'package:flame/collisions.dart';
import '../../interaction/promptable_interactable_mixin.dart';

class WeaponComponent extends SpriteComponent with HasGameReference<MyGame> {
  final String weaponId;
  final CharacterComponent owner;
  late final Type targetType;
  final WeaponConfig config;
  double interval;

  // 敌人目标
  PositionComponent? enemyTarget;

  double _attackCooldown = 0.0;

  WeaponComponent({required this.weaponId, required this.owner})
    : config = WeaponConfig.byId(weaponId)!,
      interval = 0.0;

  @override
  Future<void> onLoad() async {
    targetType = owner is HeroComponent ? MonsterComponent : HeroComponent;

    sprite = await game.loadSprite(config.spritePath);

    size = config.size;
    anchor = config.anchor;

    // 武器优先级，确保在英雄渲染后
    priority = 10;

    // 攻击间隔
    interval = config.attack.interval ?? 0.0;

    // 初始化攻击冷却时间
    _attackCooldown = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    updateTarget();
    updateRotation();

    if (_attackCooldown > 0) {
      _attackCooldown -= dt;
    }
  }

  /// 武器根据摇杆角度旋转
  /// [inputAngle] 输入角度
  void rotateByInput(double inputAngle) {
    angle = inputAngle.abs() + config.rotationOffset;
  }

  /// 武器根据世界角度旋转
  /// [worldAngle] 世界角度
  void rotateToWorldAngle(double worldAngle) {
    if (owner.scale.x < 0) {
      worldAngle = pi - worldAngle;
    }
    angle = worldAngle;
  }

  void attack() {
    if (interval > 0) {
      if (_attackCooldown > 0) return;
      _attackCooldown = interval;
    }

    final spec = config.attack;
    // 攻击矩形工厂
    final box = AttackHitboxFactory.create(
      spec: spec,
      owner: owner,
      targetType: targetType,
      target: enemyTarget,
      facingRight: owner.facingRight,
      angle: angle,
      rotationOffset: config.rotationOffset,
    );
    box.debugMode = true;
    game.world.add(box);
  }

  void updateTarget() {
    double minDistance = double.infinity;
    PositionComponent? nearest;
    final targets = game.world.children.whereType<CharacterComponent>();
    for (final t in targets) {
      if (t.runtimeType != targetType) continue;
      final d = owner.position.distanceTo(t.position);
      if (d < minDistance) {
        minDistance = d;
        nearest = t;
      }
    }
    final lockRange = config.attack.bullet?.maxRange ?? owner.cfg.attackRange;
    if (nearest != null && minDistance <= lockRange) {
      enemyTarget = nearest;
    } else {
      enemyTarget = null;
    }
  }

  void updateRotation() {
    if (enemyTarget == null) return;

    final dx = enemyTarget!.absolutePosition.x - absolutePosition.x;
    final dy = enemyTarget!.absolutePosition.y - absolutePosition.y;

    double angleRad = atan2(dy, dx);

    rotateToWorldAngle(angleRad);
  }

  /// 生成随机武器掉落物
  /// [position] 掉落位置
  static PositionComponent generateRandomWeapon(Vector2 position) {
    final random = Random();
    final keys = weaponConfigs.keys.toList();
    if (keys.isEmpty) {
      // 如果没有配置武器，返回一个空组件或抛出异常
      // 这里为了安全返回一个空组件
      return PositionComponent(position: position);
    }

    // 随机选择一个武器ID
    final weaponId = keys[random.nextInt(keys.length)];

    // 创建掉落物组件
    return WeaponDropComponent(weaponId: weaponId, position: position);
  }
}

/// 武器掉落物组件
/// 玩家触碰后可拾取
class WeaponDropComponent extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks, PromptableInteractable {
  final String weaponId;
  final WeaponConfig config;

  // 浮动动画参数
  double _elapsed = 0;
  final double _amplitude = 5.0;
  final double _period = 1.5;
  late final double _baseY;

  WeaponDropComponent({required this.weaponId, required Vector2 position})
    : config = WeaponConfig.byId(weaponId)!,
      super(position: position, anchor: Anchor.center);

  @override
  String get promptText => weaponId;

  @override
  bool get show => this.isRemoved == false;

  @override
  void onInteract(HeroComponent hero) {
    // 检查当前是否有武器
    final oldWeaponId = hero.weapon?.weaponId;

    // 玩家拾取武器
    hero.equipWeapon(weaponId);

    // 如果有旧武器，生成掉落物
    if (oldWeaponId != null) {
      // 在玩家当前位置生成旧武器掉落
      final drop = WeaponDropComponent(
        weaponId: oldWeaponId,
        position: hero.position.clone(),
      );
      game.world.add(drop);
    }

    // 播放拾取音效 (如果 AudioManager 支持)
    // AudioManager.playPickup();

    // 移除当前掉落物
    removeFromParent();
    if (!show) {
      hero.setInteractable(null);
      onExitInteraction(hero);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await game.loadSprite(config.spritePath);
    size = config.size;
    _baseY = position.y;

    // 添加碰撞盒
    add(RectangleHitbox(isSolid: true));

    // 调试模式显示碰撞盒
    debugMode = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 简单的上下浮动效果
    _elapsed += dt;
    final omega = 2 * pi / _period;
    final offset = sin(_elapsed * omega) * _amplitude;
    position.y = _baseY + offset;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is HeroComponent) {
      try {
        if (show) {
          other.setInteractable(this); // 通知 Hero
          onEnterInteraction(other);
        }
      } catch (e) {
        print('Error equipping weapon: $e');
      }
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    if (other is HeroComponent) {
      other.setInteractable(null);
      onExitInteraction(other); // 隐藏提示
    }
  }
}
