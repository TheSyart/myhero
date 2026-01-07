import 'package:flame/components.dart';
import '../../character/hero_component.dart';
import '../../character/monster_component.dart';
import 'attack_button.dart';
import 'weapon_button.dart';
import 'dart:math' as math;

class AttackHud extends PositionComponent {
  static const buttonSize = 64.0;
  static const buttonSpacing = 8.0;

  late final PositionComponent buttonGroup;
  final HeroComponent hero;
  WeaponButton? _weaponButton;
  bool _interactMode = false;

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

        final skillIndex = i;
        final skillCount = count;

        final t = skillCount <= 1 ? 0.5 : skillIndex / (skillCount - 1);

        final deg = startDeg + (endDeg - startDeg) * t;
        final rad = deg * math.pi / 180.0;

        position = Vector2(math.cos(rad), math.sin(rad)) * radius;

        buttonGroup.add(
          AttackButton(
            hero: hero,
            icon: attacks[i].icon!,
            onPressed: () => _attack(i),
          )..position = position,
        );
      }
    }

    _buildWeaponOrInteractButton();

    add(buttonGroup);
  }

  void _attack(int index) {
    hero.attack(index, MonsterComponent);
  }

  void _weaponAttack() {
    hero.weapon?.attack();
  }

  void _buildWeaponOrInteractButton() {
    _weaponButton?.removeFromParent();
    final hasWeapon = hero.weapon != null;
    final hasInteractable = hero.current != null;

    if (hasInteractable) {
      // 进入交互模式：使用一个交互图标，并点击触发 hero.interact()
      _interactMode = true;
      _weaponButton = WeaponButton(
        hero: hero,
        icon: 'ui/Exclamation-Mark.png',
        onPressed: () => hero.interact(),
      )..position = Vector2.zero();
    } else {
      // 非交互模式：显示武器图标，如果没有武器则为空按钮（保留圆圈占位）
      _interactMode = false;
      final weaponIcon = hasWeapon
          ? 'ui/Attack.png'
          : 'ui/Slash.png';
      _weaponButton = WeaponButton(
        hero: hero,
        icon: weaponIcon,
        onPressed: () => _weaponAttack(),
      )..position = Vector2.zero();
    }
    buttonGroup.add(_weaponButton!);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 根据 hero.current 的存在性在武器/交互模式之间切换
    final needInteract = hero.current != null;
    if (needInteract != _interactMode) {
      _buildWeaponOrInteractButton();
    }
  }
}
