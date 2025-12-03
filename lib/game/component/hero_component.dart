import 'package:myhero/game/my_game.dart';
import 'package:flame/sprite.dart';
import 'package:flame/components.dart';
import '../state/hero_state.dart';

class HeroComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame> {
  HeroComponent() : super(size: Vector2(32, 32), anchor: Anchor.center);

  // 每秒移动速度
  double speed = 160;

  // 动画状态机
  HeroState state = HeroState.idle;
  late Map<HeroState, SpriteAnimation> animations;

  // 朝向
  bool facingRight = true;

  @override
  Future<void> onLoad() async {
    await _loadAnimations();
    animation = animations[HeroState.idle];

    size = Vector2(100, 100);
    position = game.size / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final joy = game.joystick;

    if (joy.direction == JoystickDirection.idle) {
      _setState(HeroState.idle);
      return;
    }

    // 移动逻辑
    _setState(HeroState.run);
    position += joy.relativeDelta * speed * dt;

    // ★ 控制翻转方向（最关键）
    if (joy.relativeDelta.x > 0) {
      _faceRight();
    } else if (joy.relativeDelta.x < 0) {
      _faceLeft();
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
