class AdMilestone {
  final int requiredWatches;
  final int reward;
  final bool isLocked;
  final bool isCompleted;

  const AdMilestone({
    required this.requiredWatches,
    required this.reward,
    this.isLocked = true,
    this.isCompleted = false,
  });

  AdMilestone copyWith({
    int? requiredWatches,
    int? reward,
    bool? isLocked,
    bool? isCompleted,
  }) {
    return AdMilestone(
      requiredWatches: requiredWatches ?? this.requiredWatches,
      reward: reward ?? this.reward,
      isLocked: isLocked ?? this.isLocked,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
