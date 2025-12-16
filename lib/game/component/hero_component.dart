import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/component/door_component.dart';
import 'package:flame/sprite.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../state/hero_state.dart';
import 'wall_component.dart';
import '../../component/dialog_component.dart';
import 'blocker_component.dart';


class HeroComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame>, CollisionCallbacks {
  HeroComponent() : super(size: Vector2(32, 32), anchor: Anchor.center);

  // 每秒移动速度
  double speed = 160;

  // 生命值
  int hp = 5;

  // 是否死亡
  bool _isGameOver = false;

  // 动画状态机
  HeroState state = HeroState.idle;
  late Map<HeroState, SpriteAnimation> animations;

  // 朝向
  bool facingRight = true;

  // 保留这个用于性能优化
  final Set<BlockerComponent> _nearbyBlockers = {};
  late RectangleHitbox _hitbox;

  // 存 keyId
  final Set<String> keys = {};
  void addKey(String keyId) {
    keys.add(keyId);
    UiNotify.showToast(game, '获得钥匙: $keyId');
  }

  bool hasKey(String keyId) => keys.contains(keyId);

  void loseHp(int amount) {
    hp = hp - amount;

    if (hp <= 0) {
      UiNotify.showToast(game, '死亡');
    } else {
      UiNotify.showToast(game, 'HP -$amount  剩余 $hp');
    }
  }

  Future<void> gameOver() async {
    if (_isGameOver) return;
    _isGameOver = true;

    // 播放死亡动画
    if (animations.containsKey(HeroState.dead)) {
      _setState(HeroState.dead);
    }

    // 等待 2 秒，让死亡动画播放
    await Future.delayed(const Duration(seconds: 2));

    // 显示重新开始弹窗
    final exists = game.camera.viewport.children
        .query<RestartOverlay>()
        .isNotEmpty;
    if (!exists) {
      game.camera.viewport.add(RestartOverlay());
    }
  }

  @override
  Future<void> onLoad() async {
    await _loadAnimations();
    animation = animations[HeroState.idle];

    size = Vector2(100, 100);
    position = Vector2(1000, 1000);
    _hitbox = RectangleHitbox.relative(
      Vector2(0.5, 0.2), // 占组件宽高比例
      parentSize: size,
      position: Vector2(size.x * 0.25, size.y * 0.7), // 偏移
    );

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

    if (hp <= 0) {
      gameOver();
      return;
    }

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
    if (_wouldCollideWithBlockers()) {
      position.setFrom(originalPosition);

      // X 轴滑动
      position.x += movement.x;
      if (_wouldCollideWithBlockers()) {
        position.x = originalPosition.x;
      }

      // Y 轴滑动
      position.y += movement.y;
      if (_wouldCollideWithBlockers()) {
        position.y = originalPosition.y;
      }
    }

    if (joy.relativeDelta.x > 0) {
      _faceRight();
    } else if (joy.relativeDelta.x < 0) {
      _faceLeft();
    }
  }

  bool _wouldCollideWithBlockers() {
    final heroRect = _hitbox.toAbsoluteRect();

    // 优先使用游戏维护的 blockers 集合
    for (final blocker in game.blockers) {
      if (blocker.collidesWith(heroRect)) return true;
    }

    // 检测关闭的门
    for (final door in game.world.children.query<DoorComponent>()) {
      if (!door.isOpen && door.collidesWith(heroRect)) {
        door.attemptOpen(this);
        if (!door.isOpen) return true;
      }
    }

    // 兼容附近 blockers
    for (final nearby in _nearbyBlockers) {
      if (nearby.collidesWith(heroRect)) return true;
    }

    return false;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is BlockerComponent) {
      _nearbyBlockers.add(other);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is BlockerComponent) {
      _nearbyBlockers.remove(other);
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
      HeroState.attack: sheet.createAnimation(
        row: 3,
        stepTime: 0.10,
        from: 0,
        to: 7,
        loop: true,
      ),
      HeroState.dead: sheet.createAnimation(
        row: 6,
        stepTime: 0.10,
        from: 0,
        to: 10,
        loop: false,
      ),
    };
  }
}
