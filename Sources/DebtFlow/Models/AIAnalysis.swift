import Foundation

// MARK: - Python Microservice Response

/// The raw response payload returned by the Python /analyze endpoint.
struct AIAnalysisResponse: Codable {
    let extractedText: String
    let modelsOutput: AIModelsOutput
    let finalSuggestions: [String]

    enum CodingKeys: String, CodingKey {
        case extractedText     = "extracted_text"
        case modelsOutput      = "models_output"
        case finalSuggestions  = "final_suggestions"
    }
}

/// The three LLM perspective outputs.
struct AIModelsOutput: Codable {
    let conservative: String
    let growth: String
    let balanced: String
}

// MARK: - Swift Backend Unified Response

/// The enriched payload returned to the SwiftUI frontend.
/// Combines the AI analysis with SubscriptionImpactEngine metrics.
struct SubscriptionAnalysisResult: Codable {
    let extractedText: String
    let aiAnalysis: AIModelsOutput
    let finalSuggestions: [String]
    let subscriptionImpact: SubscriptionImpact?
    let detectedSubscriptions: [DetectedSubscription]

    enum CodingKeys: String, CodingKey {
        case extractedText        = "extracted_text"
        case aiAnalysis           = "ai_analysis"
        case finalSuggestions     = "final_suggestions"
        case subscriptionImpact   = "subscription_impact"
        case detectedSubscriptions = "detected_subscriptions"
    }
}

/// A subscription entry that was parsed from the OCR text.
/// The Swift backend uses a simple heuristic parser to extract cost
/// data from the raw OCR text so it can run SubscriptionImpactEngine.
struct DetectedSubscription: Codable {
    let name: String
    let monthlyCost: Decimal

    enum CodingKeys: String, CodingKey {
        case name
        case monthlyCost = "monthly_cost"
    }
}

// MARK: - Error Response

struct ErrorResponse: Codable {
    let error: String
}

// MARK: - Python Health Check

struct PythonHealthResponse: Codable {
    let status: String
    let model: String
}
