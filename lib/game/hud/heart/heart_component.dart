import 'package:flame/components.dart';

class HeartComponent extends SpriteComponent {
  final List<Sprite> sprites;

  HeartComponent(this.sprites) {
    sprite = sprites.last; // 默认满血
  }

  void setHpStage(int stage) {
    sprite = sprites[stage.clamp(0, sprites.length - 1)];
  }
}
