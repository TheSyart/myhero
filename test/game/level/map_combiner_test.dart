import 'package:flutter_test/flutter_test.dart';
import 'package:myhero/game/level/map_combiner.dart';
import 'dart:math' as math;

void main() {
  group('MapCombiner Layout Generation', () {
    late MapCombiner mapCombiner;
    final List<String> mockMapFiles = [
      'assets/tiles/room_start.tmx',
      'assets/tiles/room_boss.tmx',
      'assets/tiles/room_treasure.tmx',
      'assets/tiles/room_shop.tmx',
      'assets/tiles/room_battle.tmx',
      'assets/tiles/room_01.tmx',
      'assets/tiles/room_02.tmx',
    ];

    setUp(() {
      mapCombiner = MapCombiner();
    });

    test('should have at least three battle rooms', () {
      for (int i = 0; i < 20; i++) {
        final layout = mapCombiner.generateLayout(mockMapFiles, seed: i);
        final battleCount = layout.grid.values.where((m) => m.endsWith('room_battle.tmx')).length;
        expect(battleCount, greaterThanOrEqualTo(3));
      }
    });

    test('should strictly generate within 3x3 grid bounds', () {
      for (int i = 0; i < 20; i++) {
        final layout = mapCombiner.generateLayout(mockMapFiles, seed: i);
        
        for (final point in layout.grid.keys) {
          expect(point.x, greaterThanOrEqualTo(0));
          expect(point.x, lessThan(3));
          expect(point.y, greaterThanOrEqualTo(0));
          expect(point.y, lessThan(3));
        }
      }
    });

    test('should generate correct number of rooms (5 to 9)', () {
      for (int i = 0; i < 20; i++) {
        final layout = mapCombiner.generateLayout(mockMapFiles, seed: i);
        expect(layout.grid.length, greaterThanOrEqualTo(5));
        expect(layout.grid.length, lessThanOrEqualTo(9));
      }
    });

    test('should have exactly one start room', () {
      final layout = mapCombiner.generateLayout(mockMapFiles);
      int startCount = layout.grid.values.where((m) => m.endsWith('room_start.tmx')).length;
      expect(startCount, equals(1));
    });

    test('should have max one boss, treasure, and shop room', () {
      for (int i = 0; i < 20; i++) {
        final layout = mapCombiner.generateLayout(mockMapFiles, seed: i);
        
        int bossCount = layout.grid.values.where((m) => m.endsWith('room_boss.tmx')).length;
        int treasureCount = layout.grid.values.where((m) => m.endsWith('room_treasure.tmx')).length;
        int shopCount = layout.grid.values.where((m) => m.endsWith('room_shop.tmx')).length;

        expect(bossCount, lessThanOrEqualTo(1));
        expect(treasureCount, lessThanOrEqualTo(1));
        expect(shopCount, lessThanOrEqualTo(1));
        
        if (layout.grid.length > 1) {
             expect(bossCount, equals(1), reason: "Boss room should exist if more than 1 room");
        }
      }
    });

    test('should ensure all rooms are connected', () {
      for (int i = 0; i < 20; i++) {
        final layout = mapCombiner.generateLayout(mockMapFiles, seed: i);
        final grid = layout.grid;
        final connections = layout.connections;
        
        // Pick a random room (e.g. first one)
        final startNode = grid.keys.first;
        final visited = <math.Point<int>>{startNode};
        final queue = [startNode];
        
        while (queue.isNotEmpty) {
          final current = queue.removeAt(0);
          
          // Find neighbors
          for (final conn in connections) {
            if (conn.from == current && !visited.contains(conn.to)) {
              visited.add(conn.to);
              queue.add(conn.to);
            } else if (conn.to == current && !visited.contains(conn.from)) {
              visited.add(conn.from);
              queue.add(conn.from);
            }
          }
        }
        
        expect(visited.length, equals(grid.length), reason: "All rooms should be reachable");
      }
    });

    test('should reproduce same layout with same seed', () {
      final seed = 12345;
      final layout1 = mapCombiner.generateLayout(mockMapFiles, seed: seed);
      final layout2 = mapCombiner.generateLayout(mockMapFiles, seed: seed);

      expect(layout1.grid.length, equals(layout2.grid.length));
      expect(layout1.grid.keys.toSet(), equals(layout2.grid.keys.toSet()));
      
      for (final key in layout1.grid.keys) {
        expect(layout1.grid[key], equals(layout2.grid[key]));
      }
    });

    test('should produce different layouts with different seeds', () {
      final layout1 = mapCombiner.generateLayout(mockMapFiles, seed: 111);
      final layout2 = mapCombiner.generateLayout(mockMapFiles, seed: 222);
      
      // It's possible but unlikely they are identical. 
      // Checking if grid positions OR map assignments differ.
      bool isDifferent = false;
      if (layout1.grid.length != layout2.grid.length) {
        isDifferent = true;
      } else {
        // Check positions
        if (!layout1.grid.keys.toSet().containsAll(layout2.grid.keys.toSet())) {
          isDifferent = true;
        } else {
           // Check contents
           for (final key in layout1.grid.keys) {
             if (layout1.grid[key] != layout2.grid[key]) {
               isDifferent = true;
               break;
             }
           }
        }
      }
      expect(isDifferent, isTrue);
    });
  });
}
