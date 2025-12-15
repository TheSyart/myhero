import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:myhero/game/my_game.dart';
import 'package:flame/palette.dart';

enum DialogType { alert, confirm }

class DialogComponent extends PositionComponent
    with HasGameReference<MyGame>, TapCallbacks {
  final String title;
  final String message;
  final DialogType type;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String confirmText;
  final String cancelText;
  final Duration? autoDismissDuration;

  DialogComponent.alert({
    required String message,
    String title = '提示',
    VoidCallback? onConfirm,
    String confirmText = '确定',
    Duration autoDismiss = const Duration(milliseconds: 1500),
  })  : title = title,
        message = message,
        type = DialogType.alert,
        onConfirm = onConfirm,
        onCancel = null,
        confirmText = confirmText,
        cancelText = '取消',
        autoDismissDuration = autoDismiss;

  DialogComponent.confirm({
    required String message,
    String title = '提示',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    String confirmText = '确定',
    String cancelText = '取消',
  })  : title = title,
        message = message,
        type = DialogType.confirm,
        onConfirm = onConfirm,
        onCancel = onCancel,
        confirmText = confirmText,
        cancelText = cancelText,
        autoDismissDuration = null;

  late RectangleComponent _backdrop;
  late RectangleComponent _panel;
  late TextComponent _titleText;
  late TextComponent _messageText;
  RectButtonComponent? _cancelBtn;
  RectButtonComponent? _confirmBtn;

  @override
  Future<void> onLoad() async {
    size = game.size;
    position = Vector2.zero();

    _backdrop = RectangleComponent(
      position: Vector2.zero(),
      size: size.clone(),
      paint: Paint()..color = Colors.black.withOpacity(0.5),
      priority: 1000,
    );

    final panelWidth = size.x * 0.7;
    final panelHeight = size.y * 0.35;
    final panelPos = Vector2(
      (size.x - panelWidth) / 2,
      (size.y - panelHeight) / 2,
    );

    _panel = RectangleComponent(
      position: panelPos,
      size: Vector2(panelWidth, panelHeight),
      paint: BasicPalette.white.paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
      priority: 1001,
    );

    final titlePaint = TextPaint(
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
    final messagePaint = TextPaint(
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        height: 1.4,
      ),
    );

    _titleText = TextComponent(
      text: title,
      textRenderer: titlePaint,
      position: _panel.position + Vector2(16, 16),
      priority: 1002,
    );

    final messageTop = _titleText.position + Vector2(0, 32);
    _messageText = TextComponent(
      text: message,
      textRenderer: messagePaint,
      position: messageTop,
      priority: 1002,
    );

    add(_backdrop);
    add(_panel);
    add(_titleText);
    add(_messageText);

    final btnY = _panel.position.y + _panel.size.y - 56;
    if (type == DialogType.alert) {
      if (autoDismissDuration == null) {
        _confirmBtn = RectButtonComponent(
          label: confirmText,
          position: Vector2(_panel.position.x + _panel.size.x - 96, btnY),
          size: Vector2(80, 40),
          onPressed: () {
            onConfirm?.call();
            removeFromParent();
          },
        );
        add(_confirmBtn!);
      } else {
        Future.delayed(autoDismissDuration!, () {
          removeFromParent();
        });
      }
    } else {
      _cancelBtn = RectButtonComponent(
        label: cancelText,
        position: Vector2(_panel.position.x + 16, btnY),
        size: Vector2(80, 40),
        onPressed: () {
          onCancel?.call();
          removeFromParent();
        },
      );
      _confirmBtn = RectButtonComponent(
        label: confirmText,
        position: Vector2(_panel.position.x + _panel.size.x - 96, btnY),
        size: Vector2(80, 40),
        onPressed: () {
          onConfirm?.call();
          removeFromParent();
        },
      );
      add(_cancelBtn!);
      add(_confirmBtn!);
    }
  }
}

class RectButtonComponent extends PositionComponent
    with TapCallbacks, HasGameReference<MyGame> {
  final String label;
  final VoidCallback? onPressed;
  late RectangleComponent _bg;
  late TextComponent _text;

  RectButtonComponent({
    required this.label,
    required Vector2 position,
    required Vector2 size,
    this.onPressed,
  }) : super(position: position, size: size, priority: 1003);

  @override
  Future<void> onLoad() async {
    _bg = RectangleComponent(
      position: position,
      size: size,
      paint: Paint()..color = Colors.blueAccent,
      priority: priority,
    );
    _text = TextComponent(
      text: label,
      position: position + Vector2(12, 10),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      priority: priority,
    );
    parent?.add(_bg);
    parent?.add(_text);
  }

  @override
  void onTapUp(TapUpEvent event) {
    onPressed?.call();
  }
}

class ToastComponent extends PositionComponent with HasGameReference<MyGame> {
  final String message;
  final Duration duration;
  late TextComponent _text;
  double _elapsed = 0;

  ToastComponent({
    required this.message,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(priority: 1100);

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    position = Vector2(game.size.x / 2, game.size.y * 0.2);
    _text = TextComponent(
      text: message,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: priority,
    );
    add(_text);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final total = duration.inMilliseconds / 1000.0;
    final fadeStart = total * 0.6;
    double alpha = 1.0;
    if (_elapsed > fadeStart) {
      final t = ((_elapsed - fadeStart) / (total - fadeStart)).clamp(0.0, 1.0);
      alpha = 1.0 - t;
    }
    _text.textRenderer = TextPaint(
      style: TextStyle(
        color: Colors.white.withOpacity(alpha),
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
    if (_elapsed >= total) {
      removeFromParent();
    }
  }
}

class UiNotify {
  static void showToast(
    MyGame game,
    String message, {
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    final exists =
        game.camera.viewport.children.query<ToastComponent>().isNotEmpty;
    if (!exists) {
      game.camera.viewport
          .add(ToastComponent(message: message, duration: duration));
    }
  }
}

class RestartOverlay extends PositionComponent
    with HasGameReference<MyGame>, TapCallbacks {
  late RectButtonComponent _btn;

  RestartOverlay() : super(priority: 2000);

  @override
  Future<void> onLoad() async {
    size = game.size;
    position = Vector2.zero();

    final overlay = RectangleComponent(
      position: Vector2.zero(),
      size: size.clone(),
      paint: Paint()..color = Colors.black.withOpacity(0.6),
      priority: priority,
    );
    add(overlay);

    _btn = RectButtonComponent(
      label: '重新开始',
      position: Vector2(size.x / 2 - 60, size.y / 2 - 20),
      size: Vector2(120, 40),
      onPressed: () async {
        await game.restartGame();
      },
    );
    add(_btn);
  }
}
