class TrainingRecord {
  final int? id;
  final DateTime date;
  final int durationSeconds;
  final int bpm;
  final int signalCount;
  final TrainingMode mode;

  TrainingRecord({
    this.id,
    required this.date,
    required this.durationSeconds,
    required this.bpm,
    required this.signalCount,
    required this.mode,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'duration_seconds': durationSeconds,
      'bpm': bpm,
      'signal_count': signalCount,
      'mode': mode.index,
    };
  }

  factory TrainingRecord.fromMap(Map<String, dynamic> map) {
    return TrainingRecord(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      durationSeconds: map['duration_seconds'] as int,
      bpm: map['bpm'] as int,
      signalCount: map['signal_count'] as int,
      mode: TrainingMode.values[map['mode'] as int],
    );
  }
}
