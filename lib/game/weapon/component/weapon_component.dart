import 'package:flame/components.dart';
import 'package:myhero/game/config/weapon_config.dart';
import 'package:myhero/game/character/character_component.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import '../../attack/factory/attack_hitbox_factory.dart';
import 'dart:math';

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
}
