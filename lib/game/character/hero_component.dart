import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:myhero/component/dialog_component.dart';
import 'package:myhero/game/character/character_component.dart';
import '../state/character_state.dart';
import '../../manager/audio_manager.dart';

class HeroComponent extends CharacterComponent {
  final String heroId;
  final Vector2? birthPosition;

  HeroComponent({this.heroId = 'hero_default', this.birthPosition}) : super(characterId: heroId);

  // ----------------- 钥匙 -----------------
  final Set<String> keys = {};
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

    position = birthPosition ?? Vector2(1000, 1000);

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
      return;
    }

    setState(CharacterState.run);

    final delta = joy.relativeDelta * speed * dt;

    moveWithCollision(delta);

    joy.relativeDelta.x > 0 ? faceRight() : faceLeft();
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
