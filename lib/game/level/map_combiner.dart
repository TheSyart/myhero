import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../my_game.dart';

// ------------------ 常量配置 ------------------
const int GRID_ROWS = 3;
const int GRID_COLS = 3;
const int MIN_ROOMS = 5;
const int MAX_ROOMS = 9;
const int DEFAULT_ROOM_SIZE_TILES = 40;
const int DEFAULT_CORRIDOR_LENGTH_TILES = 20;
const int DEFAULT_CORRIDOR_WIDTH_TILES = 10;

/// 地图片段，表示拼接后的地图中的一个独立部分（房间或走廊）
class MapSegment {
  final TiledComponent tiled;
  final Vector2 offset;
  final String mapName;
  final double angle;
  final Set<String> openings;

  MapSegment(
    this.tiled,
    this.offset,
    this.mapName, {
    this.angle = 0,
    Set<String>? openings,
  }) : openings = openings ?? {};
}

/// 拼接完成的地图数据结构
class CombinedMap {
  /// 包含的所有地图片段
  final List<MapSegment> segments;

  /// 整个地图的包围盒大小
  final Vector2 size;

  /// 整个地图左上角的世界坐标
  final Vector2 topLeft;

  CombinedMap(this.segments, this.size, this.topLeft);
}

/// 地图拼接器
///
/// 负责将多个 Tiled 地图文件拼接成一个完整的随机地牢。
/// 采用 3x3 网格布局，通过随机游走算法生成房间连接关系。
class MapCombiner {
  final double tileSize;
  final double scale;

  // 房间和走廊的尺寸（单位：瓦片数）
  final int roomSize;
  final int corridorLength;
  final int corridorWidth;

  // 缓存已加载的地图，优化性能
  final Map<String, RenderableTiledMap> _mapCache = {};

  MapCombiner({
    this.tileSize = MyGame.tileSize,
    this.scale = MyGame.mapScale,
    this.roomSize = DEFAULT_ROOM_SIZE_TILES,
    this.corridorLength = DEFAULT_CORRIDOR_LENGTH_TILES,
    this.corridorWidth = DEFAULT_CORRIDOR_WIDTH_TILES,
  }) {
    if (roomSize <= 0 || corridorLength <= 0 || corridorWidth <= 0) {
      throw ArgumentError('Dimensions must be positive');
    }
    if (corridorWidth > roomSize) {
      throw ArgumentError('Corridor width cannot be larger than room size');
    }
  }

  /// 加载 Tiled 地图文件（带缓存）
  Future<RenderableTiledMap> _loadMap(String mapName) async {
    if (!_mapCache.containsKey(mapName)) {
      _mapCache[mapName] = await RenderableTiledMap.fromFile(
        mapName,
        Vector2.all(tileSize * scale),
      );
    }
    return _mapCache[mapName]!;
  }

