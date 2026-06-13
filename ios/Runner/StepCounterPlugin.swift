import Flutter
import UIKit
import CoreMotion

@objc class StepCounterPlugin: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var pedometer: CMPedometer?
    private var startDate: Date?
    private var baselineSteps: Int?
    private var isListening = false

    func attach(to registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.aio_workout/step_counter",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.aio_workout/step_events",
            binaryMessenger: registrar.messenger()
        )

        methodChannel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            switch call.method {
            case "isAvailable":
                result(CMPedometer.isStepCountingAvailable())
            case "requestPermission":
                self.requestPermission(result: result)
            case "startListening":
                self.startListening(result: result)
            case "stopListening":
                self.stopListening(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        eventChannel.setStreamHandler(self)
        pedometer = CMPedometer()
    }

    private func requestPermission(result: @escaping FlutterResult) {
        if #available(iOS 11.0, *) {
            pedometer?.queryPedometerData(from: Date(), to: Date()) { _, error in
                if error != nil {
                    result(false)
                } else {
                    result(true)
                }
            }
        } else {
            result(true)
        }
    }

    private func startListening(result: @escaping FlutterResult) {
        guard !isListening else {
            result(true)
            return
        }
        guard CMPedometer.isStepCountingAvailable() else {
            result(false)
            return
        }

        isListening = true
        startDate = Date()
        baselineSteps = nil

        pedometer?.startUpdates(from: Date()) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }

            let steps = data.numberOfSteps.intValue

            DispatchQueue.main.async {
                if self.baselineSteps == nil {
                    self.baselineSteps = steps
                    self.eventSink?([
                        "steps": steps,
                        "isBaseline": true
                    ])
                } else {
                    self.eventSink?([
                        "steps": steps,
                        "isBaseline": false
                    ])
                }
            }
        }

        result(true)
    }

    private func stopListening(result: @escaping FlutterResult) {
        guard isListening else {
            result(true)
            return
        }

        isListening = false
        pedometer?.stopUpdates()
        baselineSteps = nil
        startDate = nil

        result(true)
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
