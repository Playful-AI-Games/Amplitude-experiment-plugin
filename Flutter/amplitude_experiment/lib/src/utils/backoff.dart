import 'dart:async';
import 'dart:math' as math;

/// Exponential backoff implementation for retrying operations
class Backoff {
  final int attempts;
  final Duration min;
  final Duration max;
  final double scalar;
  
  Timer? _timer;
  int _attemptCount = 0;
  
  Backoff({
    required this.attempts,
    required this.min,
    required this.max,
    required this.scalar,
  });
  
  /// Start the backoff retry process
  void start(Future<void> Function() operation) {
    _attemptCount = 0;
    _scheduleNext(operation);
  }
  
  /// Cancel the backoff process
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _attemptCount = 0;
  }
  
  void _scheduleNext(Future<void> Function() operation) {
    if (_attemptCount >= attempts) {
      cancel();
      return;
    }
    
    final delay = _calculateDelay();
    _timer = Timer(delay, () async {
      _attemptCount++;
      await operation();
      _scheduleNext(operation);
    });
  }
  
  Duration _calculateDelay() {
    if (_attemptCount == 0) {
      return Duration.zero;
    }
    
    final exponential = min.inMilliseconds * math.pow(scalar, _attemptCount - 1);
    final delayMs = math.min(exponential, max.inMilliseconds.toDouble()).toInt();
    
    // Add jitter (±10%)
    final jitter = (delayMs * 0.1 * (math.Random().nextDouble() * 2 - 1)).toInt();
    
    return Duration(milliseconds: delayMs + jitter);
  }
}