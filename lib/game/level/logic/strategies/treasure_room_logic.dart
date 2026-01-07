import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import '../../level_loader.dart';
import '../room_logic.dart';

/// 宝箱房间逻辑
class TreasureRoomLogic implements RoomLogic {
  @override
  bool matches(String mapName) => mapName.contains('treasure');

  @override
  void execute(
    LevelLoader loader,
    TiledComponent tiled,
    Vector2 offset,
    double angle,
  ) {
    // 示例：在宝箱房间添加额外的特效
    print('Executing Treasure Room Logic');
  }
}
