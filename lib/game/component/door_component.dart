import 'package:myhero/game/component/hero_component.dart';
import 'package:flame/components.dart';
import 'package:myhero/game/my_game.dart';
import 'blocker_component.dart';
import 'package:myhero/component/dialog_component.dart';

class DoorComponent extends BlockerComponent with HasGameReference<MyGame> {
  final String keyId;
  bool isOpen;

  DoorComponent({
    required this.keyId,
    required this.isOpen,
    super.position,
    required super.size,
  }) : super(
    addHitbox: !isOpen);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load(isOpen ? 'open_door.png' : 'closed_door.png');
  }

  void unlock() async {
    if (!isOpen) {
      isOpen = true;
      sprite = await Sprite.load('open_door.png');
      hitbox.removeFromParent();
    }
  }

  void attemptOpen(HeroComponent hero) {
    if (!isOpen && hero.hasKey(keyId)) {
      unlock();
    } else if (!isOpen) {
      UiNotify.showToast(game, '需要钥匙 $keyId 才能打开');
    }
  }
}
