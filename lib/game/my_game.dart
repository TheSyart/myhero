import 'package:flame/game.dart';
import 'component/hero_component.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';

class MyGame extends FlameGame {
  late JoystickComponent joystick;
  late HeroComponent hero;

  @override
  Future<void> onLoad() async {
    // 加载游戏资源
    super.onLoad();

    // 1. 创建摇杆
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: Paint()..color = Colors.white70),
      background: CircleComponent(
        radius: 80,
        paint: Paint()..color = Colors.black87,
      ),
      margin: const EdgeInsets.only(left: 50, bottom: 50),
    );

    // 2. 创建英雄
    hero = HeroComponent();

    // 3. 添加进入场景
    add(joystick);
    add(hero);
    add(HeroComponent());
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
