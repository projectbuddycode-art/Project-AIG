import 'package:flutter/foundation.dart';

import 'package:aig/features/processing/models/processing_session.dart';
import 'package:aig/features/processing/models/processing_state.dart';

class PipelineStateNotifier extends ChangeNotifier {
  ProcessingSession _session = const ProcessingSession(
    id: 'idle',
    sourceMediaId: '',
  );

  ProcessingSession get session => _session;

  void update(ProcessingSession session) {
    _session = session;
    notifyListeners();
  }

  void reset() {
    _session = const ProcessingSession(
      id: 'idle',
      sourceMediaId: '',
      state: ProcessingState.idle,
    );
    notifyListeners();
  }
}
