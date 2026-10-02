import Foundation
import Flutter

/// PreviewStreamHandler sends preview frames to Flutter via EventChannel.
class PreviewStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    func sendFrame(_ data: Data, width: Int, height: Int) {
        let dict: [String: Any] = ["bytes": FlutterStandardTypedData(bytes: data), "width": width, "height": height]
        eventSink?(dict)
    }
}
