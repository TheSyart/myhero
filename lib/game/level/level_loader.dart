import '../component/treasure_component.dart';
import '../component/water_component.dart';
import '../component/key_component.dart';
import '../component/door_component.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Text;
import 'package:flame/experimental.dart';
import '../component/wall_component.dart';
import '../component/spawn_point_component.dart';
import '../../utils/common.dart';
import '../component/thorn_component.dart';
import '../component/portal_component.dart';
import '../my_game.dart';
import 'map_combiner.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// 关卡加载器
///
/// 负责加载和管理游戏关卡，包括：
/// 1. 加载单张 Tiled 地图文件
/// 2. 加载随机生成的地牢（Random Dungeon）
/// 3. 解析地图中的各种对象层（墙壁、门、钥匙、宝箱、怪物生成点等）
/// 4. 管理地图内容的生命周期（加载、清除）
class LevelLoader {
  final MyGame game;
  Vector2? heroBirthPoint;
  CombinedMap? currentCombinedMap;
  final ValueNotifier<CombinedMap?> mapNotifier = ValueNotifier<CombinedMap?>(
    null,
  );

  LevelLoader(this.game);

  static const double mapScale = MyGame.mapScale;
  static const double tileSize = MyGame.tileSize;

  /// 加载指定名称的地图
  ///
  /// [mapName] 地图文件名。如果为 'random_dungeon'，则调用 [loadRandomDungeon] 生成随机地牢。
  Future<void> load(String mapName) async {
    if (mapName == 'random_dungeon') {
      await loadRandomDungeon();
      return;
    }

    _clearCurrentLevel();
    heroBirthPoint = null;
    final world = game.world;
    final camera = game.camera;

    // ---------- 加载地图 ----------
    final realTileSize = mapScale * tileSize;
    var effectiveMap = mapName;

    final tiled = await TiledComponent.load(
      effectiveMap,
      Vector2.all(realTileSize),
    );
    tiled.priority = -100;
    world.add(tiled);

    await _loadMapContent(tiled, Vector2.zero());

    // ---------- camera ----------
    camera.setBounds(Rectangle.fromLTRB(0, 0, tiled.size.x, tiled.size.y));

    // 更新小地图数据（单图情况）
    final seg = MapSegment(tiled, Vector2.zero(), mapName);
    currentCombinedMap = CombinedMap([seg], tiled.size, Vector2.zero());
    mapNotifier.value = currentCombinedMap;
  }

  /// 加载随机地牢
  ///
  /// 使用 [MapCombiner] 生成随机地图结构，并加载所有相关的地图片段和内容。
  /// 同时设置相机边界和小地图数据。
  Future<void> loadRandomDungeon() async {
    _clearCurrentLevel();
    heroBirthPoint = null;
    final world = game.world;
    final camera = game.camera;

    final combiner = MapCombiner(tileSize: tileSize, scale: mapScale);
    final combinedMap = await combiner.combine();

    if (combinedMap.segments.isEmpty) {
      print('Failed to generate dungeon, loading default home.tmx');
      await load('home.tmx');
      return;
    }

    for (final segment in combinedMap.segments) {
      world.add(segment.tiled);
      await _loadMapContent(
        segment.tiled,
        segment.offset,
        angle: segment.angle,
        openings: segment.openings,
      );
    }

    // 设置相机边界为完整的组合地图大小
    camera.setBounds(
      Rectangle.fromLTWH(
        combinedMap.topLeft.x,
        combinedMap.topLeft.y,
        combinedMap.size.x,
        combinedMap.size.y,
      ),
    );

    // 如果没有出生点，默认设置为第一个地图的中心或类似位置
    if (heroBirthPoint == null && combinedMap.segments.isNotEmpty) {
      final firstSeg = combinedMap.segments.first;
      heroBirthPoint =
          firstSeg.offset + Vector2(200, 200); // Center of 40x40 room roughly
    }

    // 通知小地图数据变更（随机地牢）
    currentCombinedMap = combinedMap;
    mapNotifier.value = currentCombinedMap;
  }

  /// 加载地图内容
  ///
  /// 解析 Tiled 地图中的各个图层和对象，并创建对应的游戏组件。
  /// [tiled] Tiled 地图组件
  /// [offset] 地图在世界坐标系中的偏移量
  /// [angle] 地图旋转角度（用于走廊等）
  Future<void> _loadMapContent(
    TiledComponent tiled,
    Vector2 offset, {
    double angle = 0,
    Set<String>? openings,
  }) async {
    // ---------- 1. thorn ----------
    _loadThorn(tiled, offset, angle);

    // ---------- 2. key ----------
    _loadKey(tiled, offset, angle);

    // ---------- 3. treasure ----------
    _loadTreasure(tiled, offset, angle);

    // ---------- 4. door ----------
    _loadDoor(tiled, offset, angle, openings);

    // ---------- 5. water ----------
    _loadWater(tiled, offset, angle);

    // ---------- 6. wall ----------
    _loadWall(tiled, offset, angle);

    // ---------- 7. collisions ----------
    _loadCollisions(tiled, offset, angle);

    // ---------- 8. spawn / portal ----------
    _loadSpawnPoints(tiled, offset, angle);
  }