  /// 扫描 assets/tiles/ 目录下符合命名规范的地图文件
  Future<List<String>> _scanMapFiles() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestContent);

      return manifest.keys
          .where(
            (String key) =>
                key.contains('assets/tiles/') &&
                key.split('/').last.startsWith('room_') &&
                key.endsWith('.tmx'),
          )
          .toList();
    } catch (e) {
      print('Error scanning maps: $e');
      return [];
    }
  }

  /// 执行地图拼接的核心方法
  Future<CombinedMap> combine({int? seed}) async {
    final mapFiles = await _scanMapFiles();
    if (mapFiles.isEmpty) {
      print('No room maps found');
      return CombinedMap([], Vector2.zero(), Vector2.zero());
    }

    // 1. 生成布局结构（网格位置和连接关系）
    final layout = generateLayout(mapFiles, seed: seed);
    final grid = layout.grid;
    final connections = layout.connections;

    // 2. 生成具体的地图片段
    List<MapSegment> segments = [];

    // 计算地图边界
    // 强制使用 3x3 的完整尺寸来计算边界，确保小地图显示位置固定
    final double step = (roomSize + corridorLength) * tileSize * scale;
    final double fullMapWidth = 2 * step + roomSize * tileSize * scale;
    final double fullMapHeight = 2 * step + roomSize * tileSize * scale;

    // 设定最小/最大边界，覆盖整个 3x3 区域
    // 假设左上角为 (0,0)，则范围是 [0, fullMapWidth] x [0, fullMapHeight]
    // 实际坐标由 getRoomPos 决定

    double minX = 0;
    double maxX = fullMapWidth;
    double minY = 0;
    double maxY = fullMapHeight;

    // 辅助函数：计算房间在世界坐标系中的像素位置
    // p: 网格坐标 (0,0) 到 (2,2)
    Vector2 getRoomPos(math.Point<int> p) {
      return Vector2(p.x * step, p.y * step);
    }
    
    // 记录每个房间的开口方向
    final Map<math.Point<int>, Set<String>> roomOpenings = {};
    for (final p in grid.keys) {
      roomOpenings[p] = <String>{};
    }
    for (final conn in connections) {
      final p1 = conn.from;
      final p2 = conn.to;
      final dx = p2.x - p1.x;
      final dy = p2.y - p1.y;
      if (dx == 1) {
        roomOpenings[p1]!.add('right');
        roomOpenings[p2]!.add('left');
      } else if (dx == -1) {
        roomOpenings[p1]!.add('left');
        roomOpenings[p2]!.add('right');
      } else if (dy == 1) {
        roomOpenings[p1]!.add('down');
        roomOpenings[p2]!.add('up');
      } else if (dy == -1) {
        roomOpenings[p1]!.add('up');
        roomOpenings[p2]!.add('down');
      }
    }

    // 添加房间片段
    for (final entry in grid.entries) {
      final p = entry.key;
      final mapName = entry.value.split('/').last;
      final pos = getRoomPos(p);

      final map = await _loadMap(mapName);
      final tiled = TiledComponent(map);
      tiled.position = pos;
      tiled.priority = -100;

      segments.add(MapSegment(tiled, pos, mapName, openings: roomOpenings[p]));
    }

    // 添加走廊片段
    for (final conn in connections) {
      final p1 = conn.from;
      final p2 = conn.to;

      // Determine direction
      final dx = p2.x - p1.x;
      final dy = p2.y - p1.y;

      if (dx == 0) {
        // 垂直连接 (Vertical)
        // 逻辑：连接 p1 底部到 p2 顶部 (或反之)
        // 连接发生在 (x,y) 和 (x, y+1) 之间
        final topP = dy > 0 ? p1 : p2;
        final topPos = getRoomPos(topP);

        // 计算走廊位置
        // X: 相对于房间水平居中
        final xOffset = (roomSize - corridorWidth) / 2 * tileSize * scale;
        // Y: 在上方房间的底部
        final yOffset = roomSize * tileSize * scale;

        final corridorPos = topPos + Vector2(xOffset, yOffset);

        final map = await _loadMap('hallway.tmx');
        final tiled = TiledComponent(map);
        tiled.position = corridorPos;
        tiled.priority = -101; // 放在房间下面

        segments.add(MapSegment(tiled, corridorPos, 'hallway.tmx'));
      } else {
        // 水平连接 (Horizontal)
        // 逻辑：连接 p1 右侧到 p2 左侧 (或反之)
        final leftP = dx > 0 ? p1 : p2;
        final leftPos = getRoomPos(leftP);

        // 计算走廊位置
        // X: 在左侧房间的右边
        // Y: 相对于房间垂直居中
        // 需要顺时针旋转 90 度

        // TiledComponent 旋转逻辑：
        // Position 是锚点。
        // 顺时针旋转 90 度后：
        // 视觉左上角相对于锚点是 (-Height, 0)。
        // 我们希望视觉左上角位于 (RoomRight, CenterY)。
        // TargetX = RoomRight = LeftPos.x + RoomSize
        // TargetY = LeftPos.y + (RoomSize - CorridorWidth)/2
        // AnchorX = TargetX + Height (CorridorLength)
        // AnchorY = TargetY

        final roomRealSize = roomSize * tileSize * scale;
        final corrRealLength = corridorLength * tileSize * scale;
        final corrRealWidth = corridorWidth * tileSize * scale;

        final targetX = leftPos.x + roomRealSize;
        final targetY = leftPos.y + (roomRealSize - corrRealWidth) / 2;

        final anchorPos = Vector2(targetX + corrRealLength, targetY);

        final map = await _loadMap('hallway.tmx');
        final tiled = TiledComponent(map);
        tiled.position = anchorPos;
        tiled.angle = math.pi / 2;
        tiled.priority = -101;

        segments.add(
          MapSegment(tiled, anchorPos, 'hallway.tmx', angle: math.pi / 2),
        );
      }
    }

    return CombinedMap(
      segments,
      Vector2(maxX - minX, maxY - minY),
      Vector2(minX, minY),
    );
  }

  /// 生成网格布局和房间类型分配
  ///
  /// 返回包含网格数据和连接列表的 [MapLayout]
  MapLayout generateLayout(List<String> mapFiles, {int? seed}) {
    final random = math.Random(seed);

    // 1. 地图分类
    String? startMap = mapFiles.firstWhere(
      (m) => m.endsWith('room_start.tmx'),
      orElse: () => mapFiles.first,
    );
    String? bossMap = mapFiles.firstWhere(
      (m) => m.endsWith('room_boss.tmx'),
      orElse: () => mapFiles.last,
    );
    String? treasureMap = mapFiles.firstWhere(
      (m) => m.endsWith('room_treasure.tmx'),
      orElse: () => mapFiles.firstWhere(
        (m) => m != startMap && m != bossMap,
        orElse: () => startMap,
      ),
    );
    String? shopMap = mapFiles.firstWhere(
      (m) => m.endsWith('room_shop.tmx'),
      orElse: () => mapFiles.firstWhere(
        (m) => m != startMap && m != bossMap && m != treasureMap,
        orElse: () => startMap,
      ),
    );
    String? battleMap = mapFiles.firstWhere(
      (m) => m.endsWith('room_battle.tmx'),
      orElse: () => mapFiles.firstWhere(
        (m) =>
            m != startMap && m != bossMap && m != treasureMap && m != shopMap,
        orElse: () => startMap,
      ),
    );

    List<String> middleMaps = mapFiles
        .where(
          (m) =>
              !m.endsWith('room_start.tmx') &&
              !m.endsWith('room_boss.tmx') &&
              !m.endsWith('room_treasure.tmx') &&
              !m.endsWith('room_shop.tmx'),
        )
        .toList();

    if (middleMaps.isEmpty) middleMaps = [startMap];

    final int targetRooms = MIN_ROOMS + random.nextInt(MAX_ROOMS - MIN_ROOMS + 1); // MIN..MAX 个房间
    final Map<math.Point<int>, String> grid = {};
    final List<Connection> connections = [];

    // 2. 放置起始房间 (随机位置)
    int startX = random.nextInt(GRID_COLS);
    int startY = random.nextInt(GRID_ROWS);
    math.Point<int> startPos = math.Point(startX, startY);
    grid[startPos] = startMap;

    List<math.Point<int>> frontier = [startPos];

    // 3. 随机游走 / 生长 (限制在 3x3 网格内)
    while (grid.length < targetRooms && frontier.isNotEmpty) {
      final index = random.nextInt(frontier.length);
      final center = frontier[index];

      final directions = [
        const math.Point(0, 1),
        const math.Point(0, -1),
        const math.Point(1, 0),
        const math.Point(-1, 0),
      ]..shuffle(random);

      for (final dir in directions) {
        final neighbor = math.Point(center.x + dir.x, center.y + dir.y);

        if (neighbor.x >= 0 &&
            neighbor.x < GRID_COLS &&
            neighbor.y >= 0 &&
            neighbor.y < GRID_ROWS) {
          if (!grid.containsKey(neighbor)) {
            grid[neighbor] = 'temp';
            connections.add(Connection(center, neighbor));
            frontier.add(neighbor);
            break;
          }
        }
      }
    }

    // 4. 分配房间类型
    // 计算距离以放置 Boss 房 (最远距离)
    math.Point<int> bossPos = startPos;
    double maxDist = -1;

    Map<math.Point<int>, int> distances = {startPos: 0};
    List<math.Point<int>> queue = [startPos];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentDist = distances[current]!;

      if (currentDist > maxDist) {
        maxDist = currentDist.toDouble();
        bossPos = current;
      }

      for (final conn in connections) {
        if (conn.from == current && !distances.containsKey(conn.to)) {
          distances[conn.to] = currentDist + 1;
          queue.add(conn.to);
        } else if (conn.to == current && !distances.containsKey(conn.from)) {
          distances[conn.from] = currentDist + 1;
          queue.add(conn.from);
        }
      }
    }

    if (bossPos != startPos) {
      grid[bossPos] = bossMap;
    }

    List<math.Point<int>> available = grid.keys
        .where((p) => p != startPos && p != bossPos)
        .toList();

    // 确保至少有 3 个战斗房间 (如果空间允许)
    if (available.isNotEmpty && battleMap != null) {
      final int need = math.min(3, available.length);
      for (int i = 0; i < need; i++) {
        final idx = random.nextInt(available.length);
        final pos = available[idx];
        grid[pos] = battleMap;
        available.removeAt(idx);
      }
    }

    // 放置宝箱房
    if (available.isNotEmpty) {
      int treasureIndex = random.nextInt(available.length);
      math.Point<int> treasurePos = available[treasureIndex];
      grid[treasurePos] = treasureMap;
      available.removeAt(treasureIndex);
    }

    // 放置商店房
    if (available.isNotEmpty) {
      int shopIndex = random.nextInt(available.length);
      math.Point<int> shopPos = available[shopIndex];
      grid[shopPos] = shopMap;
      available.removeAt(shopIndex);
    }

    // 填充剩余房间
    for (final p in available) {
      grid[p] = middleMaps[random.nextInt(middleMaps.length)];
    }

    // 替换所有临时标记
    grid.forEach((key, value) {
      if (value == 'temp') {
        grid[key] = middleMaps[random.nextInt(middleMaps.length)];
      }
    });

    return MapLayout(grid, connections);
  }
}

class MapLayout {
  final Map<math.Point<int>, String> grid;
  final List<Connection> connections;
  MapLayout(this.grid, this.connections);
}

class Connection {
  final math.Point<int> from;
  final math.Point<int> to;
  Connection(this.from, this.to);
}
