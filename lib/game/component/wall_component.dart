import 'package:flame/components.dart';
import 'blocker_component.dart';

class WallComponent extends BlockerComponent {
  final bool vertical;
  final bool useSprite;
  WallComponent({
    Vector2? position,
    required Vector2 size,
    this.useSprite = false,
    this.vertical = true,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (useSprite) {
      sprite = await Sprite.load(
        vertical ? 'wall_vertical.png' : 'wall_horizontal.png',
      );
    }
  }
}
