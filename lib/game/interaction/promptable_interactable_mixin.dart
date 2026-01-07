import 'package:flame/components.dart';
import 'interactable.dart';
import 'prompt/interaction_prompt.dart';
import 'prompt/interaction_prompt_component.dart';

mixin PromptableInteractable
    on PositionComponent
    implements Interactable, InteractionPrompt {
  InteractionPromptComponent? _prompt;

  @override
  void onEnterInteraction(hero) {
    if (!show) return;
    _prompt ??= InteractionPromptComponent(text: promptText)
      ..position = Vector2(size.x / 2, 0);
    add(_prompt!);
  }

  @override
  void onExitInteraction(hero) {
    _prompt?.removeFromParent();
    _prompt = null;
  }
}
