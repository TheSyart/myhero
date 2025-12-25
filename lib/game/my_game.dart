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

  late LevelLoader levelLoader;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    await AudioManager.init();
    AudioManager.startRegularBgm();

    levelLoader = LevelLoader(this);
    await levelLoader.load('home.tmx');

    hero = HeroComponent(birthPosition: levelLoader.heroBirthPoint)
      ..debugMode = true;
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
