import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:myhero/game/state/character_state.dart';
import 'package:myhero/game/character/character_component.dart';
import 'package:myhero/game/hud/heart/monster_hp_bar_component.dart';
import 'package:myhero/utils/ai_util.dart';

class MonsterComponent extends CharacterComponent {
  final Vector2 birthPosition;
  final String monsterId;
  late MonsterHpBarComponent hpBar;
  final math.Random rng = math.Random();
  double wanderCooldown = 0;
  double wanderDuration = 0;
  Vector2 wanderDir = Vector2.zero();

  MonsterComponent(this.birthPosition, this.monsterId)
    : super(characterId: monsterId);

  // ----------------- AI 参数 -----------------
  late final double detectRadius = cfg.detectRadius; // 发现主角距离
  late final double attackRange = cfg.attackRange; // 攻击距离

  // ----------------- 生命周期 -----------------
  @override
  Future<void> onLoad() async {
    // 加载动画
    await loadAnimations(
      cfg.animations.map(
        (key, value) => MapEntry(key as CharacterState, value),
      ),
    );

    // 加载血条
    hpBar = MonsterHpBarComponent(
      maxHp: maxHp,
      currentHp: hp,
      barSize: Vector2(size.x * 0.5, 6),
      position: Vector2(size.x / 2, size.y / 4), // 头顶
    );
    add(hpBar);

    // 初始化状态
    state = CharacterState.idle;
    animation = animations[state];

    position = birthPosition;

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

  // ----------------- Update（简单AI） -----------------
  @override
  void update(double dt) {
    super.update(dt);

    // 更新血条
    hpBar.updateHp(hp);

    // 召唤物AI
    if (isGenerate) {
      updateSummonAI(dt);
      return;
    }
    
    // 怪物AI
    AiUtil.updateMonsterAI(this, dt);
  }

  // ----------------- 受击 -----------------
  @override
  void loseHp(int amount) {
    super.loseHp(amount);
    if (isDead) return;
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
    };
  }
}
