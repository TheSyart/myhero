import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:myhero/game/level/map_combiner.dart';
import 'package:myhero/game/level/level_loader.dart';
import 'package:myhero/game/my_game.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// 小地图 HUD 组件
///
/// 负责在游戏界面右上角显示当前关卡的小地图。
/// 功能包括：
/// 1. 显示房间和走廊的布局结构
/// 2. 标记特殊房间（起点、Boss、商店、宝箱、战斗房）
/// 3. 实时显示英雄在地图中的位置
/// 4. 自动缩放以适应地图尺寸，保持 3x3 网格结构的视觉一致性
class MinimapHud extends PositionComponent with HasGameReference<MyGame> {
  /// 当前组合地图数据
  CombinedMap? _combined;

  /// 缓存的房间矩形列表（用于绘制）
  final List<Rect> _roomRects = [];

  /// 缓存的走廊矩形列表（用于绘制）
  final List<Rect> _corridorRects = [];

  /// 世界地图的左上角坐标（通常为 (0,0)）
  Vector2 _worldTopLeft = Vector2.zero();

  /// 世界地图的总尺寸（固定的 3x3 网格大小）
  Vector2 _worldSize = Vector2.zero();

  /// 缩放倍率（默认为 1.0）
  double _zoom = 1.0;

  /// 内容缩放基准
  final double _contentScale = 1.0;

  /// 地图标记图标的大小
  final double _iconSize = 12.0;

  /// 小地图内容的内边距
  final double _padding = 4.0;

  /// 图标资源缓存
  final Map<String, ui.Image> _icons = {};

  /// 特殊房间标记列表
  final List<_Marker> _markers = [];

  // --- 画笔定义 ---

  /// 背景画笔（半透明黑色）
  final Paint _bgPaint = Paint()..color = const Color(0x88000000);

  /// 边框画笔（白色线条）
  final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const Color(0xFFFFFFFF);

  /// 房间画笔（白色轮廓）
  final Paint _roomPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = const Color(0xFFFFFFFF);

