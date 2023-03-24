//
//  MetricsClient.swift
//  
//
//  Created by Alexis TENAILLEAU on 22/03/2023.
//

import Foundation

class MetricsClient {
    
    private let metricsURL : String
    private let apiKey: String
    
    private var timer: Timer?
    private var timeInterval: TimeInterval
    private let session: URLSession
    
    private var metrics: Metrics
    
    init(unleashURL: String, apiKey: String, appName: String?, instanceId: String = "iosApp", timeInterval: TimeInterval = 15, session: URLSession = URLSession.shared) {
        self.metricsURL = "\(unleashURL)/client/metrics"
        self.apiKey = apiKey
        self.metrics = Metrics(appName: appName ?? "iosApp", instanceId: instanceId)
        self.session = session
        self.timeInterval = timeInterval
    }
    
    func start() {
        //Create first bucket
        self.metrics.bucket = Metrics.Bucket(start: Date())
        
        let timer = Timer.scheduledTimer(withTimeInterval: self.timeInterval, repeats: true) {_ in
            self.metrics.bucket?.stop = Date()
            self.sendMetrics()
            //reset bucket
            self.metrics.bucket = Metrics.Bucket(start: Date())
        }
        
        self.timer = timer
        RunLoop.current.add(timer, forMode: .default)
    }
    
    func stop(){
        timer?.invalidate()
    }
    
    func addMetrics(name: String, enable: Bool){
        guard let bucket = metrics.bucket else {
            return
        }
        
        if bucket.toggles.contains(where: {$0.key == name}) {
            if enable {
                metrics.bucket?.toggles[name]?.yes += 1
            } else {
                metrics.bucket?.toggles[name]?.no += 1
            }
        } else { //Add Metric to bucket
            metrics.bucket?.toggles[name] = Metrics.FlagMetric()
            self.addMetrics(name: name, enable: enable)
        }
        
    }
    
    private func getPayloadFrom(metrics: Metrics) -> Data?{
        let jsonEncoder = JSONEncoder()
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        jsonEncoder.dateEncodingStrategy = .formatted(dateFormat)
        return try? jsonEncoder.encode(metrics)
    }
    
    private func sendMetrics() {
        guard let url = URL(string: metricsURL) else {
            Printer.printMessage("Metrics URL not valid")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apiKey, forHTTPHeaderField: "Authorization")
        
        request.httpBody = getPayloadFrom(metrics: self.metrics)
        
        session.perform(request, completionHandler: {_,_,error in
            if let error = error {
                Printer.printMessage(error.localizedDescription)//TODO: Improve message
            }
        })
    }
}
