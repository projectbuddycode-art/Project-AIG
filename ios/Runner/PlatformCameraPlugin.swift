import Flutter
import UIKit
import AVFoundation

public class PlatformCameraPlugin: NSObject {
    private var methodChannel: FlutterMethodChannel?
    private var previewChannel: FlutterEventChannel?
    private var cameraManager: CameraManager?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = PlatformCameraPlugin()
        instance.methodChannel = FlutterMethodChannel(name: "aig.camera/methods", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)

        instance.previewChannel = FlutterEventChannel(name: "aig.camera/preview", binaryMessenger: registrar.messenger())
        let streamHandler = PreviewStreamHandler()
        instance.previewChannel?.setStreamHandler(streamHandler)

        instance.cameraManager = CameraManager(previewStream: streamHandler)
    }
}

extension PlatformCameraPlugin: FlutterPlugin {
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "ensureCameraPermission":
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                result(true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        result(granted)
                    }
                }
            case .denied, .restricted:
                result(false)
            @unknown default:
                result(false)
            }
        case "initialize":
            cameraManager?.initialize()
            result(nil)
        case "dispose":
            cameraManager?.dispose()
            result(nil)
        case "startPreview":
            cameraManager?.startPreview()
            result(nil)
        case "stopPreview":
            cameraManager?.stopPreview()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
