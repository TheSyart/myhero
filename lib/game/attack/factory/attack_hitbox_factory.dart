import 'package:flame/components.dart';
import '../spec/attack_spec.dart';
import '../component/melee_hitbox.dart';
import '../component/bullet_hitbox.dart';
import '../component/dash_hitbox.dart';
import '../../character/character_component.dart';
import '../../state/attack_type.dart';
import '../component/sector_melee_hitbox.dart';
import 'dart:math';

class AttackHitboxFactory {
  static PositionComponent create({
    required AttackSpec spec,
    required CharacterComponent owner,
    required Type targetType,
    PositionComponent? target,
    required bool facingRight,
    double? angle,
    double rotationOffset = 0,
  }) {
    switch (spec.type) {
      case AttackType.melee:
        return _createMelee(spec, owner, targetType, target, facingRight);

      case AttackType.ranged:
        return _createBullet(spec, owner, targetType, target, facingRight, angle, rotationOffset);

      case AttackType.dash:
        return _createDash(spec, owner, targetType, target, facingRight);

      default:
        throw UnimplementedError();
    }
  }

  static MeleeHitbox _createMelee(
    AttackSpec spec,
    CharacterComponent owner,
    Type targetType,
    PositionComponent? target,
    bool facingRight,
  ) {
    final size = Vector2(
      owner.size.x * spec.sizeRel.x,
      owner.size.y * spec.sizeRel.y,
    );

    final pos = Vector2(
      owner.position.x +
          (facingRight ? 0 : -size.x) +
          spec.centerOffsetRel.x * owner.size.x,
      owner.position.y + spec.centerOffsetRel.y * owner.size.y,
    );

    return MeleeHitbox(
      owner: owner,
      position: pos,
      size: size,
      damage: spec.damage,
      target: target,
      targetType: targetType,
      duration: spec.duration,
    );
  }

  static BulletHitbox _createBullet(
    AttackSpec spec,
    CharacterComponent owner,
    Type targetType,
    PositionComponent? target,
    bool facingRight,
    double? angle,
    double rotationOffset,
  ) {
    Vector2 dir;
    if (angle != null) {
      // Calculate shooting direction from visual angle and offset
      double vx = cos(angle);
      double vy = sin(angle);

      if (!facingRight) {
        vx = -vx;
      }
      dir = Vector2(vx, vy);
    } else {
      dir = Vector2(facingRight ? 1 : -1, 0);
    }

    return BulletHitbox(
      config: spec.bullet!,
      owner: owner,
      targetType: targetType,
      damage: spec.damage,
      position: owner.position.clone(),
      target: target,
      direction: dir,
    );
  }

  static DashHitbox _createDash(
    AttackSpec spec,
    CharacterComponent owner,
    Type targetType,
    PositionComponent? target,
    bool facingRight,
  ) {
    return DashHitbox(
      owner: owner,
      size: owner.size.clone(),
      damage: spec.damage,
      targetType: targetType,
      speed: spec.dashSpeed ?? owner.speed * 2,
      duration: spec.duration,
    );
  }

  // static SectorMeleeHitbox _createSectorMelee(
  //   AttackSpec spec,
  //   CharacterComponent owner,
  //   Type targetType,
  //   bool facingRight,
  // ) {
  //   return SectorMeleeHitbox.obtain(
  //     owner: owner,
  //     damage: spec.damage,
  //     targetType: targetType,
  //     radius: 100, // Should be configurable from spec
  //     arcAngle: pi / 2, // Should be configurable from spec
  //     duration: spec.duration,
  //     facingAngle: facingRight ? 0 : pi,
  //     enableDamageFalloff: true,
  //     enableCriticalHits: true,
  //   );
  // }
}
