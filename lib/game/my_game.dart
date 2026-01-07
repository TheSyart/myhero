import 'package:flame/game.dart';
import 'package:myhero/game/component/blocker_component.dart';
import 'character/hero_component.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'hud/hero_info_panel.dart';
import 'hud/attack/attack_hud.dart';
import 'hud/minimap_hud.dart';
import '../manager/audio_manager.dart';
import 'level/level_loader.dart';
import 'hud/pause_button_component.dart';
import 'package:myhero/game/hud/coin_hud.dart';
import 'package:myhero/component/dialog_component.dart';
// import 'package:flame/input.dart';

import 'state/map_type.dart';

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
  bool isPaused = false;

  late LevelLoader levelLoader;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    await AudioManager.init();
    AudioManager.startRegularBgm();

    levelLoader = LevelLoader(this);
    await levelLoader.load(MapType.home);

    hero = HeroComponent(birthPosition: levelLoader.heroBirthPoint);
    await world.add(hero);

    camera.follow(hero);

    _initHud();
  }

  void _initHud() {
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: Paint()..color = Colors.white70),
      background: CircleComponent(
        radius: 80,
        paint: Paint()..color = Colors.black87.withOpacity(0.5),
      ),
      margin: const EdgeInsets.only(left: 50, bottom: 50),
    );

    camera.viewport.add(joystick);
    camera.viewport.add(HeroInfoPanel(hero)..position = Vector2(17, 17));
    camera.viewport.add(
      AttackHud(hero)
        ..anchor = Anchor.bottomRight
        ..position = Vector2(size.x - 50, size.y - 50),
    );
    camera.viewport.add(
      MinimapHud()
        ..anchor = Anchor.topRight
        ..position = Vector2(size.x - 20, 20),
    );
    camera.viewport.add(
      CoinHud()
        ..anchor = Anchor.topRight
        ..position = Vector2(size.x - 50, 20),
    );
    camera.viewport.add(
      PauseButtonComponent()
        ..anchor = Anchor.topRight
        ..position = Vector2(size.x - 10, 20),
    );
  }

  void pauseGame() {
    isPaused = true;
    AudioManager.pauseBgm();
    final exists =
        camera.viewport.children.query<PauseOverlay>().isNotEmpty;
    if (!exists) {
      camera.viewport.add(PauseOverlay());
    }
  }

  void resumeGame() {
    isPaused = false;
    AudioManager.resumeBgm();
    for (final o in camera.viewport.children.query<PauseOverlay>()) {
      o.removeFromParent();
    }
  }

  Future<void> restartGame() async {
    // 恢复游戏状态
    resumeGame();
    
    // 清理数据
    blockers.clear();
    elapsedTime = 0;

    // 清理场景和UI
    world.removeAll(world.children);
    camera.viewport.removeAll(camera.viewport.children);

    // 重新加载主城地图
    await levelLoader.load(MapType.home);

    // 重建英雄
    hero = HeroComponent(birthPosition: levelLoader.heroBirthPoint);
    await world.add(hero);

    // 重置相机
    camera.follow(hero);

    // 重建UI
    _initHud();
  }

  @override
  void update(double dt) {
    final freezeDt = isPaused ? 0.0 : dt;
    super.update(freezeDt);
    elapsedTime += dt;
  }

  @override
  void render(Canvas canvas) {
    // 渲染逻辑
    super.render(canvas);
  }
}
