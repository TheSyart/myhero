import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../character/character_component.dart';
import '../../character/hero_component.dart';
import '../../character/monster_component.dart';
import '../../my_game.dart';

class GenerateFactory {
  static CharacterComponent create({
    required Vector2 position,
    required String generateId,
    required PositionComponent owner,
    required Type enemyType,
    double followDistance = 150,
  }) {
    CharacterComponent comp;
    // 根据拥有者类型决定生成物类型
    // Hero生成HeroComponent作为随从
    // Monster生成MonsterComponent作为随从
    if (owner is HeroComponent) {
      comp = HeroComponent(
        heroId: generateId, 
        birthPosition: position,
      );
    } else {
      comp = MonsterComponent(position, generateId);
    }

    // 设置召唤物通用属性
    comp.position = position;
    comp.isGenerate = true;
    comp.summonOwner = owner;
    comp.followDistance = followDistance;
    
    return comp;
  }

  static List<CharacterComponent> createCircle({
    required Vector2 center,
    required String generateId,
    required PositionComponent owner,
    required Type enemyType,
    required int count,
    double radius = 150,
    double followDistance = 150,
  }) {
    if (count <= 0) {
      throw ArgumentError.value(count, 'count');
    }
    if (radius <= 0) {
      throw ArgumentError.value(radius, 'radius');
    }
    final step = 2 * math.pi / count;
    final start = -math.pi / 2;
    final list = <CharacterComponent>[];
    for (int i = 0; i < count; i++) {
      final angle = start + i * step;
      final pos = Vector2(
        center.x + radius * math.cos(angle),
        center.y + radius * math.sin(angle),
      );
      list.add(
        create(
          position: pos,
          generateId: generateId,
          owner: owner,
          enemyType: enemyType,
          followDistance: followDistance,
        ),
      );
    }
    return list;
  }

  static Future<CharacterComponent> spawnToWorld({
    required MyGame game,
    required Vector2 position,
    required String generateId,
    required PositionComponent owner,
    required Type enemyType,
    double followDistance = 150,
    bool debug = false,
  }) async {
    final comp = create(
      position: position,
      generateId: generateId,
      owner: owner,
      enemyType: enemyType,
      followDistance: followDistance,
    );
    comp.debugMode = debug;
    await game.world.add(comp);
    return comp;
  }

  static Future<List<CharacterComponent>> spawnCircleToWorld({
    required MyGame game,
    required Vector2 center,
    required String generateId,
    required PositionComponent owner,
    required Type enemyType,
    required int count,
    double radius = 150,
    double followDistance = 150,
    bool debug = false,
  }) async {
    final list = createCircle(
      center: center,
      generateId: generateId,
      owner: owner,
      enemyType: enemyType,
      count: count,
      radius: radius,
      followDistance: followDistance,
    );
    for (final comp in list) {
      comp.debugMode = true;
      await game.world.add(comp);
    }
    return list;
  }
}
