import 'package:flame/components.dart';
import 'package:myhero/game/state/attack_type.dart';
import '../attack/spec/animation_spec.dart';
import '../attack/spec/attack_spec.dart';
import '../state/character_state.dart';
import '../attack/spec/hit_box_spec.dart';
import 'bullet_config.dart';

/// 角色配置
/// id 角色id
/// spritePath 角色sprite路径
/// cellSize 角色sprite单元格大小
/// componentSize 角色组件大小
/// maxHp 最大生命值
/// attackValue 攻击值
/// speed 移动速度
/// detectRadius 检测半径
/// attackRange 攻击范围
/// hitbox 人物体型碰撞框
/// animations 动画
/// attack 攻击列表
class CharacterConfig {
  final String id;
  final String spritePath;
  final Vector2 cellSize;
  final Vector2 componentSize;
  final int maxHp;
  final int attackValue;
  final double speed;
  final double detectRadius;
  final double attackRange;
  final HitboxSpec hitbox;
  final Map<Object, AnimationSpec> animations;
  final List<AttackSpec> attack;

  const CharacterConfig({
    required this.id,
    required this.spritePath,
    required this.cellSize,
    required this.componentSize,
    required this.maxHp,
    required this.attackValue,
    required this.speed,
    this.detectRadius = 500,
    this.attackRange = 60,
    required this.hitbox,
    required this.animations,
    required this.attack,
  });

  static CharacterConfig? byId(String id) => _characterConfigs[id];
}

