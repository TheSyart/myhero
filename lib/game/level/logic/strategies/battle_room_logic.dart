import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'dart:ui';
import '../../level_loader.dart';
import '../room_logic.dart';
import '../../../component/door_component.dart';
import '../../../component/spawn_point_component.dart';
import '../../../my_game.dart';

/// 战斗房间逻辑策略实现
/// 负责处理战斗类型房间的特殊逻辑：
/// 1. 识别战斗房间
/// 2. 初始化房间监控器(_BattleRoomWatcher)
class BattleRoomLogic implements RoomLogic {
  @override
  bool matches(String mapName) => mapName.contains('battle');

  @override
  void execute(
    LevelLoader loader,
    TiledComponent tiled,
    Vector2 offset,
    double angle,
  ) {
    final game = loader.game;
    // 计算房间的矩形区域
    final roomRect = Rect.fromLTWH(offset.x, offset.y, tiled.size.x, tiled.size.y);

    // 添加监控器组件到游戏世界，用于实时监控房间状态
    game.world.add(_BattleRoomWatcher(roomRect));
  }
}

/// 战斗房间监控器
/// 负责监控玩家进入和战斗状态，控制门的开关
class _BattleRoomWatcher extends Component with HasGameReference<MyGame> {
  final Rect roomRect; // 房间区域
  SpawnPointComponent? manager; // 刷怪点管理器
  List<DoorComponent>? doors; // 房间内的门
  bool closed = false; // 门是否已关闭（战斗开始标记）

  _BattleRoomWatcher(this.roomRect);

  @override
  void update(double dt) {
    super.update(dt);
    
    // 延迟查找：每一帧尝试查找门和刷怪管理器，直到找到为止
    // 这样做是因为组件加载顺序可能不同，刚开始可能还没加载完成
    doors ??= _findDoors();
    manager ??= _findManager();

    // 逻辑1：检测战斗开始
    // 条件：找到管理器 + 门未关闭 + 玩家已进入触发区域
    if (manager != null && !closed && manager!.entered) {
      for (DoorComponent d in (doors ?? const [])) {
        d.close(); // 关门
        d.setLocked(true); // 强制锁定，防止玩家手动打开
      }
      closed = true; // 标记战斗已开始（门已关）
    }

    // 逻辑2：检测战斗结束
    // 条件：找到过管理器 + 管理器已被销毁(parent == null)
    // SpawnPointComponent 会在所有波次怪物清空后自我销毁，利用这一特性判断战斗结束
    if (manager != null && manager!.parent == null) {
      for (DoorComponent d in (doors ?? const [])) {
        d.setLocked(false); // 解除强制锁定
        d.open(); // 自动开门
      }
      removeFromParent(); // 任务完成，销毁监控器自身
    }
  }

  /// 查找当前房间区域内的所有门组件
  List<DoorComponent> _findDoors() {
    final r = <DoorComponent>[];
    for (final d in game.world.children.query<DoorComponent>()) {
      // 创建门的矩形区域用于检测重叠
      final rect = Rect.fromLTWH(d.position.x, d.position.y, d.size.x, d.size.y);
      // 如果门在房间范围内，加入列表
      if (rect.overlaps(roomRect)) r.add(d);
    }
    return r;
  }

  /// 查找当前房间区域内的刷怪点管理器
  SpawnPointComponent? _findManager() {
    for (final s in game.world.children.query<SpawnPointComponent>()) {
      // 创建管理器的矩形区域（居中对齐的逻辑）
      final rect = Rect.fromLTWH(
        s.position.x - s.size.x / 2,
        s.position.y - s.size.y / 2,
        s.size.x,
        s.size.y,
      );
      // 如果管理器在房间范围内，返回该实例
      if (rect.overlaps(roomRect)) return s;
    }
    return null;
  }
}
