import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('closed stream cannot emit new events', () async {
    final controller = StreamController<int>.broadcast();
    await controller.close();

    expect(controller.isClosed, isTrue);
    expect(() => controller.add(1), throwsStateError);
  });
}
