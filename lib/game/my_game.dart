import 'package:flame/game.dart';
import 'package:myhero/game/component/blocker_component.dart';
import 'character/hero_component.dart';
import 'component/treasure_component.dart';
import 'component/water_component.dart';
import 'component/key_component.dart';
import 'component/door_component.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Text;
import 'package:flame/experimental.dart';
import 'component/wall_component.dart';
import 'component/spawn_point_component.dart';
import '../utils/common.dart';
import 'component/thorn_component.dart';
import 'hud/hero_info_panel.dart';
import 'hud/attack/attack_hud.dart';
import 'component/goal_component.dart';
import '../manager/audio_manager.dart';

class MyGame extends FlameGame with HasCollisionDetection {
  late JoystickComponent joystick;
  late HeroComponent hero;
  // 存储所有阻塞组件，供英雄做帧内碰撞预测
  final List<BlockerComponent> blockers = [];
  // 地图缩放比例
  static const double mapScale = 2.0;
  // 地图瓦片大小
  static const double tileSize = 8.0;
  // 游戏运行时间
  double elapsedTime = 0;

  @override
  Future<void> onLoad() async {
    // 加载游戏资源
    super.onLoad();
    // 初始化音频管理器
    await AudioManager.init();
    AudioManager.startRegularBgm();
    // 加载地图
    await _loadLevel();
  }

