import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 交互提示组件：在可交互物体上方显示一个向下的箭头与提示文字，
/// 并通过正弦曲线实现小幅度上下浮动的动效。
class InteractionPromptComponent extends PositionComponent {
  /// 提示文本内容（例如“宝箱”、“按下交互键”等）
  final String text;

  /// 箭头的上下浮动振幅（像素）
  final double amplitude;

  /// 箭头浮动的周期（秒）
  final double period;

  /// 箭头与文字的整体基准偏移（相对于父组件，负值为向上）
  final double baseYOffset;

  /// 文字与箭头之间的间距（像素）
  final double labelGap;

  /// 文字字号
  final double fontSize;

  /// 向下箭头的精灵组件
  late final SpriteComponent _arrow;

  /// 提示文字组件
  TextComponent? _label;

  /// 已累计的动画时间（秒）
  double _elapsed = 0;

  /// 构造函数：
  /// - [text] 提示文案
  /// - [amplitude] 箭头浮动的振幅（像素）
  /// - [period] 箭头浮动的周期（秒）
  /// - [baseYOffset] 箭头与文字整体的基准偏移（负值向上）
  /// - [labelGap] 文本与箭头之间的间距（像素）
  /// - [fontSize] 文本字号
  InteractionPromptComponent({
    required this.text,
    this.amplitude = 4.0,
    this.period = 1.0,
    this.baseYOffset = -8.0,
    this.labelGap = 10.0,
    this.fontSize = 15.0,
  });

  @override
  /// 组件加载：读取箭头精灵、创建文字并设置锚点与初始位置
  Future<void> onLoad() async {
    await super.onLoad();
    final sprite = await Sprite.load('ui/Chevron-Arrow-Down.png');
    _arrow = SpriteComponent(
      sprite: sprite,
      anchor: Anchor.bottomCenter,
    );
    _arrow.position = Vector2(0, baseYOffset);
    add(_arrow);
    final textRenderer = TextPaint(
      style: TextStyle(fontSize: fontSize, color: Colors.white),
    );
    _label = TextComponent(text: text, textRenderer: textRenderer)
      ..anchor = Anchor.bottomCenter
      ..position = Vector2(0, baseYOffset - labelGap - 2.0);
    add(_label!);
  }

  @override
  /// 每帧更新：根据正弦函数计算箭头的位移，实现上下浮动效果
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final omega = 2 * math.pi / period;
    final offset = math.sin(_elapsed * omega) * amplitude;
    _arrow.position = Vector2(0, baseYOffset + offset);
  }
}
