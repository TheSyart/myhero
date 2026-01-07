import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import '../../level_loader.dart';
import '../room_logic.dart';

/// 商店房间逻辑
class ShopRoomLogic implements RoomLogic {
  @override
  bool matches(String mapName) => mapName.contains('shop');

  @override
  void execute(
    LevelLoader loader,
    TiledComponent tiled,
    Vector2 offset,
    double angle,
  ) {
    // 示例：在商店房间添加商人 NPC
    print('Executing Shop Room Logic');
    // loader.game.world.add(ShopKeeper(...));
  }
}
