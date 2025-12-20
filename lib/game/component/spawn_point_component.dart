import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/monster_component.dart';

/// 怪物生成点组件
///
/// - 支持定时按批次生成怪物
/// - 支持最大数量限制与开始/停止控制
/// - 位置与大小由关卡配置决定（用于调试显示）
class SpawnPointComponent extends PositionComponent
    with HasGameReference<MyGame> {
  /// 场景允许存在的最大怪物总数
  final int maxCount;

  /// 要生成的怪物类型 ID（与现有代码一致，使用字符串）
  final String monsterId;

  /// 每次生成的怪物数量
  final int perCount;

  /// 每次生成的时间间隔
  final Duration productSpeed;

  bool _running = false;
  double _timeSinceLastSpawn = 0;
  final Set<MonsterComponent> _spawned = {};

  SpawnPointComponent({
    required Vector2 position,
    required Vector2 size,
    required this.maxCount,
    required this.monsterId,
    required this.perCount,
    required this.productSpeed,
    Anchor anchor = Anchor.center,
    int priority = 0,
  }) : super(
          position: position,
          size: size,
          anchor: anchor,
          priority: priority,
        );

  @override
  Future<void> onLoad() async {
    debugMode = true;
  }

  /// 开始生成
  void start() {
    _running = true;
  }

  /// 停止生成并重置计时
  void stop() {
    _running = false;
    _timeSinceLastSpawn = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_running) return;

    _timeSinceLastSpawn += dt;
    final intervalSeconds = productSpeed.inMicroseconds / 1e6;

    // 按间隔生成，避免长帧遗漏
    while (_timeSinceLastSpawn >= intervalSeconds) {
      _timeSinceLastSpawn -= intervalSeconds;
      _spawnBatch();
    }
  }

  void _spawnBatch() {
    // 仅统计由该生成点产生、且仍存在于场景中的怪物数量
    _spawned.removeWhere((m) => m.parent == null);
    final currentCount = _spawned.length;
    final allowance = maxCount - currentCount;
    if (allowance <= 0) return;

    final batch = math.min(perCount, allowance);
    for (int i = 0; i < batch; i++) {
      final monster = MonsterComponent(position.clone(), monsterId);
      monster.debugMode = true;
      game.world.add(monster);
      _spawned.add(monster);
    }
  }


}
