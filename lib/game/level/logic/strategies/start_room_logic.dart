import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import '../../level_loader.dart';
import '../room_logic.dart';

/// 初始房间逻辑
class StartRoomLogic implements RoomLogic {
  @override
  bool matches(String mapName) => mapName.contains('start');

  @override
  void execute(
    LevelLoader loader,
    TiledComponent tiled,
    Vector2 offset,
    double angle,
  ) {
    // 示例：在初始房间设置玩家出生点特效或新手引导
    print('Executing Start Room Logic');
    // loader.showTutorialHint();
  }
}
