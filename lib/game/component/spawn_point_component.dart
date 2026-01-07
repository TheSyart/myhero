import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/character/monster_component.dart';
import 'package:myhero/game/config/character_config.dart';
import 'package:myhero/game/character/hero_component.dart';

/// 刷怪点统一管理组件与数据结构
/// 功能概述：
/// 1. 接收房间内所有刷怪点配置(sites)并计算整体包围范围
/// 2. 进入房间触发首波；清空后触发下一波；全部完成后执行清理并自毁
/// 3. 施加同时存活怪物上限(maxActive)，超出时随机移除若干
/// 4. 自毁(parent==null)作为战斗完成信号，供房间监控器(如 BattleRoomWatcher)使用

/// 刷怪点数据结构：描述一个具体刷怪区域及配置
class SpawnSite {
  final Vector2 position;
  final Vector2 size;
  final String? monsterId;
  final int perCount;
  final String? type;
  const SpawnSite({
    required this.position,
    required this.size,
    this.monsterId,
    this.perCount = 3,
    this.type,
  });
}

/// 刷怪统一管理组件：集中管理房间内所有刷怪点与波次
class SpawnPointComponent extends PositionComponent
    with HasGameReference<MyGame> {
  /// 房间内所有刷怪点的位置与配置
  final List<SpawnSite> sites;

  /// 总波次数，默认 3
  final int waveCount;

  /// 同时存活刷怪点上限，默认 3
  final int maxActive;

  /// 所有刷怪点的包围矩形，用于进入判定与房间归属
  Rect? _bounds;

  /// 当前已触发的波次编号
  int _currentWave = 0;

  /// 玩家是否已进入房间（触发区域）
  bool _entered = false;

  /// 是否正在进行一次波次生成
  bool _spawning = false;

  /// 当前已生成的怪物集合（用于存活统计与清理）
  final Set<MonsterComponent> _spawned = {};

  SpawnPointComponent({
    required this.sites,
    this.waveCount = 3,
    this.maxActive = 3,
    Anchor anchor = Anchor.center,
    int priority = 0,
  }) : super(anchor: anchor, priority: priority);

  @override
  Future<void> onLoad() async {
    try {
      /// 为空则无需存在，直接自毁
      if (sites.isEmpty) {
        removeFromParent();
        return;
      }

      /// 计算所有刷怪点的整体包围范围(_bounds)
      double minX = double.infinity, minY = double.infinity;
      double maxX = -double.infinity, maxY = -double.infinity;
      for (final s in sites) {
        minX = math.min(minX, s.position.x);
        minY = math.min(minY, s.position.y);
        maxX = math.max(maxX, s.position.x + s.size.x);
        maxY = math.max(maxY, s.position.y + s.size.y);
      }
      _bounds = Rect.fromLTWH(minX, minY, maxX - minX, maxY - minY);

      /// 将组件的位置与大小设置为包围范围的中心与尺寸
      position = Vector2(_bounds!.center.dx, _bounds!.center.dy);
      size = Vector2(_bounds!.width, _bounds!.height);

      /// 施加刷怪点上限：超过则随机移除多余的刷怪点（保持包围范围不变）
      _enforceSiteCap();
    } catch (_) {
      /// 初始化失败，安全自毁
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    try {
      if (_bounds == null) return;

      /// 进入检测：英雄进入包围范围后标记为已进入
      if (!_entered) {
        for (final h in game.world.children.query<HeroComponent>()) {
          if (_bounds!.contains(Offset(h.position.x, h.position.y))) {
            _entered = true;
            break;
          }
        }
      }

      /// 清理已死亡或已被移除的怪物引用
      _spawned.removeWhere((m) => m.parent == null || m.isDead);

      /// 首波触发：仅在已进入后触发第一波
      if (_currentWave == 0 && !_spawning && _entered) {
        _spawnWave();
        return;
      }

      /// 连续波次：当前波全部清空后，若尚未达到总波数则触发下一波（进入后）
      if (_spawned.isEmpty &&
          _currentWave < waveCount &&
          !_spawning &&
          _entered) {
        _spawnWave();
        return;
      }

      /// 战斗完成：全部波次清空后执行清理与自毁
      if (_spawned.isEmpty && _currentWave >= waveCount) {
        _cleanup();
      }
    } catch (_) {}
  }

  /// 外部查询：是否已进入房间触发区
  bool get entered => _entered;

  /// 触发并生成一波怪物
  void _spawnWave() {
    _spawning = true;
    _currentWave++;
    try {
      for (final site in sites) {
        final count = site.perCount > 0 ? site.perCount : 1;
        for (int i = 0; i < count; i++) {
          /// 怪物ID为空或空串时，使用随机怪物ID
          final id = (site.monsterId == null || site.monsterId!.isEmpty)
              ? CharacterConfig.randomMonsterId
              : site.monsterId!;

          /// 在该刷怪点范围内随机位置生成
          final rx = math.Random().nextDouble();
          final ry = math.Random().nextDouble();
          final pos =
              site.position + Vector2(rx * site.size.x, ry * site.size.y);
          final monster = MonsterComponent(pos, id);
          game.world.add(monster);
          _spawned.add(monster);
        }
      }
    } catch (_) {
    } finally {
      _spawning = false;
    }
  }

  /// 施加同时存活刷怪点上限，超出则随机移除
  void _enforceSiteCap() {
    try {
      final rng = math.Random();
      if (sites.length <= maxActive) return;
      int excess = sites.length - maxActive;
      while (excess > 0 && sites.isNotEmpty) {
        final idx = rng.nextInt(sites.length);
        sites.removeAt(idx);
        excess--;
      }
    } catch (_) {}
  }

  /// 战斗完成后的清理逻辑：释放资源并自毁
  void _cleanup() {
    try {
      _spawned.clear();
      sites.clear();
    } catch (_) {
    } finally {
      removeFromParent();
    }
  }
}
