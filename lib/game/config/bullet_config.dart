import 'package:flame/components.dart';
import '../attack/spec/animation_spec.dart';

/// 子弹配置
/// speed 子弹速度
/// maxRange 最大射程
/// size 子弹大小
/// textureSize 子弹纹理大小
/// spritePath 子弹精灵路径
/// animation 子弹动画配置
/// penetrate 是否穿透
/// sizeRel 子弹大小相对值
/// centerOffsetRel 子弹中心偏移相对值

class BulletConfig {
  final double speed;
  final double maxRange;
  final Vector2 size;
  final Vector2? textureSize;
  final String? spritePath;
  final AnimationSpec? animation;
  final bool penetrate;
  final Vector2 sizeRel;
  final Vector2 centerOffsetRel;

  BulletConfig({
    required this.speed,
    required this.maxRange,
    required this.size,
    this.textureSize,
    this.spritePath,
    this.animation,
    this.penetrate = false,
    Vector2? sizeRel,
    Vector2? centerOffsetRel,
  }) : sizeRel = sizeRel ?? Vector2.all(0.5),
       centerOffsetRel = centerOffsetRel ?? Vector2(0.5, 0.5);

  static BulletConfig? byId(String id) => bulletConfigs[id];
}

final Map<String, BulletConfig> bulletConfigs = {
  'fire_ball': BulletConfig(
    speed: 500,
    maxRange: 400,
    size: Vector2(64, 64),
    textureSize: Vector2(16, 16),
    spritePath: 'bullet/fire_ball.png',
    animation: AnimationSpec(
      row: 0,
      stepTime: 0.1,
      from: 0,
      to: 30,
      loop: true,
    ),
  ),
  'bullet': BulletConfig(
    speed: 500,
    maxRange: 400,
    size: Vector2(32, 32),
    textureSize: Vector2(16, 16),
    spritePath: 'bullet/bullet.png',
    animation: AnimationSpec(row: 0, stepTime: 0.1, from: 0, to: 1, loop: true),
  ),
  'm20_rocket': BulletConfig(
    speed: 500,
    maxRange: 400,
    size: Vector2(64, 64),
    textureSize: Vector2(16, 16),
    spritePath: 'bullet/m20_rocket.png',
    animation: AnimationSpec(
      row: 0,
      stepTime: 0.1,
      from: 0,
      to: 30,
      loop: true,
    ),
  ),
  'stone_ball': BulletConfig(
    speed: 200,
    maxRange: 1000,
    size: Vector2(300, 300),
    textureSize: Vector2(100, 100),
    sizeRel: Vector2(0.4, 0.15),
    centerOffsetRel: Vector2(0.8, 0.38),
    spritePath: 'bullet/stone_ball.png',
    animation: AnimationSpec(row: 0, stepTime: 0.1, from: 0, to: 3, loop: true),
  ),
};
