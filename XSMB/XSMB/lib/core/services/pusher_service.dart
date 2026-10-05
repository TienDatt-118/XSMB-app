import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../config/app_config.dart';

class PusherService {
  PusherChannelsFlutter? _pusher;
  final List<StreamController<Map<String, dynamic>>> _liveDrawControllers = [];
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Initialize Pusher Client
  Future<void> init() async {
    if (kIsWeb) return; // Pusher channels package has limited support on pure web in this version
    
    try {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher!.init(
        apiKey: AppConfig.pusherAppKey,
        cluster: AppConfig.pusherCluster,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onEvent: _onEvent,
      );
      await _pusher!.connect();
    } catch (e) {
      debugPrint('Pusher Init Error: $e');
    }
  }

  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    debugPrint('Pusher Connection State changed from $previousState to $currentState');
    _isConnected = (currentState.toString().toLowerCase() == 'connected');
  }

  void _onError(String message, int? code, dynamic e) {
    debugPrint('Pusher Error: $message (Code: $code) - Exception: $e');
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    debugPrint('Pusher Subscribed Succeeded: $channelName - Data: $data');
  }

  void _onEvent(PusherEvent event) {
    debugPrint('Pusher Received Event: ${event.eventName} on ${event.channelName}');
    if (event.channelName == AppConfig.liveDrawChannel && event.eventName == AppConfig.liveDrawEvent) {
      try {
        final decoded = jsonDecode(event.data);
        if (decoded is Map<String, dynamic>) {
          for (var controller in _liveDrawControllers) {
            controller.add(decoded);
          }
        }
      } catch (e) {
        debugPrint('Error parsing Pusher Event Data: $e');
      }
    }
  }

  // Subscribe to live draw stream
  Stream<Map<String, dynamic>> getLiveDrawStream() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _liveDrawControllers.add(controller);

    // Subscribe to Pusher channel if not already subscribed
    if (_pusher != null && _isConnected) {
      _pusher!.subscribe(channelName: AppConfig.liveDrawChannel);
    }

    controller.onCancel = () {
      _liveDrawControllers.remove(controller);
      if (_liveDrawControllers.isEmpty && _pusher != null && _isConnected) {
        _pusher!.unsubscribe(channelName: AppConfig.liveDrawChannel);
      }
    };

    return controller.stream;
  }

  // Simulated WebSocket Live Draw (For verification & fallback testing)
  // Laravel side crawler draws one prize at a time from 18:15 to 18:30.
  // We simulate this by outputting sequential prize progress updates.
  Stream<Map<String, dynamic>> startMockLiveDraw() {
    late StreamController<Map<String, dynamic>> controller;
    Timer? timer;
    int step = 0;
    
    // Initial result state (empty)
    final Map<String, dynamic> drawState = {
      'status': 'drawing', // 'waiting', 'drawing', 'finished'
      'draw_date': DateTime.now().toIso8601String().substring(0, 10),
      'results': {
        'db': '',
        'g1': '',
        'g2': '',
        'g3': '',
        'g4': '',
        'g5': '',
        'g6': '',
        'g7': '',
      },
      'drawing_prize': 'g7', // currently drawing prize
      'drawing_index': 0,    // index inside the drawing prize
      'rolling_value': '',   // current digits rolling
    };

    final List<String> prizeSequence = [
      'g1',                   // 1 prize of 5 digits
      'g2', 'g2',             // 2 prizes of 5 digits
      'g3', 'g3', 'g3', 'g3', 'g3', 'g3', // 6 prizes of 5 digits
      'g4', 'g4', 'g4', 'g4', // 4 prizes of 4 digits
      'g5', 'g5', 'g5', 'g5', 'g5', 'g5', // 6 prizes of 4 digits
      'g6', 'g6', 'g6',       // 3 prizes of 3 digits
      'g7', 'g7', 'g7', 'g7', // 4 prizes of 2 digits
      'db',                   // 1 prize of 5 digits (LAST)
    ];

    String generateRandomDigits(int length) {
      final random = DateTime.now().microsecondsSinceEpoch;
      String result = '';
      for (int i = 0; i < length; i++) {
        result += ((random + i) % 10).toString();
      }
      return result;
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: () {
        timer = Timer.periodic(const Duration(milliseconds: 150), (t) {
          if (step >= prizeSequence.length * 15) {
            // Finished all draws
            drawState['status'] = 'finished';
            drawState['drawing_prize'] = '';
            drawState['drawing_index'] = -1;
            drawState['rolling_value'] = '';
            controller.add(Map<String, dynamic>.from(drawState));
            timer?.cancel();
            controller.close();
            return;
          }

          int prizeIdx = step ~/ 15;
          int subStep = step % 15;
          String currentPrize = prizeSequence[prizeIdx];

          // Calculate index within prize
          int count = 0;
          for (int i = 0; i < prizeIdx; i++) {
            if (prizeSequence[i] == currentPrize) count++;
          }
          drawState['drawing_prize'] = currentPrize;
          drawState['drawing_index'] = count;

          int digitLength = (currentPrize == 'g7') ? 2 : (currentPrize == 'g6' ? 3 : (currentPrize == 'g7' ? 2 : ((currentPrize == 'g4' || currentPrize == 'g5') ? 4 : 5)));
          
          if (subStep < 12) {
            // Rolling state
            drawState['rolling_value'] = generateRandomDigits(digitLength);
          } else {
            // Settle state
            String settledNum = generateRandomDigits(digitLength); // fixated number
            List<String> currentList = [];
            final raw = drawState['results'][currentPrize] as String;
            if (raw.isNotEmpty) {
              currentList = raw.split(',');
            }

            if (currentList.length <= count) {
              currentList.add(settledNum);
            } else {
              currentList[count] = settledNum;
            }

            drawState['results'][currentPrize] = currentList.join(',');
            drawState['rolling_value'] = '';
            step = (prizeIdx + 1) * 15 - 1; // jump to next prize start
          }

          controller.add(Map<String, dynamic>.from(drawState));
          step++;
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> disconnect() async {
    if (_pusher != null && _isConnected) {
      await _pusher!.disconnect();
      _isConnected = false;
    }
  }
}
