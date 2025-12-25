import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:myhero/game/attack/component/abstract_attack_rect.dart';
import 'dart:ui' as ui;

/// 普通近战攻击组件 (Melee Hitbox)
///
/// 核心功能：
/// 1. **矩形判定区域**：
///    - 使用 [RectangleHitbox] 作为物理碰撞检测区域。
///    - 默认配置为被动碰撞类型 ([CollisionType.passive])。
/// 2. **自动索敌转向**：
///    - 重写 [onLockTargetFound] 实现攻击方向自动对准最近目标。
///    - 通过调整组件旋转角度 ([angle]) 来指向目标中心。
/// 3. **生命周期管理**：
///    - 使用内部计时器 [_timer] 精确控制攻击持续时间。
///    - 超时自动销毁，模拟瞬间挥砍效果。
/// 4. **位置修正**：
///    - 构造时自动将左上角坐标转换为中心坐标，确保旋转围绕中心点进行。
///
/// 适用场景：
/// - 刀剑挥砍、拳击等短距离瞬间攻击。
/// - 需要自动吸附或转向目标的近身攻击。
class MeleeHitbox extends AbstractAttackRect {
  late final RectangleHitbox hitbox;
  double _timer = 0;

  MeleeHitbox({
    required PositionComponent owner,
    required Vector2 position,
    required Vector2 size,
    required int damage,
    required Type targetType,
    double duration = 0.2,
    bool removeOnHit = true,
    PositionComponent? target,
  }) : super(
         owner: owner,
         // 将传入的左上角坐标转换为中心坐标以便旋转
         position: position + size / 2,
         size: size,
         damage: damage,
         target: target,
         targetType: targetType,
         duration: duration,
         removeOnHit: removeOnHit,
         anchor: Anchor.center,
         priority: 100,
       ) {
    hitbox = RectangleHitbox()..collisionType = CollisionType.passive;
    add(hitbox);
  }

  @override
  ui.Rect getAttackRect() => hitbox.toAbsoluteRect();

  @override
  void onLockTargetFound() {
    final ui.Rect rect = getAttackRect();
    final Vector2 center = Vector2(
      rect.left + rect.width / 2,
      rect.top + rect.height / 2,
    );
    if (target != null) {
      angle = angleToTarget(target!, center);
    }
  }

  @override
  void onNoTargetFound() {}

  @override
  void update(double dt) {
    super.update(dt);
    // 近战：如果有目标则朝向目标，否则保持当前角度
    if (target != null) {
      onLockTargetFound();
    }

    _timer += dt;
    if (_timer >= duration) {
      removeFromParent();
    }
  }
}
