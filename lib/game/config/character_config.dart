import 'package:flame/components.dart';
import 'package:myhero/game/state/attack_type.dart';
import '../attack/spec/animation_spec.dart';
import '../attack/spec/attack_spec.dart';
import '../state/character_state.dart';
import '../attack/spec/hit_box_spec.dart';
import 'bullet_config.dart';

enum CharacterRace { hero, orc, human, boss }

class CharacterConfig {
  final String id;
  final CharacterRace race;
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
    required this.race,
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
  static Map<String, CharacterConfig> byRace(CharacterRace race) =>
      _raceConfigs[race] ?? const {};
  static List<CharacterConfig> listByRace(CharacterRace race) =>
      (_raceConfigs[race]?.values.toList()) ?? const [];

  static String get randomMonsterId {
    final monsters = _characterConfigs.values
        .where((c) => c.race != CharacterRace.hero)
        .toList();
    if (monsters.isEmpty) return 'elite_orc'; // Fallback
    return monsters[DateTime.now().millisecond % monsters.length].id;
  }
}

final Map<String, CharacterConfig> _characterConfigs = {
  'hero_default': CharacterConfig(
    id: 'hero_default',
    race: CharacterRace.hero,
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
        sizeRel: Vector2(1, 1),
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
    race: CharacterRace.hero,
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
    race: CharacterRace.human,
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
    race: CharacterRace.orc,
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
    race: CharacterRace.orc,
    spritePath: 'character/Elite Orc.png',
    cellSize: Vector2(100, 100),
    componentSize: Vector2(300, 300),
    maxHp: 30,
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
    race: CharacterRace.orc,
    spritePath: 'character/Orc rider.png',
    cellSize: Vector2(100, 100),
    componentSize: Vector2(300, 300),
    maxHp: 40,
    attackValue: 1,
    speed: 100,
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
    race: CharacterRace.orc,
    spritePath: 'character/Orc.png',
    cellSize: Vector2(100, 100),
    componentSize: Vector2(300, 300),
    maxHp: 10,
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
  'stone_boss': CharacterConfig(
    id: 'boss',
    race: CharacterRace.orc,
    spritePath: 'character/Stone Boss.png',
    cellSize: Vector2(100, 100),
    componentSize: Vector2(300, 300),
    maxHp: 100,
    attackValue: 5,
    speed: 100,
    detectRadius: 1000,
    attackRange: 1000,
    hitbox: HitboxSpec(
      sizeRel: Vector2(0.0625, 0.05),
      posRel: Vector2(0.475, 0.525),
    ),
    animations: {
      CharacterState.idle: const AnimationSpec(
        row: 1,
        stepTime: 0.15,
        from: 0,
        to: 8,
        loop: true,
      ),
      CharacterState.run: const AnimationSpec(
        row: 0,
        stepTime: 0.10,
        from: 0,
        to: 4,
        loop: true,
      ),
      CharacterState.hurt: const AnimationSpec(
        row: 1,
        stepTime: 0.05,
        from: 0,
        to: 4,
        loop: false,
      ),
      CharacterState.dead: const AnimationSpec(
        row: 9,
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
        duration: 0.4,
        type: AttackType.melee,
        sizeRel: Vector2(0.5, 0.5),
        centerOffsetRel: Vector2(0, -0.25),
        icon: 'button/sword.png',
        animation: const AnimationSpec(
          row: 4,
          stepTime: 0.1,
          from: 0,
          to: 7,
          loop: false,
        ),
      ),
      AttackSpec(
        id: 'stone_ball',
        damage: 3,
        duration: 3,
        type: AttackType.ranged,
        sizeRel: Vector2(1, 1),
        centerOffsetRel: Vector2(0, 0),
        bullet: BulletConfig.byId('stone_ball'),
        icon: 'button/fire.png',
        animation: AnimationSpec(
          row: 2,
          stepTime: 0.05,
          from: 0,
          to: 9,
          loop: false,
        ),
      ),
    ],
  ),
};

final Map<CharacterRace, Map<String, CharacterConfig>> _raceConfigs = (() {
  final map = <CharacterRace, Map<String, CharacterConfig>>{
    CharacterRace.hero: {},
    CharacterRace.orc: {},
    CharacterRace.human: {},
  };
  _characterConfigs.forEach((id, cfg) {
    (map[cfg.race] ??= {})[id] = cfg;
  });
  return map;
})();
