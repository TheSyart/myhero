import 'package:flame/components.dart';
import 'attack_button.dart';
import '../../character/hero_component.dart';
import '../../character/monster_component.dart';
import 'dart:math' as math;

class AttackHud extends PositionComponent {
  static const buttonSize = 64.0;
  static const buttonSpacing = 8.0;

  late final PositionComponent buttonGroup;
  final HeroComponent hero;

  AttackHud(this.hero)
    : super(
        anchor: Anchor.center, // ✅ HUD 本体的锚点
        priority: 10000, // ✅ UI 永远在最上层
      );

  @override
  Future<void> onLoad() async {
    // ✅ 子组件只做相对布局
    buttonGroup = PositionComponent()
      ..anchor = Anchor.center
      ..position = Vector2.zero();

    final attacks = hero.cfg.attack;
    final count = attacks.length;

    if (count > 0) {
      final radius = buttonSize + 32.0;
      final startDeg = 270.0;
      final endDeg = 180.0;

      for (int i = 0; i < count; i++) {
        Vector2 position;

        // 普通攻击放中间
        if (i == 0) {
          position = Vector2.zero();
        } else {
          final skillIndex = i - 1;
          final skillCount = count - 1;

          final t = skillCount <= 1 ? 0.5 : skillIndex / (skillCount - 1);

          final deg = startDeg + (endDeg - startDeg) * t;
          final rad = deg * math.pi / 180.0;

          position = Vector2(math.cos(rad), math.sin(rad)) * radius;
        }

        buttonGroup.add(
          AttackButton(
            hero: hero,
            icon: attacks[i].icon!,
            onPressed: () => _attack(i),
          )..position = position,
        );
      }
    }

    add(buttonGroup);
  }

  void _attack(int index) {
    hero.attack(index, MonsterComponent);
  }
}
