import 'package:flame/components.dart';
import 'package:myhero/game/state/attack_type.dart';
import '../../config/bullet_config.dart';
import 'animation_spec.dart';

/// 攻击规范
/// id 攻击id
/// damage 伤害
/// duration 持续时间
/// type 攻击类型
/// sizeRel 攻击大小偏移
/// centerOffsetRel 攻击中心偏移
/// animation 攻击动画
/// bullet 攻击子弹配置
/// dashSpeed 冲刺速度
/// buffs 攻击 buffs
/// icon 攻击图标


class AttackSpec {
  final String id;
  final int damage;
  final double duration;
  final AttackType type;
  final Vector2 sizeRel;
  final Vector2 centerOffsetRel;
  final AnimationSpec? animation;
  final BulletConfig? bullet;
  final double? dashSpeed;
  final List<String>? buffs;
  final String? generateId;
  final String? icon;
  final int? generateCount;
  final double? generateRadius;

  const AttackSpec({
    required this.id,
    required this.damage,
    required this.duration,
    required this.type,
    required this.sizeRel,
    required this.centerOffsetRel,
    this.animation,
    this.bullet,
    this.dashSpeed,
    this.buffs,
    this.generateId,
    this.icon,
    this.generateCount,
    this.generateRadius,
  });
}
