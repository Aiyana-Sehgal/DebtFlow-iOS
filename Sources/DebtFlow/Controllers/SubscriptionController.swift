#if os(Windows)
import WinSDK
#endif
import Foundation




// MARK: - Custom Error Types

enum ControllerError: Error, LocalizedError {
    case invalidURL
    case networkError(String)
    case timeout
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Python service URL."
        case .networkError(let message):
            return "Network error: \(message)"
        case .timeout:
            return "Request timed out."
        case .invalidResponse:
            return "Invalid response from Python service."
        }
    }
}

// MARK: - Subscription Controller

/// Handles `POST /api/subscriptions/analyze`.
///
/// Flow:
///   1. Parse the multipart/form-data request and extract the image bytes.
///   2. POST the image to the local Python microservice (`/analyze`).
///   3. Decode the AI JSON response into `AIAnalysisResponse`.
///   4. Run a lightweight OCR-text parser to detect subscription costs.
///   5. Feed detected subscriptions into `SubscriptionImpactEngine`.
///   6. Return a unified `SubscriptionAnalysisResult` as JSON.
enum SubscriptionController {

    // Python microservice base URL — same machine, different port
    private static let pythonServiceURL = "http://127.0.0.1:8000"

    // MARK: - Public entry point

    /// Returns `(statusCode, responseBodyString)`.
    static func analyze(multipartBody: Data, boundary: String) -> (Int, String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        // 1. Extract image bytes from multipart body
        guard let imageData = extractImageData(from: multipartBody, boundary: boundary) else {
            return encode(encoder, ErrorResponse(error: "Could not parse image from multipart body."), statusCode: 400)
        }

        // 2. Health-check the Python service (fast fail)
        guard pythonServiceIsHealthy() else {
            return encode(encoder, ErrorResponse(
                error: "AI microservice is unavailable. Ensure the Python service is running on port 8000."
            ), statusCode: 503)
        }

        // 3. Forward image to Python /analyze
        let aiResponse: AIAnalysisResponse
        switch postImageToPython(imageData: imageData) {
        case .success(let response):
            aiResponse = response
        case .failure(let err):
            return encode(encoder, ErrorResponse(error: "Python microservice error: \(err)"), statusCode: 502)
        }

        // 4. Parse subscription costs from OCR text (heuristic)
        let detectedSubscriptions = parseSubscriptions(from: aiResponse.extractedText)

        // 5. Compute subscription impact (requires at least one detected subscription)
        let impact: SubscriptionImpact? = detectedSubscriptions.isEmpty ? nil : {
            let subs = detectedSubscriptions.map { Subscription(name: $0.name, monthlyCost: $0.monthlyCost) }
            // Use conservative defaults for the impact calculation
            return SubscriptionImpactEngine.calculateImpact(
                subscriptions: subs,
                extraPayment: 200,   // Assume $200 extra/month if unknown
                payoffMonths: 36,    // Assume 3-year horizon if unknown
                totalInterest: 0
            )
        }()

        // 6. Build and return unified result
        let result = SubscriptionAnalysisResult(
            extractedText: aiResponse.extractedText,
            aiAnalysis: aiResponse.modelsOutput,
            finalSuggestions: aiResponse.finalSuggestions,
            subscriptionImpact: impact,
            detectedSubscriptions: detectedSubscriptions
        )
        return encode(encoder, result, statusCode: 200)
    }

    // MARK: - Private: Python Microservice Communication

    private static func pythonServiceIsHealthy() -> Bool {
        guard let url = URL(string: "\(pythonServiceURL)/health") else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        var isHealthy = false
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                isHealthy = true
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()
        return isHealthy
    }

    private static func postImageToPython(imageData: Data) -> Result<AIAnalysisResponse, ControllerError> {
        guard let url = URL(string: "\(pythonServiceURL)/analyze") else {
            return .failure(.invalidURL)
        }

        let boundary = "SwiftBoundary\(Int.random(in: 100000...999999))"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120  // OCR + 3 LLM calls can take a while

        // Build multipart body
        var body = Data()
        let crlf = "\r\n"
        body.append("--\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"screenshot.jpg\"\(crlf)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(crlf)\(crlf)".data(using: .utf8)!)
        body.append(imageData)
        body.append("\(crlf)--\(boundary)--\(crlf)".data(using: .utf8)!)
        request.httpBody = body

        var result: Result<AIAnalysisResponse, ControllerError> = .failure(.timeout)
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }

