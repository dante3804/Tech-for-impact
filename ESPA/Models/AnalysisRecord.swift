//
//  AnalysisRecord.swift
//  ESPA
//
//  Persisted record for a single image-based stockpile analysis run.
//

import Foundation

// MARK: - AnalysisWeather

/// Snapshot of weather conditions captured at the moment of analysis.
struct AnalysisWeather: Codable, Hashable {
    let temperature: Int    // °C
    let condition: String   // e.g. "맑음", "흐림", "비"
    let windSpeed: Double   // m/s
    let humidity: Int       // %
}

// MARK: - AnalysisRecord

/// One completed AI analysis (image → bag count / fill rate / HRI delta).
/// Persisted to UserDefaults as the analysis history feed.
struct AnalysisRecord: Codable, Identifiable, Hashable {
    let id: String
    let timestamp: Date
    let stockpileName: String
    let stockpileId: Int
    let bagCount: Int
    let fillRate: FillRate
    let confidence: Double      // 0.0 – 1.0
    let estimatedWeight: Double // kg
    let estimatedHRI: Double
    let previousHRI: Double
    let hriDelta: Double
    let weather: AnalysisWeather
    let imageName: String       // filename in app's Documents/analysis-images/
    let modelStatus: String     // e.g. "정상", "재학습 권장", "성능 저하"
    let message: String         // human-readable summary / advice

    /// Risk level derived from the estimated HRI for convenience in views.
    var riskLevel: RiskLevel {
        HRICalculator.riskLevel(for: estimatedHRI)
    }

    /// True when the new HRI is higher than the previous one.
    var isHRIIncreased: Bool { hriDelta > 0 }
}

// MARK: - Convenience initializer

extension AnalysisRecord {
    /// Creates a new record, auto-assigning a UUID and `Date()` timestamp.
    init(
        stockpileName: String,
        stockpileId: Int,
        bagCount: Int,
        fillRate: FillRate,
        confidence: Double,
        estimatedWeight: Double,
        estimatedHRI: Double,
        previousHRI: Double,
        weather: AnalysisWeather,
        imageName: String,
        modelStatus: String,
        message: String
    ) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.stockpileName = stockpileName
        self.stockpileId = stockpileId
        self.bagCount = bagCount
        self.fillRate = fillRate
        self.confidence = confidence
        self.estimatedWeight = estimatedWeight
        self.estimatedHRI = estimatedHRI
        self.previousHRI = previousHRI
        self.hriDelta = estimatedHRI - previousHRI
        self.weather = weather
        self.imageName = imageName
        self.modelStatus = modelStatus
        self.message = message
    }
}
