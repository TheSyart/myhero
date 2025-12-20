import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:myhero/game/character/character_component.dart';
import 'package:myhero/game/attack/component/abstract_attack_rect.dart';
import 'dart:ui' as ui;

/// 冲刺攻击组件 (Dash Hitbox)
///
/// 核心功能：
/// 1. **位移与物理运动**：
///    - 直接驱动归属者([owner])进行高速位移。
///    - 集成物理碰撞检测 ([moveWithCollision])，防止穿墙。
///    - 持续同步位置 [position.setFrom(owner.position)]，确保攻击判定跟随角色。
/// 2. **摇杆操作与方向锁定**：
///    - [onNoTargetFound]：优先使用摇杆方向，否则沿当前朝向冲刺。
///    - [_locked] 机制：确保冲刺过程中方向恒定，不受中途操作影响。
/// 3. **持续伤害判定**：
///    - [removeOnHit: false]：冲刺不会因命中敌人而停止 (穿透效果)。
///    - 在持续时间 [duration] 内，对路径上接触的所有有效目标造成伤害。
/// 4. **生命周期管理**：
///    - 基于时间 [_elapsedTime] 控制冲刺时长，结束后自动销毁组件。
///
/// 适用场景：
/// - 战士冲锋、刺客突进等位移技能。
/// - 需要同时兼顾位移和伤害的技能机制。
class DashHitbox extends AbstractAttackRect {
  final double speed;
  Vector2 direction = Vector2.zero();
  bool _locked = false;
  double _elapsedTime = 0;

  DashHitbox({
    required PositionComponent owner,
    required Vector2 size,
    required int damage,
    required Type targetType,
    required this.speed,
    double duration = 0.2,
  }) : super(
          owner: owner,
          position: owner.position.clone(),
          size: size,
          damage: damage,
          targetType: targetType,
          duration: duration,
          removeOnHit: false,
          anchor: Anchor.center,
        ) {
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  void _initializeDirection() {
    if (_locked) return;

    // 1. 优先使用摇杆方向
    if (!game.joystick.delta.isZero()) {
      direction = game.joystick.delta.normalized();
    } 
    // 2. 否则使用人物朝向
    else if (owner is CharacterComponent) {
      direction = Vector2((owner as CharacterComponent).facingRight ? 1 : -1, 0);
    } 
    // 3. 默认右侧
    else {
      direction = Vector2(1, 0);
    }
    
    _locked = true;
  }

  @override
  ui.Rect getAttackRect() => toAbsoluteRect();

  @override
  void onLockTargetFound(PositionComponent target) {
  }

  @override
  void onNoTargetFound() {
    if (_locked) return;
    
    if (!game.joystick.delta.isZero()) {
      direction = game.joystick.delta.normalized();
    } else {
       if (owner is CharacterComponent) {
         direction = Vector2((owner as CharacterComponent).facingRight ? 1 : -1, 0);
       } else {
         direction = Vector2(1, 0); // Default default
       }
    }
    _locked = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_locked) {
      _initializeDirection();
    }
    
    _elapsedTime += dt;
    if (_elapsedTime >= duration) {
      removeFromParent();
      return;
    }

    if (_locked && !direction.isZero()) {
      final delta = direction * speed * dt;
      if (owner is CharacterComponent) {
         final char = owner as CharacterComponent;
         char.moveWithCollision(delta);
         
         if (delta.x > 0) char.faceRight();
         if (delta.x < 0) char.faceLeft();
      } else {
         owner.position += delta;
      }
    }
    
    position.setFrom(owner.position);
  }

}
