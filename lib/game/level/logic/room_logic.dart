import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import '../level_loader.dart';

/// 房间逻辑接口
///
/// 定义了特定房间类型的特殊逻辑处理
abstract class RoomLogic {
  /// 判断该逻辑是否适用于给定的地图名称
  bool matches(String mapName);

  /// 执行特殊的房间逻辑
  ///
  /// [loader] 关卡加载器实例，可用于访问 game, world 等
  /// [tiled] 当前房间的 TiledComponent
  /// [offset] 当前房间的世界坐标偏移
  /// [angle] 当前房间的旋转角度
  void execute(
    LevelLoader loader,
    TiledComponent tiled,
    Vector2 offset,
    double angle,
  );
}