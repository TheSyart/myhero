import 'package:flame/game.dart';
import 'component/hero_component.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Text;
import 'package:flame/experimental.dart';
import 'component/wall_component.dart';

class MyGame extends FlameGame with HasCollisionDetection {
  late JoystickComponent joystick;
  late HeroComponent hero;
  // 存储所有墙体组件，供英雄做帧内碰撞预测
  final List<WallComponent> walls = [];
  // 地图缩放比例
  static const double mapScale = 2.0;
  // 地图瓦片大小
  static const double tileSize = 8.0;

  @override
  Future<void> onLoad() async {
    // 加载游戏资源
    super.onLoad();

    // 1. 加载地图
    final realTileSize = mapScale * tileSize;
    final tiled = await TiledComponent.load('地牢.tmx', Vector2.all(realTileSize));
    world.add(tiled);

    // ---- 处理 Object Layer 碰撞 ----
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
        walls.add(wall);
        await world.add(wall);
      }
    }

    // 2. 创建摇杆
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: Paint()..color = Colors.white70),
      background: CircleComponent(
        radius: 80,
        paint: Paint()..color = Colors.black87,
      ),
      margin: const EdgeInsets.only(left: 50, bottom: 50),
    );

    // 3. 创建英雄
    hero = HeroComponent();
    hero.debugMode = true;
    // 4. 添加进入场景
    camera.viewport.add(joystick);
    world.add(hero);

    // ---- Camera ----
    camera.setBounds(Rectangle.fromLTRB(0, 0, tiled.size.x, tiled.size.y));
    camera.follow(hero);
  }

  @override
  void update(double dt) {
    // 游戏逻辑，每帧更新
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // 渲染逻辑
    super.render(canvas);
  }
}
