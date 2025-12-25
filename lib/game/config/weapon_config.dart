import 'package:flame/components.dart';
import 'dart:math' as math;
import '../attack/spec/attack_spec.dart';
import '../state/attack_type.dart';
import 'bullet_config.dart';

enum WeaponType { melee, ranged }

/// 武器配置
/// type 武器类型
/// spritePath 精灵图路径
/// size 武器大小
/// anchor 锚点 (用于调整旋转中心/手持位置)
/// rotationOffset 旋转偏移量 (弧度)
/// damage 基础伤害
/// attackInterval 攻击间隔
/// attackRange 攻击范围
class WeaponConfig {
  final WeaponType type;
  final String spritePath;
  final Vector2 size;
  final Anchor anchor;
  final double rotationOffset;
  final AttackSpec attack;

  const WeaponConfig({
    required this.type,
    required this.spritePath,
    required this.size,
    this.anchor = Anchor.centerLeft,
    this.rotationOffset = 0,
    required this.attack,
  });

  static WeaponConfig? byId(String id) => weaponConfigs[id];
}

final Map<String, WeaponConfig> weaponConfigs = {
  'AK47': WeaponConfig(
    type: WeaponType.ranged,
    spritePath: 'weapon/AK47/AK47.png',
    size: Vector2(96, 48),
    anchor: Anchor.centerLeft, // Handle at center
    rotationOffset: -math.pi / 2, // Rotate 90 degrees
    attack: AttackSpec(
      id: 'AK47_attack',
      icon: 'weapon/AK47/AK47.png',
      damage: 10,
      duration: 2.0,
      interval: 0.5,
      type: AttackType.ranged,
      sizeRel: Vector2(1, 1),
      centerOffsetRel: Vector2(0, 0),
      bullet: BulletConfig.byId('bullet'),
    ),
  ),
  'Bazooka-M20': WeaponConfig(
    type: WeaponType.ranged,
    spritePath: 'weapon/Bazooka-M20/Bazooka-M20.png',
    size: Vector2(192, 32),
    anchor: Anchor.centerLeft, // Handle at center
    rotationOffset: -math.pi / 2, // Rotate 90 degrees
    attack: AttackSpec(
      id: 'Bazooka-M20_attack',
      icon: 'weapon/Bazooka-M20/Bazooka-M20.png',
      damage: 8,
      duration: 2.0,
      interval: 0.8,
      type: AttackType.ranged,
      sizeRel: Vector2(1, 1),
      centerOffsetRel: Vector2(0, 0),
      bullet: BulletConfig.byId('m20_rocket'),
    ),
  ),
  'Glock-P80': WeaponConfig(
    type: WeaponType.ranged,
    spritePath: 'weapon/Glock-P80/Glock-P80.png',
    size: Vector2(64, 48),
    anchor: Anchor.centerLeft, // Handle at center
    rotationOffset: -math.pi / 2, // Rotate 90 degrees
    attack: AttackSpec(
      id: 'Glock-P80_attack',
      damage: 10,
      duration: 2.0,
      interval: 0.5,
      type: AttackType.ranged,
      sizeRel: Vector2(1, 1),
      centerOffsetRel: Vector2(0, 0),
      bullet: BulletConfig.byId('bullet'),
    ),
  ),
  'Revolver-Colt45': WeaponConfig(
    type: WeaponType.ranged,
    spritePath: 'weapon/Revolver-Colt45/Revolver-Colt45.png',
    size: Vector2(64, 32),
    anchor: Anchor.centerLeft, // Handle at center
    rotationOffset: -math.pi / 2, // Rotate 90 degrees
    attack: AttackSpec(
      id: 'Revolver-Colt45_attack',
      icon: 'weapon/Revolver-Colt45/Revolver-Colt45.png',
      damage: 8,
      duration: 2.0,
      interval: 0.8,
      type: AttackType.ranged,
      sizeRel: Vector2(1, 1),
      centerOffsetRel: Vector2(0, 0),
      bullet: BulletConfig.byId('bullet'),
    ),
  ),
  'Submachine-MP5A3': WeaponConfig(
    type: WeaponType.ranged,
    spritePath: 'weapon/Submachine-MP5A3/Submachine-MP5A3.png',
    size: Vector2(80, 48),
    anchor: Anchor.centerLeft, // Handle at center
    rotationOffset: -math.pi / 2, // Rotate 90 degrees
    attack: AttackSpec(
      id: 'Submachine-MP5A3_attack',
      icon: 'weapon/Submachine-MP5A3/Submachine-MP5A3.png',
      damage: 10,
      duration: 2.0,
      interval: 0.5,
      type: AttackType.ranged,
      sizeRel: Vector2(1, 1),
      centerOffsetRel: Vector2(0, 0),
      bullet: BulletConfig.byId('bullet'),
    ),
  ),
};
