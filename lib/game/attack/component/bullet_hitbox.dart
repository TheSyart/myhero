import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import 'package:myhero/game/config/bullet_config.dart';
import 'package:myhero/game/attack/component/abstract_attack_rect.dart';
import '../../../manager/audio_manager.dart';
import 'dart:ui' as ui;

/// 远程投射物攻击组件 (Bullet Hitbox)
///
/// 核心功能：
/// 1. **直线弹道运动**：
///    - 基于 [direction] 和 [config.speed] 进行每帧位移。
///    - 记录飞行距离 [_distanceTraveled]，超过射程 [config.maxRange] 自动销毁。
/// 2. **智能索敌与方向锁定**：
///    - [onLockTargetFound]：发射时若检测到敌人，自动锁定方向朝向敌人。
///    - [onNoTargetFound]：若无敌人，优先使用摇杆方向，否则保持初始方向。
///    - [_locked] 机制：确保子弹一旦发射，方向即被锁定，不会随玩家后续操作改变轨迹。
/// 3. **视觉表现**：
///    - 支持静态贴图或帧动画 ([SpriteAnimationComponent])。
///    - 发射时播放音效 ([AudioManager.playLaserGun])。
/// 4. **碰撞特性**：
///    - 使用 [RectangleHitbox] 并设为 [CollisionType.active] 主动检测碰撞。
///    - 支持穿透属性 ([config.penetrate])，决定命中后是否立即销毁。
///
/// 适用场景：
/// - 弓箭、魔法球、枪械子弹等远程攻击。
/// - 需要直线飞行且射程受限的投射物。
class BulletHitbox extends AbstractAttackRect {
  final BulletConfig config;
  Vector2 direction;

  double _distanceTraveled = 0;
  bool _locked = false;

  BulletHitbox({
    required this.config,
    required this.direction,
    required PositionComponent owner,
    required Type targetType,
    required int damage,
    required Vector2 position,
  }) : super(
         owner: owner,
         position: position,
         size: config.size,
         damage: damage,
         targetType: targetType,
         duration: config.maxRange / config.speed,
         removeOnHit: !config.penetrate,
         anchor: Anchor.center,
       ) {
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  @override
  ui.Rect getAttackRect() => ui.Rect.fromLTWH(
    position.x - size.x / 2,
    position.y - size.y / 2,
    size.x,
    size.y,
  );

  @override
  void onLockTargetFound(PositionComponent target) {
    // 设置从人物到最近敌人的直线方向
    final Vector2 origin = position.clone();
    final Vector2 targetPos = target.position.clone();
    direction = (targetPos - origin).normalized();
    _locked = true;
  }

  @override
  void onNoTargetFound() {
    // 子弹攻击：若无目标，且尚未锁定方向，则尝试使用摇杆方向
    // 如果摇杆也无输入，保持初始 direction
    if (!_locked && !game.joystick.delta.isZero()) {
      direction = game.joystick.delta.normalized();
    }
    // 无论是否使用了摇杆方向，只要进入这里（说明没找到敌人），就锁定方向。
    // 防止后续飞行中因为摇杆变动而改变方向。
    _locked = true;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // 加载子弹音效
    AudioManager.playLaserGun();

    if (config.spritePath != null) {
      final image = await game.images.load(config.spritePath!);

      if (config.animation != null) {
        final sheet = SpriteSheet(
          image: image,
          srcSize: config.textureSize ?? config.size,
        );
        final anim = sheet.createAnimation(
          row: config.animation!.row,
          stepTime: config.animation!.stepTime,
          from: config.animation!.from,
          to: config.animation!.to,
          loop: config.animation!.loop,
        );
        add(SpriteAnimationComponent(animation: anim, size: size));
      } else {
        final sprite = Sprite(image);
        add(SpriteComponent(sprite: sprite, size: size));
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_locked) {
      autoLockNearestTarget();
    }
    final moveStep = direction * config.speed * dt;
    position += moveStep;
    _distanceTraveled += moveStep.length;

    if (_distanceTraveled >= config.maxRange) {
      removeFromParent();
    }
  }

  // Collision handled by AbstractAttackRect
}