  Future<void> _loadLevel() async {
    // 1. 加载地图
    final realTileSize = mapScale * tileSize;
    final tiled = await TiledComponent.load(
      '地牢.tmx',
      Vector2.all(realTileSize),
    );
    world.add(tiled);

    // ---- 处理 thorn 中的荆棘 ----
    final thornLayer = tiled.tileMap.getLayer<ObjectGroup>('thorn');

    if (thornLayer != null) {
      for (final obj in thornLayer.objects) {
        if (obj.properties['type']?.value == 'thorn') {
          final status = obj.properties['status']!.value as String;
          final x = mapScale * obj.x;
          final y = mapScale * obj.y;
          final w = mapScale * obj.width;
          final h = mapScale * obj.height;
          final thornComponent = ThornComponent(
            status: status,
            position: Vector2(x, y),
            size: Vector2(w, h),
          );
          thornComponent.debugMode = true;
          await world.add(thornComponent);
        }
      }
    }

    // ---- 处理 Key Layer 中的钥匙 ----
    final keyLayer = tiled.tileMap.getLayer<ObjectGroup>('key');

    if (keyLayer != null) {
      for (final obj in keyLayer.objects) {
        if (obj.properties['type']?.value == 'key') {
          final keyId = obj.properties['keyId']!.value as String;
          final x = mapScale * obj.x;
          final y = mapScale * obj.y;
          final w = mapScale * obj.width;
          final h = mapScale * obj.height;
          final keyComponent = KeyComponent(
            keyId: keyId,
            position: Vector2(x, y),
            size: Vector2(w, h),
          );
          keyComponent.debugMode = true;
          await world.add(keyComponent);
        }
      }
    }

    // ---- 处理 treasure Layer 中的宝箱 ----
    final treasureLayer = tiled.tileMap.getLayer<ObjectGroup>('treasure');

    if (treasureLayer != null) {
      for (final obj in treasureLayer.objects) {
        if (obj.properties['type']?.value == 'treasure') {
          final status = obj.properties['status']!.value as String;
          final x = mapScale * obj.x;
          final y = mapScale * obj.y;
          final w = mapScale * obj.width;
          final h = mapScale * obj.height;
          final treasureComponent = TreasureComponent(
            status: status,
            position: Vector2(x, y),
            size: Vector2(w, h),
          );
          treasureComponent.debugMode = true;
          await world.add(treasureComponent);
        }
      }
    }

    // ---- 处理 Door Layer 中的门 ----
    final doorLayer = tiled.tileMap.getLayer<ObjectGroup>('door');

    if (doorLayer != null) {
      for (final obj in doorLayer.objects) {
        if (obj.properties['type']?.value == 'door') {
          final keyId = obj.properties['keyId']!.value as String;
          final x = mapScale * obj.x;
          final y = mapScale * obj.y;
          final w = mapScale * obj.width;
          final h = mapScale * obj.height;
          final doorComponent = DoorComponent(
            keyId: keyId,
            isOpen: obj.properties['status']?.value == 'open' ? true : false,
            position: Vector2(x, y),
            size: Vector2(w, h),
          );
          doorComponent.debugMode = true;
          await world.add(doorComponent);
        }
      }
    }

    // ---- 处理 water 碰撞区 ----
    final waterLayer = tiled.tileMap.getLayer<TileLayer>('water');
    if (waterLayer != null && waterLayer.data != null) {
      await addMergedTileLayerV2(
        tileData: waterLayer.data!,
        width: waterLayer.width,
        height: waterLayer.height,
        tileSize: tileSize,
        scale: mapScale,
        createComponent: (position, size) async {
          final water = WaterComponent(position: position, size: size);
          blockers.add(water);
          water.debugMode = true;
          return water;
        },
        parent: world,
      );
    }

    //

    // ---- 处理 wall 碰撞 ----
    // final wallLayer = tiled.tileMap.getLayer<TileLayer>('wall');
    // if (wallLayer != null && wallLayer.data != null) {
    //   await addMergedTileLayerV2(
    //     tileData: wallLayer.data!,
    //     width: wallLayer.width,
    //     height: wallLayer.height,
    //     tileSize: tileSize,
    //     scale: mapScale,
    //     createComponent: (position, size) async {
    //       final wall = WallComponent(position: position, size: size);
    //       blockers.add(wall);
    //       wall.debugMode = true;
    //       return wall;
    //     },
    //     parent: world,
    //   );
    // }

    final objGroup = tiled.tileMap.getLayer<ObjectGroup>('Collisions');

    if (objGroup != null) {
      for (final obj in objGroup.objects) {
        final x = mapScale * obj.x;
        final y = mapScale * obj.y;
        final w = mapScale * obj.width;
        final h = mapScale * obj.height;

        // 将墙体添加为 WallComponent 组件
        final wall = WallComponent(
          position: Vector2(x, y),
          size: Vector2(w, h),
        );
        wall.debugMode = true;
        blockers.add(wall);
        await world.add(wall);
      }
    }

    // ---- 处理 spawn_points 中的怪物和终点 ----
    final spawnLayer = tiled.tileMap.getLayer<ObjectGroup>('spawn_points');
    if (spawnLayer != null) {
      for (final obj in spawnLayer.objects) {
        final type = obj.properties['type']?.value as String?;
        final monsterId =
            obj.properties['monsterId']?.value as String? ?? 'elite_orc';
        final x = mapScale * obj.x;
        final y = mapScale * obj.y;
        final w = mapScale * obj.width;
        final h = mapScale * obj.height;
        if (type == 'monster_spawn') {
          final maxCount = obj.properties['maxCount']?.value as int? ?? 3;
          final perCount = obj.properties['perCount']?.value as int? ?? 1;
          final productSpeedSec =
              obj.properties['productSpeed']?.value as int? ?? 3;

          final spawn = SpawnPointComponent(
            position: Vector2(x, y),
            size: Vector2(w, h),
            maxCount: maxCount,
            monsterId: monsterId,
            perCount: perCount,
            productSpeed: Duration(seconds: productSpeedSec),
          );
          spawn.debugMode = true;
          await world.add(spawn);
          spawn.start();
        } else if (type == 'goal') {
          final goalComponent = GoalComponent(
            position: Vector2(x, y),
            size: Vector2(w, h),
          );
          goalComponent.debugMode = true;
          await world.add(goalComponent);
        }
      }
    }

    // 2. 创建摇杆
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: Paint()..color = Colors.white70),
      background: CircleComponent(
        radius: 80,
        paint: Paint()..color = Colors.black87.withOpacity(0.5),
      ),
      margin: const EdgeInsets.only(left: 50, bottom: 50),
    );

    // 3. 创建英雄
    hero = HeroComponent();
    hero.debugMode = true;

    // 4. 添加进入场景
    camera.viewport.add(joystick);
    world.add(hero);

    // 5. 添加 HUD
    final hud = HeroInfoPanel(hero)..position = Vector2(17, 17);
    camera.viewport.add(hud);

    // 添加攻击 HUD
    final attackHud = AttackHud(hero)
      ..anchor = Anchor.bottomRight
      ..position = Vector2(size.x - 50, size.y - 50);

    camera.viewport.add(attackHud);

    // ---- Camera ----
    camera.setBounds(Rectangle.fromLTRB(0, 0, tiled.size.x, tiled.size.y));
    camera.follow(hero);
  }

  Future<void> restartGame() async {
    resumeEngine();
    blockers.clear();
    for (final c in List<Component>.from(world.children)) {
      c.removeFromParent();
    }
    for (final c in List<Component>.from(camera.viewport.children)) {
      c.removeFromParent();
    }
    await _loadLevel();
  }

  @override
  void update(double dt) {
    // 游戏逻辑，每帧更新
    super.update(dt);
    elapsedTime += dt;
  }

  @override
  void render(Canvas canvas) {
    // 渲染逻辑
    super.render(canvas);
  }
}