  /// 走廊画笔（灰色轮廓）
  final Paint _corridorPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFFAAAAAA);

  /// 英雄位置画笔（红色圆点）
  final Paint _heroPaint = Paint()..color = const Color(0xFFFF4444);

  /// 设置缩放级别
  ///
  /// [z] 缩放值，限制在 0.5 到 3.0 之间
  void setZoom(double z) {
    _zoom = z.clamp(0.5, 3.0);
  }

  @override
  Future<void> onLoad() async {
    // 设置小地图尺寸为屏幕宽度的 20%
    final side = game.size.x * 0.2;
    size = Vector2(side, side);
    anchor = Anchor.topRight;
    // 设置位置在右上角，留出 20 像素边距
    position = Vector2(game.size.x - 20, 20);

    // 监听地图加载事件
    final LevelLoader loader = game.levelLoader;
    _applyCombined(loader.currentCombinedMap);
    loader.mapNotifier.addListener(() {
      _applyCombined(loader.mapNotifier.value);
    });
  }

  /// 应用新的地图数据
  ///
  /// 当生成新地牢时调用，重新计算所有房间和走廊的显示矩形。
  void _applyCombined(CombinedMap? m) {
    _combined = m;
    _roomRects.clear();
    _corridorRects.clear();
    _markers.clear();

    if (m == null) {
      _worldTopLeft = Vector2.zero();
      _worldSize = Vector2.zero();
      return;
    }

    // 使用 MapCombiner 计算出的完整 3x3 边界
    _worldTopLeft = m.topLeft.clone();
    _worldSize = m.size.clone();

    // 遍历所有地图片段，计算它们在小地图上的相对位置
    for (final seg in m.segments) {
      final rect = _computeSegmentRect(seg);
      if (seg.mapName.endsWith('hallway.tmx')) {
        _corridorRects.add(rect);
      } else {
        _roomRects.add(rect);

        // 识别并添加特殊房间标记
        String? type;
        if (seg.mapName.endsWith('room_start.tmx'))
          type = 'start';
        else if (seg.mapName.endsWith('room_boss.tmx'))
          type = 'boss';
        else if (seg.mapName.endsWith('room_shop.tmx'))
          type = 'shop';
        else if (seg.mapName.endsWith('room_treasure.tmx'))
          type = 'treasure';
        else if (seg.mapName.endsWith('room_battle.tmx'))
          type = 'battle';

        if (type != null) {
          _markers.add(_Marker(type, rect));
        }
      }
    }
  }

  /// 计算单个地图片段的矩形区域
  ///
  /// 处理地图的旋转（如横向/纵向走廊），将其转换为相对于世界左上角的矩形。
  Rect _computeSegmentRect(MapSegment seg) {
    final localPos = Vector2.zero();
    final localSize = seg.tiled.size.clone();
    final angle = seg.angle;

    // 如果没有旋转，直接计算
    if (angle == 0) {
      final left = seg.offset.x - _worldTopLeft.x;
      final top = seg.offset.y - _worldTopLeft.y;
      return Rect.fromLTWH(left, top, localSize.x, localSize.y);
    }

    // 如果有旋转，需要变换四个顶点来计算包围盒
    final p1 = localPos;
    final p2 = localPos + Vector2(localSize.x, 0);
    final p3 = localPos + localSize;
    final p4 = localPos + Vector2(0, localSize.y);

    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    Vector2 rotate(Vector2 v) {
      return Vector2(v.x * cosA - v.y * sinA, v.x * sinA + v.y * cosA);
    }

    final rp1 = rotate(p1);
    final rp2 = rotate(p2);
    final rp3 = rotate(p3);
    final rp4 = rotate(p4);

    final minX = math.min(math.min(rp1.x, rp2.x), math.min(rp3.x, rp4.x));
    final maxX = math.max(math.max(rp1.x, rp2.x), math.max(rp3.x, rp4.x));
    final minY = math.min(math.min(rp1.y, rp2.y), math.min(rp3.y, rp4.y));
    final maxY = math.max(math.max(rp1.y, rp2.y), math.max(rp3.y, rp4.y));

    final left = seg.offset.x - _worldTopLeft.x + minX;
    final top = seg.offset.y - _worldTopLeft.y + minY;

    return Rect.fromLTWH(left, top, maxX - minX, maxY - minY);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. 绘制背景和边框
    final bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(bgRect, _bgPaint);
    canvas.drawRect(bgRect, _borderPaint);

    if (_worldSize.x <= 0 || _worldSize.y <= 0) return;

    // 2. 计算缩放比例和偏移
    // 强制左上角对齐，并保留固定边距，确保 3x3 网格位置固定
    final factor = _fitFactor();
    final centerOffsetX = _padding;
    final centerOffsetY = _padding;

    // 3. 计算英雄在小地图上的位置
    final heroPos = game.hero.position;
    final heroMinimapX = (heroPos.x - _worldTopLeft.x) * factor;
    final heroMinimapY = (heroPos.y - _worldTopLeft.y) * factor;

    // 辅助函数：绘制缩放后的矩形
    void drawRectScaled(Rect r, Paint p) {
      final scaled = Rect.fromLTWH(
        r.left * factor + centerOffsetX,
        r.top * factor + centerOffsetY,
        r.width * factor,
        r.height * factor,
      );
      canvas.drawRect(scaled, p);
    }

    // 4. 绘制走廊
    for (final r in _corridorRects) {
      drawRectScaled(r, _corridorPaint);
    }

    // 5. 绘制房间
    for (final r in _roomRects) {
      drawRectScaled(r, _roomPaint);
    }

    // 6. 绘制英雄位置
    final heroX = heroMinimapX + centerOffsetX;
    final heroY = heroMinimapY + centerOffsetY;
    canvas.drawCircle(Offset(heroX, heroY), 3, _heroPaint);

    // 7. 绘制特殊房间图标
    for (final m in _markers) {
      final img = _icons[m.type];
      if (img == null) continue;

      // 计算图标位置（居中显示在房间矩形内）
      final cx =
          m.rect.left * factor + centerOffsetX + m.rect.width * factor / 2;
      final cy =
          m.rect.top * factor + centerOffsetY + m.rect.height * factor / 2;
      final half = _iconSize / 2;

      final dst = Rect.fromLTWH(cx - half, cy - half, _iconSize, _iconSize);
      final src = Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      canvas.drawImageRect(img, src, dst, Paint());
    }
  }

  /// 计算缩放因子
  ///
  /// 根据世界地图尺寸和小地图显示区域尺寸，计算合适的缩放比例。
  /// 确保地图内容能够完整显示在小地图区域内，并保持长宽比。
  double _fitFactor() {
    final availW = size.x - 2 * _padding;
    final availH = size.y - 2 * _padding;

    final fx = availW / _worldSize.x;
    final fy = availH / _worldSize.y;

    // 取宽高中较小的缩放比，确保内容完全可见
    final base = math.min(fx, fy);
    final effectiveZoom = math.min(_zoom, 1.0);

    return base * effectiveZoom * _contentScale;
  }

  double debugFactor() => _fitFactor();
  Offset debugCenterOffset() {
    return Offset(_padding, _padding);
  }

  @override
  Future<void> onMount() async {
    super.onMount();
    // 加载图标资源
    _icons['start'] = await game.images.load('map/start.png');
    _icons['boss'] = await game.images.load('map/boss.png');
    _icons['treasure'] = await game.images.load('map/treasure.png');
    _icons['shop'] = await game.images.load('map/shop.png');
    _icons['battle'] = await game.images.load('map/battle.png');
  }
}

/// 内部类：特殊房间标记数据
class _Marker {
  final String type;
  final Rect rect;
  _Marker(this.type, this.rect);
}
