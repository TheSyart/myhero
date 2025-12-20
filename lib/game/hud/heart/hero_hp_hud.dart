import 'package:flame/components.dart';
import '../../character/hero_component.dart';
import 'heart_component.dart';
import '../../my_game.dart';

class HeroHpHud extends PositionComponent with HasGameReference<MyGame> {
  final HeroComponent hero;

  // 心跳组件
  final List<HeartComponent> hearts = [];

  // 每个心跳组件的精灵图
  late final List<Sprite> heartSprites;
  
  // 每个心跳组件包含的生命值
  final int hpPerHeart = 4;

  HeroHpHud(this.hero);

  @override
  Future<void> onLoad() async {
    final image = await game.images.load('heart_animated_1.png');

    heartSprites = List.generate(
      hpPerHeart + 1, // 包含空心
      (i) => Sprite(
        image,
        srcPosition: Vector2((hpPerHeart - i) * 17, 0),
        srcSize: Vector2(17, 17),
      ),
    );

    for (int i = 0; i < hero.maxHp ~/ hpPerHeart; i++) {
      final double heartSize = 24;
      final double heartSpacing = heartSize + 1;
      final heart = HeartComponent(heartSprites)
        ..size = Vector2(heartSize, heartSize)
        ..position = Vector2(i * heartSpacing, 0);
      hearts.add(heart);
      add(heart);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final totalHearts = hearts.length;
    final clampedHp = hero.hp.clamp(0, hero.maxHp);
    for (int i = 0; i < totalHearts; i++) {
      final start = i * hpPerHeart;
      final filled = (clampedHp - start).clamp(0, hpPerHeart);
      hearts[i].setHpStage(filled);
    }
  }
}
