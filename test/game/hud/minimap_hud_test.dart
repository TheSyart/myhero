import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:myhero/game/my_game.dart';
import 'package:myhero/game/hud/minimap_hud.dart';
import 'package:myhero/game/level/level_loader.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'dart:ui';

class TestMyGame extends MyGame {
  @override
  Future<void> onLoad() async {
    // Skip default loading to avoid asset dependencies
  }
}

void main() {
  group('MinimapHud', () {
    testWithGame<TestMyGame>('positions at top-right and has 20% square size', () {
      final g = TestMyGame();
      return g;
    }, (game) async {
      game.onGameResize(Vector2(1000, 600));
      game.levelLoader = LevelLoader(game);
      game.hero = HeroComponent(birthPosition: Vector2.zero());

      final minimap = MinimapHud();
      await game.camera.viewport.add(minimap);
      await minimap.onLoad();

      expect(minimap.anchor, Anchor.topRight);
      expect(minimap.size.x, closeTo(200, 0.01));
      expect(minimap.size.y, closeTo(200, 0.01));
      expect(minimap.position.x, closeTo(980, 0.01));
      expect(minimap.position.y, closeTo(20, 0.01));
    });

    testWithGame<TestMyGame>('updates data when world changes', () {
      final g = TestMyGame();
      return g;
    }, (game) async {
      game.onGameResize(Vector2(1200, 800));
      game.levelLoader = LevelLoader(game);
      game.hero = HeroComponent(birthPosition: Vector2.zero());

      final minimap = MinimapHud();
      await game.camera.viewport.add(minimap);
      await minimap.onLoad();

      minimap.debugSetWorldData(
        worldTopLeft: Vector2.zero(),
        worldSize: Vector2(800, 600),
        rooms: [Rect.fromLTWH(0, 0, 400, 300), Rect.fromLTWH(400, 0, 400, 300)],
        corridors: [Rect.fromLTWH(390, 120, 20, 60)],
      );
      expect(minimap.debugRoomCount(), 2);
      expect(minimap.debugCorridorCount(), 1);

      minimap.debugSetWorldData(
        worldTopLeft: Vector2.zero(),
        worldSize: Vector2(800, 600),
        rooms: [
          Rect.fromLTWH(0, 0, 400, 300),
          Rect.fromLTWH(400, 0, 400, 300),
          Rect.fromLTWH(0, 300, 400, 300)
        ],
        corridors: [
          Rect.fromLTWH(390, 120, 20, 60),
          Rect.fromLTWH(190, 300, 20, 60),
        ],
      );
      expect(minimap.debugRoomCount(), 3);
      expect(minimap.debugCorridorCount(), 2);
    });

    testWithGame<TestMyGame>('supports zoom without overflow', () {
      final g = TestMyGame();
      return g;
    }, (game) async {
      game.onGameResize(Vector2(1000, 600));
      game.levelLoader = LevelLoader(game);
      game.hero = HeroComponent(birthPosition: Vector2(500, 300));

      final minimap = MinimapHud();
      await game.camera.viewport.add(minimap);
      await minimap.onLoad();

      minimap.debugSetWorldData(
        worldTopLeft: Vector2.zero(),
        worldSize: Vector2(2000, 2000),
        rooms: [Rect.fromLTWH(0, 0, 500, 500)],
        corridors: [],
      );

      minimap.setZoom(2.0);
      expect(minimap.size.x, closeTo(200, 0.01));
      expect(minimap.size.y, closeTo(200, 0.01));
    });

    testWithGame<TestMyGame>('no conflict with other HUD elements', () {
      final g = TestMyGame();
      return g;
    }, (game) async {
      game.onGameResize(Vector2(1000, 600));
      game.levelLoader = LevelLoader(game);
      game.hero = HeroComponent(birthPosition: Vector2.zero());

      final minimap = MinimapHud();
      await game.camera.viewport.add(minimap);
      await minimap.onLoad();

      final bottomRightChildren = game.camera.viewport.children.where((c) {
        return c is PositionComponent && (c as PositionComponent).anchor == Anchor.bottomRight;
      }).toList();

      for (final c in bottomRightChildren) {
        final pc = c as PositionComponent;
        expect(minimap.position.y < pc.position.y, isTrue);
      }
    });
  });
}