  // ---------------- 私有方法 ----------------

  (Vector2, Vector2) _getTransformedRect(
    TiledObject obj,
    Vector2 offset,
    double angle,
  ) {
    final localPos = _pos(obj);
    final localSize = _size(obj);
    return _transformRect(localPos, localSize, offset, angle);
  }

  (Vector2, Vector2) _transformRect(
    Vector2 localPos,
    Vector2 localSize,
    Vector2 offset,
    double angle,
  ) {
    if (angle == 0) {
      return (localPos + offset, localSize);
    }

    // 计算旋转后的矩形的4个角点
    final p1 = localPos;
    final p2 = localPos + Vector2(localSize.x, 0);
    final p3 = localPos + localSize;
    final p4 = localPos + Vector2(0, localSize.y);

    // 旋转它们
    final cosA = cos(angle);
    final sinA = sin(angle);

    Vector2 rotate(Vector2 v) {
      return Vector2(v.x * cosA - v.y * sinA, v.x * sinA + v.y * cosA);
    }

    final rp1 = rotate(p1);
    final rp2 = rotate(p2);
    final rp3 = rotate(p3);
    final rp4 = rotate(p4);

    // 找到旋转后的矩形的边界框
    final minX = min(min(rp1.x, rp2.x), min(rp3.x, rp4.x));
    final maxX = max(max(rp1.x, rp2.x), max(rp3.x, rp4.x));
    final minY = min(min(rp1.y, rp2.y), min(rp3.y, rp4.y));
    final maxY = max(max(rp1.y, rp2.y), max(rp3.y, rp4.y));

    final newPos = Vector2(minX, minY) + offset;
    final newSize = Vector2(maxX - minX, maxY - minY);

    return (newPos, newSize);
  }

  void _loadThorn(TiledComponent tiled, Vector2 offset, double angle) {
    final layer = tiled.tileMap.getLayer<ObjectGroup>('thorn');
    if (layer == null) return;

    for (final obj in layer.objects) {
      if (obj.properties['type']?.value != 'thorn') continue;

      final (pos, size) = _getTransformedRect(obj, offset, angle);

      final c = ThornComponent(
        status: obj.properties['status']!.value as String,
        position: pos,
        size: size,
      )..debugMode = true;

      game.world.add(c);
    }
  }

  void _loadKey(TiledComponent tiled, Vector2 offset, double angle) {
    final layer = tiled.tileMap.getLayer<ObjectGroup>('key');
    if (layer == null) return;

    for (final obj in layer.objects) {
      if (obj.properties['type']?.value != 'key') continue;

      final (pos, size) = _getTransformedRect(obj, offset, angle);

      final c = KeyComponent(
        keyId: obj.properties['keyId']!.value as String,
        position: pos,
        size: size,
      )..debugMode = true;

      game.world.add(c);
    }
  }

  void _loadTreasure(TiledComponent tiled, Vector2 offset, double angle) {
    final layer = tiled.tileMap.getLayer<ObjectGroup>('treasure');
    if (layer == null) return;

    for (final obj in layer.objects) {
      if (obj.properties['type']?.value != 'treasure') continue;

      final (pos, size) = _getTransformedRect(obj, offset, angle);

      final c = TreasureComponent(
        status: obj.properties['status']!.value as String,
        position: pos,
        size: size,
      )..debugMode = true;

      game.world.add(c);
    }
  }

  void _loadDoor(
    TiledComponent tiled,
    Vector2 offset,
    double angle,
    Set<String>? openings,
  ) {
    final layer = tiled.tileMap.getLayer<ObjectGroup>('door');
    if (layer == null) return;

    for (final obj in layer.objects) {
      if (obj.properties['type']?.value != 'door') continue;

      final (pos, size) = _getTransformedRect(obj, offset, angle);

      bool allowDoor = true;
      String side = 'center';
      if (openings != null) {
        final left = offset.x;
        final top = offset.y;
        final right = offset.x + tiled.size.x;
        final bottom = offset.y + tiled.size.y;
        const double eps = 1.0;
        if (pos.x <= left + eps) {
          side = 'left';
        } else if (pos.x + size.x >= right - eps) {
          side = 'right';
        } else if (pos.y <= top + eps) {
          side = 'up';
        } else if (pos.y + size.y >= bottom - eps) {
          side = 'down';
        }
        allowDoor = openings.contains(side);
      }

      if (allowDoor) {
        final c = DoorComponent(
          keyId: obj.properties['keyId']!.value as String,
          isOpen: obj.properties['status']?.value == 'open',
          position: pos,
          size: size,
        );
        game.world.add(c);
      } else {
        final wall = WallComponent(
          position: pos,
          size: size,
          useSprite: true,
          vertical: side == 'left' || side == 'right',
        );
        game.blockers.add(wall);
        game.world.add(wall);
      }
    }
  }

