//
//  Metrics.swift
//  
//
//  Created by Alexis TENAILLEAU on 22/03/2023.
//

import Foundation

struct Metrics: Codable {
    var appName: String
    var instanceId: String?
    var bucket: Bucket?
}

extension Metrics {
    struct Bucket: Codable {
        var start: Date?
        var end: Date?
        var toggles: [String: FlagMetric] = [:]
    }
    
    struct FlagMetric: Codable {
        var yes: Int = 0
        var no: Int = 0
    }
}
