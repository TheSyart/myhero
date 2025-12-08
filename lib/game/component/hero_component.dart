import 'package:myhero/game/my_game.dart';
import 'package:flame/sprite.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../state/hero_state.dart';
import 'wall_component.dart';

class HeroComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  HeroComponent() : super(size: Vector2(32, 32), anchor: Anchor.center);

  // 每秒移动速度
  double speed = 160;

  // 动画状态机
  HeroState state = HeroState.idle;
  late Map<HeroState, SpriteAnimation> animations;

  // 朝向
  bool facingRight = true;

  // 保留这个用于性能优化
  final Set<WallComponent> _nearbyWalls = {};
  late RectangleHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    await _loadAnimations();
    animation = animations[HeroState.idle];

    size = Vector2(100, 100);
    position = Vector2(1000, 1000);

    _hitbox = RectangleHitbox();
    add(_hitbox);
  }

  @override
  void onMount() {
    super.onMount();
    game.camera.follow(this);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final joy = game.joystick;

    if (joy.direction == JoystickDirection.idle) {
      _setState(HeroState.idle);
      return;
    }

    _setState(HeroState.run);

    final movement = joy.relativeDelta * speed * dt;
    final originalPosition = position.clone();

    // 先尝试完整移动
    position += movement;

    // 检测碰撞
    if (_wouldCollideWithWalls()) {
      position.setFrom(originalPosition);

      // X 轴滑动
      position.x += movement.x;
      if (_wouldCollideWithWalls()) {
        position.x = originalPosition.x;
      }

      // Y 轴滑动
      position.y += movement.y;
      if (_wouldCollideWithWalls()) {
        position.y = originalPosition.y;
      }
    }

    if (joy.relativeDelta.x > 0) {
      _faceRight();
    } else if (joy.relativeDelta.x < 0) {
      _faceLeft();
    }
  }

  bool _wouldCollideWithWalls() {
    final heroRect = _hitbox.toAbsoluteRect();

    // 优先使用游戏维护的墙体集合，避免依赖碰撞回调的延迟
    for (final wall in game.walls) {
      final wallHitboxes = wall.children.query<RectangleHitbox>();
      if (wallHitboxes.isEmpty) continue;

      final wallRect = wallHitboxes.first.toAbsoluteRect();
      if (heroRect.overlaps(wallRect)) return true;
    }

    // 兼容：如果 game.walls 为空，退回使用附近墙体集合
    if (game.walls.isEmpty) {
      for (final wall in _nearbyWalls) {
        final wallHitboxes = wall.children.query<RectangleHitbox>();
        if (wallHitboxes.isEmpty) continue;
        final wallRect = wallHitboxes.first.toAbsoluteRect();
        if (heroRect.overlaps(wallRect)) return true;
      }
    }

    return false;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is WallComponent) {
      _nearbyWalls.add(other);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is WallComponent) {
      _nearbyWalls.remove(other);
    }
  }

  // ----------------- 动画状态切换 -----------------
  void _setState(HeroState newState) {
    if (state == newState) return;
    state = newState;
    animation = animations[state]!;
  }

  // ----------------- 翻转控制 -----------------
  void _faceRight() {
    if (!facingRight) {
      flipHorizontally();
      facingRight = true;
    }
  }

  void _faceLeft() {
    if (facingRight) {
      flipHorizontally();
      facingRight = false;
    }
  }

  // ----------------- 加载动画 -----------------
  Future<void> _loadAnimations() async {
    final image = await game.images.load('SPRITE_SHEET.png');
    final sheet = SpriteSheet(image: image, srcSize: Vector2(32, 32));

    animations = {
      HeroState.idle: sheet.createAnimation(
        row: 0,
        stepTime: 0.15,
        from: 0,
        to: 6,
        loop: true,
      ),
      HeroState.run: sheet.createAnimation(
        row: 1,
        stepTime: 0.10,
        from: 0,
        to: 8,
        loop: true,
      ),
    };
  }
}
