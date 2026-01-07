import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import 'package:myhero/game/character/character_component.dart';
import 'dart:ui' as ui;

/// 攻击判定组件基类 (Abstract Attack Hitbox)
///
/// 核心功能：
/// 1. **基础属性管理**：统一管理攻击的位置、范围、伤害、归属者(owner)、目标类型及存活周期。
/// 2. **命中检测机制**：
///    - 集成 [CollisionCallbacks] 支持物理引擎碰撞。
///    - 提供 [getAttackRect] 接口支持自定义几何区域判定（如扇形、多边形）。
///    - 内置目标去重机制 [_hitTargets]，防止单次攻击多段伤害异常。
/// 3. **智能索敌系统**：
///    - [autoLockNearestTarget]：自动筛选最近的有效目标（排除自身、过滤距离）。
///    - [angleToTarget]：计算精准的攻击朝向。
/// 4. **生命周期控制**：
///    - 支持命中即销毁 ([removeOnHit]) 或穿透模式。
///    - 基于时间的自动销毁机制。
///
/// 扩展说明：
/// - 所有攻击判定体（近战、子弹、AOE等）均应继承此类。
/// - 子类需实现 [getAttackRect] 以定义具体的攻击区域形状。
abstract class AbstractAttackRect extends PositionComponent
    with CollisionCallbacks, HasGameReference<MyGame> {
  int damage;
  PositionComponent owner;
  PositionComponent? target;
  Type targetType;
  double duration;
  bool removeOnHit;
  double maxLockDistance;
  final Set<PositionComponent> _hitTargets = {};

  AbstractAttackRect({
    required this.owner,
    required Vector2 position,
    required Vector2 size,
    required this.damage,
    required this.targetType,
    PositionComponent? target,
    this.duration = 0.2,
    this.removeOnHit = true,
    this.maxLockDistance = 500.0,
    Anchor anchor = Anchor.center,
    int priority = 100,
  }) : super(
         position: position,
         size: size,
         anchor: anchor,
         priority: priority,
       ) {
    this.target = target; // ✅ 关键
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    autoLockNearestTarget();
  }

  /// 自动索敌逻辑
  void autoLockNearestTarget() {
    if (target != null) {
      onLockTargetFound();
      return;
    }

    PositionComponent? nearest;
    double minDistance = double.infinity;

    final Iterable<PositionComponent> candidates;
    if (targetType == HeroComponent) {
      candidates = game.world.children.query<HeroComponent>();
    } else if (targetType == MonsterComponent) {
      candidates = game.world.children.query<MonsterComponent>();
    } else {
      candidates = [];
    }

    for (final candidate in candidates) {
      if (candidate == owner) continue;

      if (candidate is CharacterComponent && candidate.isDead) continue;

      final double distance = position.distanceTo(candidate.position);
      if (distance < minDistance && distance <= maxLockDistance) {
        minDistance = distance;
        nearest = candidate;
      }
    }

    if (nearest != null) {
      target = nearest;
      onLockTargetFound();
    } else {
      onNoTargetFound();
    }
  }

  /// 重置基础属性（用于对象池复用）
  void resetBase({
    required PositionComponent owner,
    required Vector2 position,
    required Vector2 size,
    required int damage,
    required Type targetType,
    PositionComponent? target,
    double duration = 0.2,
    bool removeOnHit = true,
    double maxLockDistance = 500.0,
  }) {
    this.owner = owner;
    this.position.setFrom(position);
    this.size.setFrom(size);
    this.damage = damage;
    this.targetType = targetType;
    this.target = target;
    this.duration = duration;
    this.removeOnHit = removeOnHit;
    this.maxLockDistance = maxLockDistance;
    _hitTargets.clear();
  }

  /// 返回该组件用于判定的几何区域
  ui.Rect getAttackRect();

  /// 子类实现：当找到最近目标时的处理
  void onLockTargetFound();

  /// 子类实现：当未找到目标时的处理（如跟随摇杆方向）
  void onNoTargetFound();

  /// 计算到目标的朝向角度（弧度）
  double angleToTarget(PositionComponent target, Vector2 from) {
    final Vector2 origin = from;
    final Vector2 targetPos = target.position.clone();
    return math.atan2(targetPos.y - origin.y, targetPos.x - origin.x);
  }

  void _applyHit(PositionComponent other) {
    if (other == owner) return;
    if (_hitTargets.contains(other)) return;
    if (targetType == HeroComponent && other is HeroComponent) {
      other.loseHp(damage);
      _hitTargets.add(other);
      if (removeOnHit) {
        removeFromParent();
      }
    } else if (targetType == MonsterComponent && other is MonsterComponent) {
      other.loseHp(damage);
      _hitTargets.add(other);
      if (removeOnHit) {
        removeFromParent();
      }
    }
  }

  bool _rectContains(ui.Rect a, ui.Rect b) {
    return a.left <= b.left &&
        a.top <= b.top &&
        a.right >= b.right &&
        a.bottom >= b.bottom;
  }

  bool _rectsTouchOrOverlap(ui.Rect a, ui.Rect b) {
    return !(a.right < b.left ||
        a.left > b.right ||
        a.bottom < b.top ||
        a.top > b.bottom);
  }

  bool _shouldDamage(ui.Rect attackRect, ui.Rect targetRect) {
    return _rectContains(attackRect, targetRect) ||
        _rectContains(targetRect, attackRect) ||
        _rectsTouchOrOverlap(attackRect, targetRect);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final ui.Rect attackRect = getAttackRect();
    if (targetType == HeroComponent) {
      for (final h in game.world.children.query<HeroComponent>()) {
        if (h == owner) continue;
        final ui.Rect targetRect = h.hitbox.toAbsoluteRect();
        if (_shouldDamage(attackRect, targetRect)) {
          _applyHit(h);
        }
      }
    } else if (targetType == MonsterComponent) {
      for (final m in game.world.children.query<MonsterComponent>()) {
        if (m == owner) continue;
        final ui.Rect targetRect = m.hitbox.toAbsoluteRect();
        if (_shouldDamage(attackRect, targetRect)) {
          _applyHit(m);
        }
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    _applyHit(other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    _applyHit(other);
  }
}
