import 'dart:async';
import 'package:flutter/services.dart';
import 'step_history_storage.dart';

class StepCounterService {
  static const MethodChannel _channel = MethodChannel('com.aio_workout/step_counter');
  static const EventChannel _stepEvents = EventChannel('com.aio_workout/step_events');

  static final StepCounterService _instance = StepCounterService._();
  factory StepCounterService() => _instance;
  StepCounterService._();

  final StepHistoryStorage _storage = StepHistoryStorage();
  StreamSubscription<dynamic>? _stepSubscription;
  StreamController<int>? _stepController;
  int _todaySteps = 0;
  int _sensorBaseline = -1;
  bool _isRunning = false;
  bool _useSensor = true;

  Stream<int> get stepStream {
    if (_stepController == null || _stepController!.isClosed) {
      _stepController = StreamController<int>.broadcast();
    }
    return _stepController!.stream;
  }

  int get todaySteps => _todaySteps;
  bool get isRunning => _isRunning;
  bool get useSensor => _useSensor;

  Future<void> initialize() async {
    _useSensor = await _storage.loadUseSensor();
    _todaySteps = await _storage.loadTodaySteps();
  }

  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> startListening() async {
    if (_isRunning || !_useSensor) return;

    try {
      final available = await isAvailable();
      if (!available) return;

      final granted = await requestPermission();
      if (!granted) return;

      _channel.invokeMethod('startListening');
      _stepSubscription?.cancel();
      _stepSubscription = _stepEvents.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final steps = event['steps'] as int? ?? 0;
            final isBaseline = event['isBaseline'] as bool? ?? false;

            if (isBaseline) {
              _sensorBaseline = steps;
              return;
            }

            if (_sensorBaseline >= 0) {
              _todaySteps = steps - _sensorBaseline;
            } else {
              _todaySteps = steps;
            }

            if (_todaySteps < 0) _todaySteps = 0;
            _persistSteps();
            _stepController?.add(_todaySteps);
          }
        },
        onError: (error) {
          _isRunning = false;
        },
      );

      _isRunning = true;
    } catch (e) {
      _isRunning = false;
    }
  }

  Future<void> stopListening() async {
    if (!_isRunning) return;
    try {
      await _channel.invokeMethod('stopListening');
    } catch (e) {
      // ignore
    }
    _stepSubscription?.cancel();
    _stepSubscription = null;
    _isRunning = false;
  }

  void _persistSteps() {
    _storage.saveTodaySteps(_todaySteps);
  }

  void addManualSteps(int count) {
    _todaySteps += count;
    _persistSteps();
    _stepController?.add(_todaySteps);
  }

  Future<void> setTodaySteps(int steps) async {
    _todaySteps = steps;
    _persistSteps();
    _stepController?.add(_todaySteps);
  }

  Future<void> setUseSensor(bool use) async {
    _useSensor = use;
    await _storage.saveUseSensor(use);
    if (use) {
      await startListening();
    } else {
      await stopListening();
    }
  }

  void dispose() {
    _stepSubscription?.cancel();
    _stepController?.close();
    _stepController = null;
  }
}
