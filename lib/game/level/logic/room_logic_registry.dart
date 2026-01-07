import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import '../level_loader.dart';
import 'room_logic.dart';
import 'strategies/boss_room_logic.dart';
import 'strategies/shop_room_logic.dart';
import 'strategies/treasure_room_logic.dart';
import 'strategies/battle_room_logic.dart';
import 'strategies/start_room_logic.dart';

/// 房间逻辑注册表
class RoomLogicRegistry {
  static final List<RoomLogic> _strategies = [
    StartRoomLogic(),
    BattleRoomLogic(),
    BossRoomLogic(),
    ShopRoomLogic(),
    TreasureRoomLogic(),
  ];

  /// 注册新的策略
  static void register(RoomLogic strategy) {
    _strategies.add(strategy);
  }

  /// 执行匹配的策略
  static void executeStrategies(
    String mapName,
    LevelLoader loader,
    TiledComponent tiled,
    Vector2 offset,
    double angle,
  ) {
    for (final strategy in _strategies) {
      if (strategy.matches(mapName)) {
        strategy.execute(loader, tiled, offset, angle);
      }
    }
  }
}
