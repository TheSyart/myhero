import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import '../../level_loader.dart';
import '../room_logic.dart';

/// Boss 房间逻辑
class BossRoomLogic implements RoomLogic {
  @override
  bool matches(String mapName) => mapName.contains('boss');

  @override
  void execute(
    LevelLoader loader,
    TiledComponent tiled,
    Vector2 offset,
    double angle,
  ) {
    // 示例：在 Boss 房间添加特殊的 Boss 敌人
    print('Executing Boss Room Logic');
    // loader.game.world.add(BossEnemy(...));
  }
}