            if let error = error {
                result = .failure(.networkError(error.localizedDescription))
                return
            }
            guard let data = data else {
                result = .failure(.invalidResponse)
                return
            }
            do {
                let decoded = try JSONDecoder().decode(AIAnalysisResponse.self, from: data)
                result = .success(decoded)
            } catch {
                // Try to surface a Python error message instead
                if let errorObj = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    result = .failure(.networkError(errorObj.error))
                } else {
                    result = .failure(.networkError("Failed to decode Python response: \(error.localizedDescription)"))
                }
            }
        }.resume()

        semaphore.wait()
        return result
    }

    // MARK: - Private: Multipart Parsing

    /// Extracts the first file part's binary data from a raw multipart body.
    private static func extractImageData(from body: Data, boundary: String) -> Data? {
        let boundaryMarker = "--\(boundary)".data(using: .utf8)!
        let doubleCRLF = "\r\n\r\n".data(using: .utf8)!

        // Find first boundary
        guard let boundaryRange = body.range(of: boundaryMarker) else { return nil }

        // Find header/body separator
        let searchStart = boundaryRange.upperBound
        guard let headerEnd = body.range(of: doubleCRLF, in: searchStart..<body.endIndex) else { return nil }

        let contentStart = headerEnd.upperBound

        // Find closing boundary
        let closingMarker = "\r\n--\(boundary)".data(using: .utf8)!
        guard let closingRange = body.range(of: closingMarker, in: contentStart..<body.endIndex) else {
            return nil
        }

        return body[contentStart..<closingRange.lowerBound]
    }

    // MARK: - Private: Heuristic Subscription Parser

    /// Very lightweight regex-free parser that looks for cost patterns like
    /// "$9.99", "9.99/mo", "£12", "€5.99" in OCR text and associates them
    /// with adjacent words as subscription names.
    private static func parseSubscriptions(from text: String) -> [DetectedSubscription] {
        var results: [DetectedSubscription] = []

        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        for (i, word) in words.enumerated() {
            // Strip currency symbols and extract a numeric cost
            let stripped = word
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: "£", with: "")
                .replacingOccurrences(of: "€", with: "")
                .replacingOccurrences(of: "/mo", with: "")
                .replacingOccurrences(of: "/month", with: "")
                .replacingOccurrences(of: "/yr", with: "")
                .replacingOccurrences(of: "/year", with: "")

            guard let cost = Decimal(string: stripped), cost > 0.5, cost < 1000 else { continue }

            // Use the preceding word as the subscription name, fallback to "Subscription N"
            let name: String
            if i > 0, !(words[i - 1].first?.isNumber ?? true) {
                name = words[i - 1]
            } else if i + 1 < words.count {
                name = words[i + 1]
            } else {
                name = "Subscription \(results.count + 1)"
            }

            // Normalize to monthly cost (simple heuristic: > $50 = likely annual)
            let monthlyCost: Decimal
            if word.lowercased().contains("/yr") || word.lowercased().contains("/year") {
                monthlyCost = MoneyUtils.roundToTwoDecimals(cost / 12)
            } else {
                monthlyCost = MoneyUtils.roundToTwoDecimals(cost)
            }

            // Avoid duplicates
            if !results.contains(where: { $0.monthlyCost == monthlyCost && $0.name == name }) {
                results.append(DetectedSubscription(name: name, monthlyCost: monthlyCost))
            }
        }

        return results
    }

    // MARK: - Private: Response Encoding

    private static func encode<T: Encodable>(
        _ encoder: JSONEncoder,
        _ value: T,
        statusCode: Int
    ) -> (Int, String) {
        guard let data = try? encoder.encode(value),
              let str = String(data: data, encoding: .utf8) else {
            return (500, #"{"error":"Failed to encode response"}"#)
        }
        return (statusCode, str)
    }
}
