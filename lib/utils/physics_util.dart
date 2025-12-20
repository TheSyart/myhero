import 'package:flame/extensions.dart';
import 'package:myhero/game/character/character_component.dart';
import 'package:myhero/game/component/door_component.dart';

class PhysicsUtil {
  /// 处理角色碰撞纠正
  ///
  /// [component] 需要处理碰撞的角色
  /// [dt] 帧间隔时间
  static void resolveOverlaps(CharacterComponent component, double dt) {
    if (component.isDead) return;

    final rect = component.hitbox.toAbsoluteRect();
    Vector2 totalCorrection = Vector2.zero();

    // 1. Check Blockers (Walls, Water)
    for (final blocker in component.game.blockers) {
      _solveCollision(
        component,
        rect,
        blocker.hitbox.toAbsoluteRect(),
        totalCorrection,
      );
    }

    // 2. Check Doors
    for (final door in component.game.world.children.query<DoorComponent>()) {
      // 只有关着的门或者生成物碰到门时才需要推开
      if ((!door.isOpen && !component.isGenerate) || component.isGenerate) {
        if (door.collidesWith(rect) && !door.isOpen) {
          _solveCollision(
            component,
            rect,
            door.hitbox.toAbsoluteRect(),
            totalCorrection,
          );
        }
      }
    }

    // 3. Check Characters
    // final characters = component.game.world.children.query<CharacterComponent>();
    for (final other
        in component.game.world.children.query<CharacterComponent>()) {
      if (other == component || other.isDead) continue;
      _solveCollision(
        component,
        rect,
        other.hitbox.toAbsoluteRect(),
        totalCorrection,
        isDynamic: true,
        otherCenter: other.absoluteCenter,
      );
    }

    if (!totalCorrection.isZero()) {
      component.position += totalCorrection;
      component.lastCorrection = totalCorrection;
    } else {
      component.lastCorrection = null;
    }
  }

  static void _solveCollision(
    CharacterComponent component,
    Rect myRect,
    Rect otherRect,
    Vector2 totalCorrection, {
    bool isDynamic = false,
    Vector2? otherCenter,
  }) {
    // 考虑已经应用的修正
    final correctedMyRect = myRect.shift(totalCorrection.toOffset());

    if (!correctedMyRect.overlaps(otherRect)) return;

    final intersection = correctedMyRect.intersect(otherRect);
    if (intersection.width <= 0 || intersection.height <= 0) return;

    Vector2 correction = Vector2.zero();

    // Resolve along shallowest axis (SAT)
    if (intersection.width < intersection.height) {
      // X axis
      double dir = 0;
      if (isDynamic && otherCenter != null) {
        dir = (component.absoluteCenter.x - otherCenter.x).sign;
      } else {
        // Static object: push out to nearest edge
        dir = (component.absoluteCenter.x - otherRect.center.dx).sign;
      }

      if (dir == 0) dir = 1; // Default
      correction.x = dir * intersection.width;
    } else {
      // Y axis
      double dir = 0;
      if (isDynamic && otherCenter != null) {
        dir = (component.absoluteCenter.y - otherCenter.y).sign;
      } else {
        dir = (component.absoluteCenter.y - otherRect.center.dy).sign;
      }

      if (dir == 0) dir = 1;
      correction.y = dir * intersection.height;
    }

    // Apply correction
    if (isDynamic) {
      // Push both away? Or just self?
      // Self moves 50%
      totalCorrection.add(correction * 0.5);
    } else {
      // Static wall: full push
      totalCorrection.add(correction);
    }
  }
}
