import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:myhero/game/attack/component/abstract_attack_rect.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/character/monster_component.dart';

class SectorMeleeHitbox extends AbstractAttackRect {
  static final List<SectorMeleeHitbox> _pool = [];

  double radius;
  double arcAngle; // 弧度
  double facingAngle;
  
  // Enhanced features
  bool enableDamageFalloff;
  double minDamageMultiplier;
  bool enableCriticalHits;
  double criticalHitChance;
  double criticalMultiplier;
  double criticalZoneRatio;

  double _timer = 0;
  final Set<PositionComponent> _localHitTargets = {};

  SectorMeleeHitbox({
    required PositionComponent owner,
    required this.radius,
    required this.arcAngle,
    required int damage,
    required Type targetType,
    this.facingAngle = 0,
    double duration = 0.2,
    this.enableDamageFalloff = false,
    this.minDamageMultiplier = 0.5,
    this.enableCriticalHits = false,
    this.criticalHitChance = 0.0,
    this.criticalMultiplier = 1.5,
    this.criticalZoneRatio = 0.3,
  }) : super(
          owner: owner,
          position: owner.position.clone(),
          size: Vector2.zero(),
          damage: damage,
          targetType: targetType,
          duration: duration,
          removeOnHit: false,
        );

  static SectorMeleeHitbox obtain({
    required PositionComponent owner,
    required double radius,
    required double arcAngle,
    required int damage,
    required Type targetType,
    double facingAngle = 0,
    double duration = 0.2,
    bool enableDamageFalloff = false,
    double minDamageMultiplier = 0.5,
    bool enableCriticalHits = false,
    double criticalHitChance = 0.0,
    double criticalMultiplier = 1.5,
    double criticalZoneRatio = 0.3,
  }) {
    if (_pool.isNotEmpty) {
      final component = _pool.removeLast();
      component.reset(
        owner: owner,
        radius: radius,
        arcAngle: arcAngle,
        damage: damage,
        targetType: targetType,
        facingAngle: facingAngle,
        duration: duration,
        enableDamageFalloff: enableDamageFalloff,
        minDamageMultiplier: minDamageMultiplier,
        enableCriticalHits: enableCriticalHits,
        criticalHitChance: criticalHitChance,
        criticalMultiplier: criticalMultiplier,
        criticalZoneRatio: criticalZoneRatio,
      );
      return component;
    } else {
      return SectorMeleeHitbox(
        owner: owner,
        radius: radius,
        arcAngle: arcAngle,
        damage: damage,
        targetType: targetType,
        facingAngle: facingAngle,
        duration: duration,
        enableDamageFalloff: enableDamageFalloff,
        minDamageMultiplier: minDamageMultiplier,
        enableCriticalHits: enableCriticalHits,
        criticalHitChance: criticalHitChance,
        criticalMultiplier: criticalMultiplier,
        criticalZoneRatio: criticalZoneRatio,
      );
    }
  }

  void reset({
    required PositionComponent owner,
    required double radius,
    required double arcAngle,
    required int damage,
    required Type targetType,
    required double facingAngle,
    required double duration,
    required bool enableDamageFalloff,
    required double minDamageMultiplier,
    required bool enableCriticalHits,
    required double criticalHitChance,
    required double criticalMultiplier,
    required double criticalZoneRatio,
  }) {
    resetBase(
      owner: owner,
      position: owner.position,
      size: Vector2.zero(),
      damage: damage,
      targetType: targetType,
      duration: duration,
      removeOnHit: false,
    );
    this.radius = radius;
    this.arcAngle = arcAngle;
    this.facingAngle = facingAngle;
    this.enableDamageFalloff = enableDamageFalloff;
    this.minDamageMultiplier = minDamageMultiplier;
    this.enableCriticalHits = enableCriticalHits;
    this.criticalHitChance = criticalHitChance;
    this.criticalMultiplier = criticalMultiplier;
    this.criticalZoneRatio = criticalZoneRatio;
    _timer = 0;
    _localHitTargets.clear();
  }

  @override
  void onRemove() {
    super.onRemove();
    _pool.add(this);
  }

  @override
  ui.Rect getAttackRect() => ui.Rect.zero;

  @override
  void onLockTargetFound(PositionComponent target) {}

  @override
  void onNoTargetFound() {}

  @override
  void update(double dt) {
    super.update(dt);

    position.setFrom(owner.position);
    angle = facingAngle;

    _timer += dt;
    if (_timer >= duration) {
      removeFromParent();
      return;
    }

    _checkHits();
  }

  void _checkHits() {
     final targets = targetType == MonsterComponent
         ? game.world.children.query<MonsterComponent>()
         : game.world.children.query<HeroComponent>();
 
     for (final t in targets) {
       if (t == owner) continue;
       
       print('DEBUG: Checking target at ${t.position}, owner at $position, facing $facingAngle');
       final inSector = _isInSector(
         origin: position,
         facingAngle: facingAngle,
         target: t.position,
         radius: radius,
         arcAngle: arcAngle,
       );
       print('DEBUG: InSector: $inSector');

       if (inSector) {
          _applyEnhancedHit(t, position, t.position);
       }
     }
   }

  bool _isInSector({
    required Vector2 origin,
    required double facingAngle,
    required Vector2 target,
    required double radius,
    required double arcAngle,
  }) {
    final toTarget = target - origin;
    if (toTarget.length2 > radius * radius) return false;

    final targetAngle = math.atan2(toTarget.y, toTarget.x);
    double diff = targetAngle - facingAngle;

    while (diff > math.pi) diff -= 2 * math.pi;
    while (diff < -math.pi) diff += 2 * math.pi;

    return diff.abs() <= arcAngle / 2;
  }

  void _applyEnhancedHit(PositionComponent target, Vector2 origin, Vector2 targetPos) {
    if (target == owner) return;
    if (_localHitTargets.contains(target)) return;

    double finalDamage = damage.toDouble();

    if (enableDamageFalloff) {
      final dist = origin.distanceTo(targetPos);
      final t = (dist / radius).clamp(0.0, 1.0);
      final multiplier = 1.0 - t * (1.0 - minDamageMultiplier);
      finalDamage *= multiplier;
    }

    bool isCrit = false;
    if (enableCriticalHits) {
      final dist = origin.distanceTo(targetPos);
      if (dist < radius * criticalZoneRatio) {
        isCrit = true;
      } else if (math.Random().nextDouble() < criticalHitChance) {
        isCrit = true;
      }
    }

    if (isCrit) {
      finalDamage *= criticalMultiplier;
    }

    if (targetType == HeroComponent && target is HeroComponent) {
      target.loseHp(finalDamage.toInt());
      _localHitTargets.add(target);
    } else if (targetType == MonsterComponent && target is MonsterComponent) {
      target.loseHp(finalDamage.toInt());
      _localHitTargets.add(target);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (!debugMode) return;
    super.render(canvas);

    final paint = ui.Paint()
      ..color = const ui.Color(0x55FF0000)
      ..style = ui.PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..arcTo(
        ui.Rect.fromCircle(center: ui.Offset.zero, radius: radius),
        -arcAngle / 2,
        arcAngle,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);
  }
}
