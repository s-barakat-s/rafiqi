class TasbeehTaskContext {
  const TasbeehTaskContext({
    required this.taskId,
    required this.phraseId,
    required this.phraseText,
    required this.targetCount,
    required this.initialProgress,
  });

  final String taskId;
  final String phraseId;
  final String phraseText;
  final int targetCount;
  final int initialProgress;
}
