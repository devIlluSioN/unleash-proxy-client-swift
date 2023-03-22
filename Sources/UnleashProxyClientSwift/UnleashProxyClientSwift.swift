
import Foundation
import SwiftEventBus

// MARK: - Welcome
struct FeatureResponse: Codable {
    let toggles: [Toggle]
}

// MARK: - Toggle
public struct Toggle: Codable {
    public let name: String
    public let enabled: Bool
    public let variant: Variant
}

// MARK: - Variant
public struct Variant: Codable {
    public let name: String
    public let enabled: Bool
    public let payload: Payload?
}

// MARK: - Payload
public struct Payload: Codable {
    public let type, value: String
}

struct Context {
    let appName: String?
    let environment: String?
}


@available(macOS 10.15, *)
public class UnleashClient: ObservableObject {
    public var context: [String: String] = [:]
    var timer: Timer?
    var poller: Poller
    var metrics: MetricsClient?
    
    public init(unleashUrl: String, clientKey: String, refreshInterval: Int? = nil, appName: String? = nil, environment: String? = nil, poller: Poller? = nil, metricsInterval: TimeInterval? = nil, metricsEnable: Bool = true) {
        self.context["appName"] = appName
        self.context["environment"] = environment
        self.timer = nil
        if let poller = poller {
            self.poller = poller
        } else {
            self.poller = Poller(refreshInterval: refreshInterval, unleashUrl: unleashUrl, apiKey: clientKey)
        }
        if metricsEnable {
            self.metrics = MetricsClient(unleashURL: unleashUrl, apiKey: clientKey, appName: appName, timeInterval: metricsInterval ?? 15)
            //Default timeInterval 15sec
            self.subscribe(name: "ready", callback: {
                self.metrics?.start()
            })
        }
   }

    public func start(_ printToConsole: Bool = false, completionHandler: ((PollerError?) -> Void)? = nil) -> Void {
        Printer.showPrintStatements = printToConsole
        poller.start(context: context, completionHandler: completionHandler)
        metrics?.start()
    }

    public func stop() -> Void {
        poller.stop()
        metrics?.stop()
    }

    public func isEnabled(name: String) -> Bool {
        return poller.toggles[name]?.enabled ?? false
    }

    public func getVariant(name: String) -> Variant {
        let variant = poller.toggles[name]?.variant ?? Variant(name: "disabled", enabled: false, payload: nil)
        metrics?.addMetrics(name: name, enable: poller.toggles[name]?.enabled ?? false)
        
        return variant
    }

    public func subscribe(name: String, callback: @escaping () -> Void) {
        SwiftEventBus.onBackgroundThread(self, name: name) { result in
            callback()
        }
    }

    public func updateContext(context: [String: String]) -> Void {
        var newContext: [String: String] = [:]
        newContext["appName"] = self.context["appName"]
        newContext["environment"] = self.context["environment"]

        context.forEach { (key, value) in
            newContext[key] = value
        }

        self.context = newContext
        self.stop()
        self.start()
    }
}