  Future<void> _loadWater(
    TiledComponent tiled,
    Vector2 offset,
    double angle,
  ) async {
    final layer = tiled.tileMap.getLayer<TileLayer>('water');
    if (layer == null || layer.data == null) return;

    await addMergedTileLayerV2(
      tileData: layer.data!,
      width: layer.width,
      height: layer.height,
      tileSize: tileSize,
      scale: mapScale,
      parent: game.world,
      createComponent: (pos, size) async {
        final (newPos, newSize) = _transformRect(pos, size, offset, angle);
        final water = WaterComponent(position: newPos, size: newSize)
          ..debugMode = true;
        game.blockers.add(water);
        return water;
      },
    );
  }

  Future<void> _loadWall(
    TiledComponent tiled,
    Vector2 offset,
    double angle,
  ) async {
    final layer = tiled.tileMap.getLayer<TileLayer>('wall');
    if (layer == null || layer.data == null) return;

    await addMergedTileLayerV2(
      tileData: layer.data!,
      width: layer.width,
      height: layer.height,
      tileSize: tileSize,
      scale: mapScale,
      parent: game.world,
      createComponent: (pos, size) async {
        final (newPos, newSize) = _transformRect(pos, size, offset, angle);
        final wall = WallComponent(position: newPos, size: newSize)
          ..debugMode = true;
        game.blockers.add(wall);
        return wall;
      },
    );
  }

  void _loadCollisions(TiledComponent tiled, Vector2 offset, double angle) {
    final layer = tiled.tileMap.getLayer<ObjectGroup>('Collisions');
    if (layer == null) return;

    for (final obj in layer.objects) {
      final (pos, size) = _getTransformedRect(obj, offset, angle);
      final wall = WallComponent(position: pos, size: size)..debugMode = true;

      game.blockers.add(wall);
      game.world.add(wall);
    }
  }

  void _loadSpawnPoints(TiledComponent tiled, Vector2 offset, double angle) {
    final layer = tiled.tileMap.getLayer<ObjectGroup>('spawn_points');
    if (layer == null) return;

    for (final obj in layer.objects) {
      final type = obj.properties['type']?.value as String?;

      if (type == 'monster_spawn') {
        final (pos, size) = _getTransformedRect(obj, offset, angle);
        final spawn = SpawnPointComponent(
          position: pos,
          size: size,
          monsterId:
              obj.properties['monsterId']?.value as String? ?? 'elite_orc',
          maxCount: obj.properties['maxCount']?.value as int? ?? 3,
          perCount: obj.properties['perCount']?.value as int? ?? 1,
          productSpeed: Duration(
            seconds: obj.properties['productSpeed']?.value as int? ?? 3,
          ),
        )..debugMode = true;

        game.world.add(spawn);
        spawn.start();
      }

      if (type == 'portal') {
        final (pos, size) = _getTransformedRect(obj, offset, angle);
        final mapId = obj.properties['mapId']?.value as String? ?? 'home.tmx';
        final portal = PortalComponent(position: pos, size: size, mapId: mapId)
          ..debugMode = true;

        game.world.add(portal);
      }

      if (type == 'birthPoint') {
        final (pos, _) = _getTransformedRect(obj, offset, angle);
        heroBirthPoint = pos;
      }
    }
  }

  // ---------- 工具 ----------

  Vector2 _pos(TiledObject o) => Vector2(mapScale * o.x, mapScale * o.y);

  Vector2 _size(TiledObject o) =>
      Vector2(mapScale * o.width, mapScale * o.height);

  void _clearCurrentLevel() {
    game.blockers.clear();
    final children = List<Component>.from(game.world.children);
    for (final c in children) {
      if (c is TiledComponent ||
          c is WaterComponent ||
          c is WallComponent ||
          c is ThornComponent ||
          c is KeyComponent ||
          c is TreasureComponent ||
          c is DoorComponent ||
          c is SpawnPointComponent ||
          c is PortalComponent) {
        c.removeFromParent();
      }
    }
  }
}
