import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import '../../character/hero_component.dart';
import 'package:myhero/game/my_game.dart';
import 'dart:math';
import 'dart:ui' as ui;

class WeaponButton extends SpriteButtonComponent with HasGameReference<MyGame> {
  final HeroComponent hero;
  final String iconName;

  WeaponButton({
    required this.hero,
    required String icon,
    required VoidCallback onPressed,
  }) : iconName = icon,
       super(
         onPressed: onPressed,
         size: Vector2.all(72),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 创建一个透明的 button sprite 以满足 SpriteButtonComponent 的断言要求
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    button = Sprite(image);
    
    if (iconName.isEmpty) return;

    // 加载武器图标并按比例缩放
    final sprite = await game.loadSprite(iconName);
    final srcSize = sprite.srcSize;
    
    // 目标显示大小（留出边距）
    const targetSize = 48.0;
    
    // 计算缩放比例，保持长宽比
    final scale = min(targetSize / srcSize.x, targetSize / srcSize.y);
    
    final newSize = srcSize * scale;
    
    add(SpriteComponent(
      sprite: sprite,
      size: newSize,
      position: size / 2,
      anchor: Anchor.center,
    ));

    // 添加外部圆圈
    add(
      CircleComponent(
        radius: 36,
        position: size / 2,
        anchor: Anchor.center,
        paint: Paint()
          ..color = Colors.white38
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    final path = Path()..addOval(size.toRect());
    canvas.clipPath(path);
    // 不调用 super.render(canvas) 避免绘制拉伸的背景图
    // super.render(canvas); 
    // 但我们需要确保子组件被绘制。SpriteButtonComponent 是 Component，render 默认会绘制 children 吗？
    // SpriteButtonComponent extends PositionComponent. 
    // PositionComponent.render draws children? No, PositionComponent.render does nothing by default (except debug).
    // But Component.renderTree does.
    // Wait, if I override render and don't call super.render, children might not be rendered if super.render was responsible for them?
    // No, renderTree calls render and then renders children.
    // So overriding render only affects this component's own drawing.
    // However, SpriteButtonComponent.render draws the button sprite.
    // If I comment out super.render(canvas), the button sprite won't draw (which is good because I didn't set it).
    // But I should verify if I need to do anything else.
    // Actually, if I don't set `button`, `super.render` might do nothing anyway.
    // Let's keep it simple.
    
    super.render(canvas);
    canvas.restore();
  }
}
