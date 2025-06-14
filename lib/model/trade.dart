class Trade {
  final int id;
  final double result;
  final DateTime timestamp;

  Trade({required this.id, required this.result, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  Trade copyWith({int? id, double? result, DateTime? timestamp}) {
    return Trade(
      id: id ?? this.id,
      result: result ?? this.result,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'result': result,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] as int,
      result: (json['result'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trade &&
        other.id == id &&
        other.result == result &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(id, result, timestamp);

  @override
  String toString() {
    return 'Trade(id: $id, result: $result, timestamp: $timestamp)';
  }
}
