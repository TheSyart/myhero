import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:myhero/component/dialog_component.dart';
import 'package:myhero/game/character/character_component.dart';
import '../state/character_state.dart';
import '../../manager/audio_manager.dart';
import '../interaction/interactable.dart';

class HeroComponent extends CharacterComponent {
  final String heroId;
  final Vector2? birthPosition;

    Interactable? current;


  HeroComponent({this.heroId = 'hero_default', this.birthPosition})
    : super(characterId: heroId);


  void setInteractable(Interactable? obj) {
    current = obj;
  }

  void interact() {
    current?.onInteract(this);
  }

  // ----------------- 钥匙 -----------------
  final Set<String> keys = {};
  int coins = 0;

  void addCoin(int amount) {
    coins += amount;
  }

  void addKey(String keyId) {
    keys.add(keyId);
    UiNotify.showToast(game, '获得钥匙: $keyId');
  }

  bool hasKey(String keyId) => keys.contains(keyId);

  // ----------------- 生命周期 -----------------
  @override
  Future<void> onLoad() async {
    await loadAnimations(
      cfg.animations.map(
        (key, value) => MapEntry(key as CharacterState, value),
      ),
    );

    state = CharacterState.idle;
    animation = animations[state];

    position = birthPosition ?? size / 2;

    hitbox = RectangleHitbox.relative(
      cfg.hitbox.sizeRel,
      parentSize: size,
      position: Vector2(
        size.x * cfg.hitbox.posRel.x,
        size.y * cfg.hitbox.posRel.y,
      ),
    );

    add(hitbox);
  }

  @override
  void onMount() {
    super.onMount();
    if (!isGenerate) {
      game.camera.follow(this);
    }
  }

  // ----------------- Update（只处理玩家输入） -----------------
  @override
  void update(double dt) {
    super.update(dt);

    if (isActionLocked) return;

    if (isGenerate) {
      updateSummonAI(dt);
      return;
    }

    final joy = game.joystick;
    if (joy.direction == JoystickDirection.idle) {
      setState(CharacterState.idle);
      // 如果没有输入，武器保持当前角度或归位（可选）
      return;
    }

    setState(CharacterState.run);

    final delta = joy.relativeDelta * speed * dt;

    moveWithCollision(delta);

    if (weapon?.enemyTarget == null) {
      joy.relativeDelta.x > 0 ? faceRight() : faceLeft();

      // 更新武器旋转
      if (weapon != null && !joy.delta.isZero()) {
        // 计算摇杆角度 (0为右，PI/2为下)
        final angle = joy.delta.screenAngle();
        weapon!.rotateByInput(angle);
      }
    }
  }

  // ----------------- 受击 -----------------
  @override
  void loseHp(int amount) {
    super.loseHp(amount);
    if (isDead) return;
    AudioManager.playHurt();

    setState(CharacterState.hurt);
    animationTicker?.onComplete = () {
      if (!isDead) {
        setState(CharacterState.idle);
      }
    };
  }

  // ----------------- 死亡 -----------------
  @override
  void onDead() {
    setState(CharacterState.dead);

    animationTicker?.onComplete = () {
      removeFromParent();

      if (isGenerate) return;
      final exists = game.camera.viewport.children
          .query<RestartOverlay>()
          .isNotEmpty;
      if (!exists) {
        game.camera.viewport.add(RestartOverlay());
      }
    };
  }
}
