import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MonsterHpBarComponent extends PositionComponent {
  final int maxHp;
  int currentHp;

  /// 血条尺寸
  final Vector2 barSize;

  MonsterHpBarComponent({
    required this.maxHp,
    required this.currentHp,
    required this.barSize,
    Vector2? position,
  }) : super(
          size: barSize,
          position: position ?? Vector2.zero(),
          anchor: Anchor.bottomCenter,
          priority: 1000,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);

    final hpPaint = Paint()
      ..color = _hpColor();

    // 背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      bgPaint,
    );

    // 当前血量
    final ratio = currentHp / maxHp;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x * ratio, size.y),
      hpPaint,
    );
  }

  Color _hpColor() {
    final ratio = currentHp / maxHp;
    if (ratio > 0.6) return Colors.green;
    if (ratio > 0.3) return Colors.orange;
    return Colors.red;
  }

  void updateHp(int hp) {
    currentHp = hp.clamp(0, maxHp);
  }
}
