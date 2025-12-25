import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import 'package:myhero/game/attack/spec/animation_spec.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/component/door_component.dart';
import 'package:myhero/game/config/character_config.dart';
import 'package:myhero/utils/ai_util.dart';
import 'package:myhero/utils/physics_util.dart';
import '../state/character_state.dart';
import '../attack/factory/attack_hitbox_factory.dart';
import '../attack/factory/generate_factory.dart';
import '../state/attack_type.dart';
import '../weapon/component/weapon_component.dart';
import 'dart:ui';

abstract class CharacterComponent extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameReference<MyGame> {
  final CharacterConfig cfg;
  late SpriteSheet sheet;

  CharacterComponent({required String characterId, Vector2? size})
    : cfg = CharacterConfig.byId(characterId)!,
      super(
        size: size ?? CharacterConfig.byId(characterId)!.componentSize,
        anchor: Anchor.center,
      );

  // --------- 基础属性 ---------
  late final int maxHp = cfg.maxHp;
  late final int attackValue = cfg.attackValue;
  late final double speed = cfg.speed;
  late int hp = maxHp;

  bool facingRight = true;
  bool isDead = false;
  bool isGenerate = false;
  PositionComponent? summonOwner;
  double followDistance = 150;

  // --------- 武器 ---------
  WeaponComponent? weapon;

  // ----------------- 召唤物AI逻辑 -----------------
  /// 更新召唤物AI行为
  /// 包含：寻找敌人、攻击、跟随主人、待机
  ///
  /// [dt] 帧间隔时间
  void updateSummonAI(double dt) {
    AiUtil.updateSummonAI(this, dt);
  }

  late RectangleHitbox hitbox;

  // --------- 状态机 ---------
  late CharacterState state;
  late Map<CharacterState, SpriteAnimation> animations;

  // ----------------- 状态锁 -----------------
  bool get isActionLocked =>
      state == CharacterState.attack ||
      state == CharacterState.dead ||
      state == CharacterState.hurt;

  @override
  void update(double dt) {
    super.update(dt);
    resolveOverlaps(dt);
    // 优先处理召唤物AI
    if (isGenerate) {
      updateSummonAI(dt);
      return;
    }
  }

  // ----------------- 碰撞纠正 -----------------
  Vector2? lastCorrection;

  void resolveOverlaps(double dt) {
    PhysicsUtil.resolveOverlaps(this, dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (debugMode && lastCorrection != null && !lastCorrection!.isZero()) {
      final paint = Paint()
        ..color = const Color(0xFFFF0000)
        ..strokeWidth = 2;
      final centerOffset = size / 2;
      final end = centerOffset + lastCorrection! * 20;
      canvas.drawLine(centerOffset.toOffset(), end.toOffset(), paint);
    }
  }

  // ----------------- 武器系统 -----------------
  /// 装备武器
  void equipWeapon(String weaponId) {
    // 移除旧武器
    weapon?.removeFromParent();

    weapon = WeaponComponent(weaponId: weaponId, owner: this);
    // 设置武器在人物合适位置
    weapon!.position = Vector2(size.x / 3, size.y / 1.5);
    add(weapon!);
  }

  // ----------------- 攻击 -----------------
  void attack(int index, Type target) {
    if (isActionLocked) return;

    final spec = cfg.attack[index];
    playAttackAnimation(spec.animation);

    // 生成召唤物
    // TODO: 待优化
    if (spec.type == AttackType.generate) {
      final count = spec.generateCount ?? 3;
      final radius = spec.generateRadius ?? 150;
      final center =
          position.clone() +
          Vector2(
            size.x * spec.centerOffsetRel.x,
            size.y * spec.centerOffsetRel.y,
          );

      final enemy = this is HeroComponent ? MonsterComponent : HeroComponent;

      GenerateFactory.spawnCircleToWorld(
        game: game,
        center: center,
        generateId: spec.generateId ?? cfg.id,
        owner: this,
        enemyType: enemy,
        count: count,
        radius: radius,
        followDistance: radius * 0.8,
      );
      return;
    }

    // 攻击矩形工厂
    final box = AttackHitboxFactory.create(
      spec: spec,
      owner: this,
      targetType: target,
      facingRight: facingRight,
    );
    box.debugMode = true;
    game.world.add(box);
  }

  // --------- 生命逻辑 ---------
  void loseHp(int amount) {
    if (isDead) return;

    hp -= amount;
    if (hp <= 0) {
      hp = 0;
      isDead = true;
      onDead();
    }
  }

  void onDead();

  // --------- 状态切换 ---------
  void setState(CharacterState newState) {
    if (state == newState) return;
    state = newState;
    animation = animations[state]!;
  }

  // --------- 朝向 ---------
  void faceRight() {
    if (!facingRight) {
      flipHorizontally();
      facingRight = true;
    }
  }

  void faceLeft() {
    if (facingRight) {
      flipHorizontally();
      facingRight = false;
    }
  }

  bool collidesWith(Rect heroRect) {
    return hitbox.toAbsoluteRect().overlaps(heroRect);
  }

  // ----------------- 动画 -----------------
  Future<void> loadAnimations(
    Map<CharacterState, AnimationSpec> stateToSpec,
  ) async {
    final image = await game.images.load(cfg.spritePath);
    sheet = SpriteSheet(image: image, srcSize: cfg.cellSize);

    animations = stateToSpec.map((state, spec) {
      return MapEntry(
        state,
        sheet.createAnimation(
          row: spec.row,
          stepTime: spec.stepTime,
          from: spec.from,
          to: spec.to,
          loop: spec.loop,
        ),
      );
    });
  }

  void playAttackAnimation(AnimationSpec? anim) {
    if (anim != null) {
      state = CharacterState.attack;
      animation = sheet.createAnimation(
        row: anim.row,
        stepTime: anim.stepTime,
        from: anim.from,
        to: anim.to,
        loop: anim.loop,
      );
    }
    animationTicker?.onComplete = () {
      setState(CharacterState.idle);
    };
  }

  // --------- 移动 ---------
  /// 移动并处理碰撞
  ///
  /// [delta] 移动向量
  /// [willCollide] 碰撞检测函数，返回是否会碰撞
  void moveWithCollision(Vector2 delta) {
    final original = position.clone();

    position += delta;
    if (!_willCollide(hitbox.toAbsoluteRect())) return;

    // 回退
    position.setFrom(original);

    // X 轴滑动
    position.x += delta.x;
    if (_willCollide(hitbox.toAbsoluteRect())) {
      position.x = original.x;
    }

    // Y 轴滑动
    position.y += delta.y;
    if (_willCollide(hitbox.toAbsoluteRect())) {
      position.y = original.y;
    }
  }

  // ----------------- 碰撞判断 -----------------
  bool _willCollide(Rect rect) {
    for (final blocker in game.blockers) {
      if (blocker.collidesWith(rect)) {
        return true;
      }
    }

    for (final door in game.world.children.query<DoorComponent>()) {
      if (!door.isOpen && door.collidesWith(rect) && !isGenerate) {
        door.attemptOpen(this);
        if (!door.isOpen) return true;
      }
    }

    for (final character in game.world.children.query<CharacterComponent>()) {
      if (character != this && character.collidesWith(rect)) {
        return true;
      }
    }

    return false;
  }
}
