import 'package:myhero/game/character/hero_component.dart';
import 'package:flame/components.dart';
import 'package:myhero/game/my_game.dart';
import 'blocker_component.dart';
import 'package:myhero/component/dialog_component.dart';
import 'package:myhero/game/character/character_component.dart';
import 'package:myhero/manager/audio_manager.dart';

class DoorComponent extends BlockerComponent with HasGameReference<MyGame> {
  final String keyId;
  bool isOpen;
  bool _forceLocked = false;
  double _knockCooldownLeft = 0;

  DoorComponent({
    required this.keyId,
    required this.isOpen,
    super.position,
    required super.size,
  }) : super(addHitbox: !isOpen);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load(isOpen ? 'open_door.png' : 'closed_door.png');
  }

  Future<void> open() async {
    _unlock(force: true);
  }

  Future<void> close() async {
    if (isOpen) {
      isOpen = false;
      sprite = await Sprite.load('closed_door.png');
      if (hitbox.parent == null) {
        add(hitbox);
      }
    }
  }

  void setLocked(bool locked) {
    _forceLocked = locked;
  }

  void _unlock({bool force = false}) async {
    if (!isOpen) {
      if (_forceLocked && !force) return;
      isOpen = true;
      sprite = await Sprite.load('open_door.png');

      await AudioManager.playDoorOpen();

      hitbox.removeFromParent();
    }
  }

  void attemptOpen(CharacterComponent character) {
    if (character is! HeroComponent) return;
    if (_forceLocked) return;
    if ((!isOpen && character.hasKey(keyId)) || keyId.isEmpty) {
      _unlock(force: false);
    } else if (!isOpen) {
      if (_knockCooldownLeft > 0) return;
      _knockCooldownLeft = 1.0;
      AudioManager.playDoorKnock();
      UiNotify.showToast(game, '需要钥匙 $keyId 才能打开');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_knockCooldownLeft > 0) {
      _knockCooldownLeft -= dt;
      if (_knockCooldownLeft < 0) _knockCooldownLeft = 0;
    }
  }
}
