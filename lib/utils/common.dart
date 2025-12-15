import 'package:flame/components.dart';

/// 扫描 TileLayer 数据，将连续非零瓦片合并成矩形组件（水平+垂直合并）
/// [tileData] - TileLayer.data，按行展开
/// [width] - TileLayer 宽度（列数）
/// [height] - TileLayer 高度（行数）
/// [tileSize] - 每个瓦片大小
/// [scale] - 地图缩放
/// [createComponent] - 创建每个碰撞块的方法
Future<void> addMergedTileLayerV2({
  required List<int> tileData,
  required int width,
  required int height,
  required double tileSize,
  double scale = 1.0,
  required Future<PositionComponent> Function(Vector2 position, Vector2 size)
      createComponent,
  required Component parent,
}) async {
  // Step1: 先按行生成水平合并块
  List<List<int>> rects = []; // 每行的开始列和宽度
  List<List<int>> horizontalRects = List.generate(height, (_) => []);

  for (var y = 0; y < height; y++) {
    int startX = -1;
    for (var x = 0; x <= width; x++) {
      final isFilled = x < width && tileData[y * width + x] != 0;

      if (isFilled && startX == -1) {
        startX = x;
      }

      if ((!isFilled || x == width) && startX != -1) {
        horizontalRects[y].addAll([startX, x - startX]);
        startX = -1;
      }
    }
  }

  // Step2: 垂直合并相同列和宽度的块
  List<List<int>> processed = List.generate(height, (_) => List.filled(width, 0));
  for (var y = 0; y < height; y++) {
    for (var i = 0; i < horizontalRects[y].length; i += 2) {
      final xStart = horizontalRects[y][i];
      final w = horizontalRects[y][i + 1];

      if (processed[y][xStart] == 1) continue;

      // 尝试向下合并
      int rectHeight = 1;
      for (var yy = y + 1; yy < height; yy++) {
        bool canMerge = false;
        for (var j = 0; j < horizontalRects[yy].length; j += 2) {
          if (horizontalRects[yy][j] == xStart &&
              horizontalRects[yy][j + 1] == w) {
            canMerge = true;
            break;
          }
        }
        if (canMerge) {
          rectHeight++;
          for (var col = xStart; col < xStart + w; col++) {
            processed[yy][col] = 1;
          }
        } else {
          break;
        }
      }

      // 创建组件
      final position =
          Vector2(xStart * tileSize * scale, y * tileSize * scale);
      final size = Vector2(w * tileSize * scale, rectHeight * tileSize * scale);
      final block = await createComponent(position, size);
      await parent.add(block);

      for (var col = xStart; col < xStart + w; col++) {
        processed[y][col] = 1;
      }
    }
  }
}
