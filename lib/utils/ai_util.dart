import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:myhero/game/character/character_component.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import 'package:myhero/game/state/character_state.dart';

class AiUtil {
  /// 更新召唤物AI行为
  /// 包含：寻找敌人、攻击、跟随主人、待机
  static void updateSummonAI(CharacterComponent component, double dt) {
    try {
      if (component.isActionLocked) return;

      // 1. 确定敌对类型
      // 如果自己是HeroComponent，则敌人是MonsterComponent；反之亦然
      final bool isHero = component is HeroComponent;

      PositionComponent? target;
      if (isHero) {
        // 寻找最近的Monster
        for (final m in component.game.world.children.query<MonsterComponent>()) {
          if (m == component.summonOwner) continue; // 排除主人（如果是）
          if (target == null ||
              (m.position - component.position).length <
                  (target!.position - component.position).length) {
            target = m;
          }
        }
      } else {
        // 寻找最近的Hero
        for (final h in component.game.world.children.query<HeroComponent>()) {
          if (h == component.summonOwner) continue;
          if (target == null ||
              (h.position - component.position).length <
                  (target!.position - component.position).length) {
            target = h;
          }
        }
      }

      final double detectRadius = component.cfg.detectRadius;
      final double attackRange = component.cfg.attackRange;

      if (target != null) {
        final toEnemy = target.position - component.position;
        final enemyDistance = toEnemy.length;
        if (enemyDistance <= detectRadius) {
          // 进入攻击范围
          if (enemyDistance <= attackRange) {
            component.attack(0, isHero ? MonsterComponent : HeroComponent);
            return;
          }

          // 追击敌人
          component.setState(CharacterState.run);
          final direction = toEnemy.normalized();
          final delta = direction * component.speed * dt;
          component.moveWithCollision(delta);
          direction.x >= 0 ? component.faceRight() : component.faceLeft();
          return;
        }
      }

      // 跟随拥有者
      if (component.summonOwner != null && component.summonOwner!.parent != null) {
        final toOwner = component.summonOwner!.position - component.position;
        final ownerDistance = toOwner.length;
        final double deadZone = 8.0;

        if (ownerDistance > component.followDistance + deadZone) {
          component.setState(CharacterState.run);
          final direction = toOwner.normalized();
          final delta = direction * component.speed * dt;
          component.moveWithCollision(delta);
          direction.x >= 0 ? component.faceRight() : component.faceLeft();
          return;
        }
      }

      // 待机
      component.setState(CharacterState.idle);
    } catch (e, stack) {
      print('Error in AiUtil.updateSummonAI: $e\n$stack');
    }
  }

  /// 更新怪物AI行为
  /// 包含：寻找敌人、攻击、巡逻
  static void updateMonsterAI(MonsterComponent monster, double dt) {
    if (monster.isActionLocked) return;

    // 寻找最近的HeroComponent作为目标
    PositionComponent? target;
    double distance = double.infinity;

    for (final h in monster.game.world.children.query<HeroComponent>()) {
      final d = (h.position - monster.position).length;
      if (d < distance) {
        distance = d;
        target = h;
      }
    }

    // 超出感知范围或未找到目标
    if (target == null || distance > monster.detectRadius) {
      if (monster.wanderDuration > 0) {
        monster.setState(CharacterState.run);
        final delta = monster.wanderDir * monster.speed * dt;
        monster.moveWithCollision(delta);
        monster.wanderDuration -= dt;
        monster.wanderDir.x >= 0 ? monster.faceRight() : monster.faceLeft();
      } else {
        monster.wanderCooldown -= dt;
        if (monster.wanderCooldown <= 0) {
          final angle = monster.rng.nextDouble() * 2 * math.pi;
          monster.wanderDir = Vector2(math.cos(angle), math.sin(angle));
          monster.wanderDuration = 0.6 + monster.rng.nextDouble() * 1.2;
          monster.wanderCooldown = 1.0 + monster.rng.nextDouble() * 2.0;
        } else {
          monster.setState(CharacterState.idle);
        }
      }
      return;
    }

    // 进入攻击范围
    if (distance <= monster.attackRange) {
      monster.attack(0, HeroComponent);
      return;
    }

    // 追逐
    monster.setState(CharacterState.run);

    final toTarget = target!.position - monster.position;
    final direction = toTarget.normalized();
    final delta = direction * monster.speed * dt;

    monster.moveWithCollision(delta);

    direction.x >= 0 ? monster.faceRight() : monster.faceLeft();
  }
}