final Map<String, CharacterConfig> _characterConfigs = {
  'hero_default': CharacterConfig(
    id: 'hero_default',
    spritePath: 'character/Satyr.png',
    cellSize: Vector2(32, 32),
    componentSize: Vector2(100, 100),
    maxHp: 20,
    attackValue: 1,
    speed: 160,
    hitbox: HitboxSpec(
      sizeRel: Vector2(0.25, 0.2),
      posRel: Vector2(0.425, 0.7),
    ),
    animations: {
      CharacterState.idle: const AnimationSpec(
        row: 0,
        stepTime: 0.15,
        from: 0,
        to: 6,
        loop: true,
      ),
      CharacterState.run: const AnimationSpec(
        row: 1,
        stepTime: 0.10,
        from: 0,
        to: 8,
        loop: true,
      ),
      CharacterState.dead: const AnimationSpec(
        row: 6,
        stepTime: 0.10,
        from: 0,
        to: 10,
        loop: false,
      ),
      CharacterState.hurt: const AnimationSpec(
        row: 7,
        stepTime: 0.05,
        from: 0,
        to: 4,
        loop: false,
      ),
    },
    attack: [
      AttackSpec(
        id: 'common',
        damage: 5,
        duration: 0.2,
        type: AttackType.melee,
        sizeRel: Vector2(0.5, 2),
        centerOffsetRel: Vector2(0, -1),
        icon: 'button/sword.png',
        animation: const AnimationSpec(
          row: 3,
          stepTime: 0.03,
          from: 0,
          to: 7,
          loop: false,
        ),
      ),
      AttackSpec(
        id: 'fire_ball',
        damage: 3,
        duration: 3,
        type: AttackType.ranged,
        sizeRel: Vector2(1, 1),
        centerOffsetRel: Vector2(0, 0),
        bullet: BulletConfig.byId('fire_ball'),
        icon: 'button/fire.png',
        animation: AnimationSpec(
          row: 2,
          stepTime: 0.05,
          from: 0,
          to: 4,
          loop: false,
        ),
      ),
      AttackSpec(
        id: 'impact',
        damage: 2,
        duration: 1,
        type: AttackType.dash,
        sizeRel: Vector2(1, 1),
        centerOffsetRel: Vector2(0, 0),
        dashSpeed: 300,
        icon: 'button/impact.png',
        animation: AnimationSpec(
          row: 8,
          stepTime: 0.15,
          from: 0,
          to: 6,
          loop: false,
        ),
      ),
      AttackSpec(
        id: 'generate',
        damage: 0,
        duration: 0,
        type: AttackType.generate,
        sizeRel: Vector2(0, 0),
        centerOffsetRel: Vector2(0, 0),
        icon: 'button/generate.png',
        generateId: 'hero_friend',
        animation: const AnimationSpec(
          row: 4,
          stepTime: 0.15,
          from: 0,
          to: 6,
          loop: false,
        ),
      ),
    ],
  ),
  'hero_friend': CharacterConfig(
    id: 'hero_friend',
    spritePath: 'character/Satyr Friend.png',
    cellSize: Vector2(32, 32),
    componentSize: Vector2(100, 100),
    maxHp: 20,
    attackValue: 1,
    speed: 160,
    hitbox: HitboxSpec(
      sizeRel: Vector2(0.25, 0.2),
      posRel: Vector2(0.425, 0.7),
    ),
    animations: {
      CharacterState.idle: const AnimationSpec(
        row: 2,
        stepTime: 0.15,
        from: 0,
        to: 4,
        loop: true,
      ),
      CharacterState.run: const AnimationSpec(
        row: 3,
        stepTime: 0.10,
        from: 0,
        to: 8,
        loop: true,
      ),
      CharacterState.dead: const AnimationSpec(
        row: 7,
        stepTime: 0.10,
        from: 0,
        to: 8,
        loop: false,
      ),
      CharacterState.hurt: const AnimationSpec(
        row: 6,
        stepTime: 0.1,
        from: 0,
        to: 3,
        loop: false,
      ),
    },
    attack: [
      AttackSpec(
        id: 'common',
        damage: 3,
        duration: 0.2,
        type: AttackType.melee,
        sizeRel: Vector2(0.5, 2),
        centerOffsetRel: Vector2(0, -1),
        icon: 'button/sword.png',
        animation: const AnimationSpec(
          row: 8,
          stepTime: 0.1,
          from: 0,
          to: 8,
          loop: false,
        ),
      ),
    ],
  ),
  'armored_axeman': CharacterConfig(
    id: 'armored_axeman',
    spritePath: 'character/Armored Axeman.png',
    cellSize: Vector2(100, 100),
    componentSize: Vector2(300, 300),
    maxHp: 20,
    attackValue: 1,
    speed: 80,
    hitbox: HitboxSpec(
      sizeRel: Vector2(0.0625, 0.05),
      posRel: Vector2(0.475, 0.525),
    ),
    animations: {
      CharacterState.idle: const AnimationSpec(
        row: 0,
        stepTime: 0.15,
        from: 0,
        to: 6,
        loop: true,
      ),
      CharacterState.run: const AnimationSpec(
        row: 1,
        stepTime: 0.10,
        from: 0,
        to: 8,
        loop: true,
      ),
      CharacterState.hurt: const AnimationSpec(
        row: 5,
        stepTime: 0.05,
        from: 0,
        to: 4,
        loop: false,
      ),
      CharacterState.dead: const AnimationSpec(
        row: 6,
        stepTime: 0.10,
        from: 0,
        to: 4,
        loop: false,
      ),
    },
    attack: [
      AttackSpec(
        id: 'common',
        damage: 1,
        duration: 0.2,
        type: AttackType.melee,
        sizeRel: Vector2(0.25, 0.5),
        centerOffsetRel: Vector2(0, -0.25),
        animation: const AnimationSpec(
          row: 2,
          stepTime: 0.10,
          from: 0,
          to: 9,
          loop: false,
        ),
      ),
    ],
  ),
  'armored_orc': CharacterConfig(
    id: 'armored_orc',
    spritePath: 'character/Armored Orc.png',
    cellSize: Vector2(100, 100),
    componentSize: Vector2(300, 300),
    maxHp: 40,
    attackValue: 1,
    speed: 80,
    hitbox: HitboxSpec(
      sizeRel: Vector2(0.0625, 0.05),
      posRel: Vector2(0.475, 0.525),
    ),
    animations: {
      CharacterState.idle: const AnimationSpec(
        row: 0,
        stepTime: 0.15,
        from: 0,
        to: 6,
        loop: true,
      ),
      CharacterState.run: const AnimationSpec(
        row: 1,
        stepTime: 0.10,
        from: 0,
        to: 8,
        loop: true,
      ),
      CharacterState.hurt: const AnimationSpec(
        row: 6,
        stepTime: 0.05,
        from: 0,
        to: 4,
        loop: false,
      ),
      CharacterState.dead: const AnimationSpec(
        row: 7,
        stepTime: 0.10,
        from: 0,
        to: 4,
        loop: false,
      ),
    },
    attack: [
      AttackSpec(
        id: 'common',
        damage: 2,
        duration: 0.2,
        type: AttackType.melee,
        sizeRel: Vector2(0.25, 0.5),
        centerOffsetRel: Vector2(0, -0.25),
        animation: const AnimationSpec(
          row: 2,
          stepTime: 0.15,
          from: 0,
          to: 7,
          loop: false,
        ),
      ),
    ],
  ),
  'elite_orc': CharacterConfig(
    id: 'elite_orc',
    spritePath: 'character/Elite Orc.png',
    cellSize: Vector2(100, 100),
    componentSize: Vector2(300, 300),
    maxHp: 30,
    attackValue: 1,
    speed: 120,
    hitbox: HitboxSpec(
      sizeRel: Vector2(0.0625, 0.05),
      posRel: Vector2(0.475, 0.525),
    ),
    animations: {
      CharacterState.idle: const AnimationSpec(
        row: 0,
        stepTime: 0.15,
        from: 0,
        to: 6,
        loop: true,
      ),
      CharacterState.run: const AnimationSpec(
        row: 1,
        stepTime: 0.10,
        from: 0,
        to: 8,
        loop: true,
      ),
      CharacterState.hurt: const AnimationSpec(
        row: 5,
        stepTime: 0.05,
        from: 0,
        to: 4,
        loop: false,
      ),
      CharacterState.dead: const AnimationSpec(
        row: 6,
        stepTime: 0.10,
        from: 0,
        to: 4,
        loop: false,
      ),
    },
    attack: [
      AttackSpec(
        id: 'common',
        damage: 2,
        duration: 0.2,
        type: AttackType.melee,
        sizeRel: Vector2(0.25, 0.5),
        centerOffsetRel: Vector2(0, -0.25),
        animation: const AnimationSpec(
          row: 2,
          stepTime: 0.15,
          from: 0,
          to: 7,
          loop: false,
        ),
      ),
    ],
  ),
  'orc_rider': CharacterConfig(
    id: 'orc_rider',
    spritePath: 'character/Orc rider.png',
    cellSize: Vector2(100, 100),
    componentSize: Vector2(300, 300),
    maxHp: 40,
    attackValue: 1,
    speed: 150,
    hitbox: HitboxSpec(
      sizeRel: Vector2(0.0625, 0.05),
      posRel: Vector2(0.475, 0.525),
    ),
    animations: {
      CharacterState.idle: const AnimationSpec(
        row: 0,
        stepTime: 0.15,
        from: 0,
        to: 6,
        loop: true,
      ),
      CharacterState.run: const AnimationSpec(
        row: 1,
        stepTime: 0.10,
        from: 0,
        to: 8,
        loop: true,
      ),
      CharacterState.hurt: const AnimationSpec(
        row: 6,
        stepTime: 0.05,
        from: 0,
        to: 4,
        loop: false,
      ),
      CharacterState.dead: const AnimationSpec(
        row: 7,
        stepTime: 0.10,
        from: 0,
        to: 4,
        loop: false,
      ),
    },
    attack: [
      AttackSpec(
        id: 'common',
        damage: 3,
        duration: 0.2,
        type: AttackType.melee,
        sizeRel: Vector2(0.25, 0.5),
        centerOffsetRel: Vector2(0, -0.25),
        animation: const AnimationSpec(
          row: 2,
          stepTime: 0.15,
          from: 0,
          to: 8,
          loop: false,
        ),
      ),
    ],
  ),
  'orc': CharacterConfig(
    id: 'orc',
    spritePath: 'character/Orc.png',
    cellSize: Vector2(100, 100),
    componentSize: Vector2(300, 300),
    maxHp: 10,
    attackValue: 1,
    speed: 200,
    hitbox: HitboxSpec(
      sizeRel: Vector2(0.0625, 0.05),
      posRel: Vector2(0.475, 0.525),
    ),
    animations: {
      CharacterState.idle: const AnimationSpec(
        row: 0,
        stepTime: 0.15,
        from: 0,
        to: 6,
        loop: true,
      ),
      CharacterState.run: const AnimationSpec(
        row: 1,
        stepTime: 0.10,
        from: 0,
        to: 8,
        loop: true,
      ),
      CharacterState.hurt: const AnimationSpec(
        row: 4,
        stepTime: 0.05,
        from: 0,
        to: 4,
        loop: false,
      ),
      CharacterState.dead: const AnimationSpec(
        row: 5,
        stepTime: 0.10,
        from: 0,
        to: 4,
        loop: false,
      ),
    },
    attack: [
      AttackSpec(
        id: 'common',
        damage: 1,
        duration: 0.2,
        type: AttackType.melee,
        sizeRel: Vector2(0.25, 0.5),
        centerOffsetRel: Vector2(0, -0.25),
        animation: const AnimationSpec(
          row: 2,
          stepTime: 0.15,
          from: 0,
          to: 6,
          loop: false,
        ),
      ),
    ],
  ),
};
