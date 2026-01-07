import '../character/hero_component.dart';

mixin Interactable {
  void onEnterInteraction(HeroComponent hero);
  void onExitInteraction(HeroComponent hero);
  void onInteract(HeroComponent hero);
}
