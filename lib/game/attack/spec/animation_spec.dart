class AnimationSpec {
  final int row;
  final int from;
  final int to;
  final double stepTime;
  final bool loop;
  const AnimationSpec({
    required this.row,
    required this.from,
    required this.to,
    required this.stepTime,
    required this.loop,
  });
}