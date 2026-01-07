import 'package:flame/components.dart';
import 'package:myhero/game/character/hero_component.dart';
import 'package:myhero/game/my_game.dart';
import 'heart/hero_hp_hud.dart';

class HeroInfoPanel extends PositionComponent with HasGameReference<MyGame> {
  final HeroComponent hero;

  HeroInfoPanel(this.hero);

  @override
  Future<void> onLoad() async {
    // 1. 头像
    final portraitImage = await game.images.load('hud/avatar.png');
    final avatar = SpriteComponent(
      sprite: Sprite(portraitImage),
      size: Vector2(60, 60),
    );
    add(avatar);

    // 2. 血条 HUD
    final hpHud = HeroHpHud(hero);
    // 这里的坐标是相对于 InfoPanel 的，也就是相对于头像
    hpHud.position = Vector2(avatar.size.x + 8, (avatar.size.y - 24) / 2);
    add(hpHud);
    
    // 设置 Panel 大小，方便后续布局（虽然 PositionComponent 默认 size 是 0，但设置一下比较好）
    size = Vector2(avatar.size.x + 8 + 100, avatar.size.y); // 宽度估算
  }
}
