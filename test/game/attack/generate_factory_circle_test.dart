import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/attack/factory/generate_factory.dart';
import 'package:myhero/game/character/hero_component.dart';

void main() {
  test('createCircle returns correct count and positions on circle', () {
    final center = Vector2(200, 200);
    const radius = 100.0;
    const count = 8;
    final owner = PositionComponent(position: Vector2.zero(), size: Vector2.all(10));

    final comps = GenerateFactory.createCircle(
      center: center,
      generateId: 'elite_orc',
      owner: owner,
      enemyType: HeroComponent,
      count: count,
      radius: radius,
    );

    expect(comps.length, count);

    double dist(Vector2 a, Vector2 b) {
      final dx = a.x - b.x;
      final dy = a.y - b.y;
      return math.sqrt(dx * dx + dy * dy);
    }

    for (final c in comps) {
      final d = dist(c.position, center);
      expect(d, closeTo(radius, 1e-3));
    }

    final angles = comps.map((c) {
      final p = c.position - center;
      return math.atan2(p.y, p.x);
    }).toList()
      ..sort();

    final step = 2 * math.pi / count;
    for (int i = 1; i < angles.length; i++) {
      final diff = angles[i] - angles[i - 1];
      expect(diff, closeTo(step, 1e-3));
    }
  });
}
