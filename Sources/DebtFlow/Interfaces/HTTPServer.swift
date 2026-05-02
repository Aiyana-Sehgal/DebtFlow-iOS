import Foundation
#if os(Windows)
import WinSDK
#elseif os(Linux)
import Glibc
#else
import Darwin
#endif

typealias SOCKET = Int32

// MARK: - Server Bootstrap

func startServer(port: UInt16) {
    #if os(Windows)
    var wsaData = WSADATA()
    WSAStartup(0x0202, &wsaData)
    #endif

    let serverFd = socket(AF_INET, SOCK_STREAM, 0)

    #if os(Windows)
    guard serverFd != INVALID_SOCKET else {
        print("Failed to create socket"); return
    }
    #else
    guard serverFd >= 0 else {
        print("Failed to create socket"); return
    }
    #endif

    var opt: Int32 = 1
    setsockopt(serverFd, SOL_SOCKET, SO_REUSEADDR, &opt, socklen_t(MemoryLayout<Int32>.size))

    var addr = sockaddr_in()
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = port.bigEndian

    #if os(Windows)
    addr.sin_addr = IN_ADDR()
    #else
    addr.sin_addr.s_addr = INADDR_ANY
    #endif

    let bindResult = withUnsafePointer(to: &addr) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            bind(serverFd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }

    guard bindResult == 0 else {
        print("Bind failed. Is port \(port) already in use?"); return
    }

    listen(serverFd, 10)
    print("DebtFlow HTTP server running on http://localhost:\(port)")
    print("Endpoints:")
    print("  POST /calculate")
    print("  POST /compare")
    print("  POST /api/subscriptions/analyze  (multipart/form-data — requires Python AI service on :8000)")
    print("  GET  /\n")

    while true {
        #if os(Windows)
        let clientFd = accept(serverFd, nil, nil)
        guard clientFd != INVALID_SOCKET else { continue }
        #else
        let clientFd = accept(serverFd, nil, nil)
        guard clientFd >= 0 else { continue }
        #endif

        handleClient(fd: clientFd)

        #if os(Windows)
        closesocket(clientFd)
        #else
        close(clientFd)
        #endif
    }
}

// MARK: - Client Handler

private func handleClient(fd: SOCKET) {

    // -------------------------------------------------------------------------
    // Read the full HTTP request into a Data buffer.
    // Images can be several MB, so we loop until we have read Content-Length
    // bytes past the header boundary.
    // -------------------------------------------------------------------------
    var rawData = Data()
    var chunk = [UInt8](repeating: 0, count: 65536)    // 64 KB per read

    // Phase 1: read until we find the header/body separator
    var headerData = Data()
    var headerDone = false
    let headerSep = Data([0x0D, 0x0A, 0x0D, 0x0A])    // \r\n\r\n

    while !headerDone {
        #if os(Windows)
        let n = recv(fd, &chunk, Int32(chunk.count), 0)
        guard n > 0 else { return }
        let read = Int(n)
        #else
        let n = recv(fd, &chunk, chunk.count, 0)
        guard n > 0 else { return }
        let read = n
        #endif

        rawData.append(contentsOf: chunk.prefix(read))
        if let _ = rawData.range(of: headerSep) {
            headerDone = true
        }
    }

    // Parse the headers
    guard let sepRange = rawData.range(of: headerSep) else { return }
    headerData = rawData[rawData.startIndex..<sepRange.lowerBound]
    let bodyStart = sepRange.upperBound

    guard let headerString = String(data: headerData, encoding: .utf8) else { return }
    let headerLines = headerString.components(separatedBy: "\r\n")
    guard let requestLine = headerLines.first else { return }

    let parts = requestLine.components(separatedBy: " ")
    guard parts.count >= 2 else { return }
    let method = parts[0]
    let path   = parts[1]

    print("Request: \(method) \(path)")

    // Extract Content-Length if present so we know how much body to read
    var contentLength = 0
    var contentType   = ""
    for line in headerLines.dropFirst() {
        let lower = line.lowercased()
        if lower.hasPrefix("content-length:") {
            let value = line.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)
            contentLength = Int(value) ?? 0
        }
        if lower.hasPrefix("content-type:") {
            contentType = String(line.dropFirst("content-type:".count).trimmingCharacters(in: .whitespaces))
        }
    }

    // Phase 2: read remainder of body if Content-Length says there's more
    var bodyData = rawData[bodyStart...]
    let remaining = contentLength - bodyData.count
    if remaining > 0 {
        var toRead = remaining
        while toRead > 0 {
            let chunkSize = min(toRead, chunk.count)
            #if os(Windows)
            let n = recv(fd, &chunk, Int32(chunkSize), 0)
            guard n > 0 else { break }
            let read = Int(n)
            #else
            let n = recv(fd, &chunk, chunkSize, 0)
            guard n > 0 else { break }
            let read = n
            #endif
            bodyData.append(contentsOf: chunk.prefix(read))
            toRead -= read
        }
    }

    let fullBodyData = Data(bodyData)

    // -------------------------------------------------------------------------
    // Route the request
    // -------------------------------------------------------------------------
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    var statusCode   = 200
    var statusText   = "OK"
    var responseBody = ""

    if method == "POST" {

        // --- /calculate -------------------------------------------------------
        if path == "/calculate" {
            if let request = try? JSONDecoder().decode(DebtPayoffRequest.self, from: fullBodyData) {
                let result = PayoffEngine.calculate(request: request)
                if let json = try? encoder.encode(result),
                   let str  = String(data: json, encoding: .utf8) {
                    responseBody = str
                } else {
                    statusCode = 500; statusText = "Internal Server Error"
                    responseBody = #"{"error":"Failed to encode response"}"#
                }
            } else {
                statusCode = 400; statusText = "Bad Request"
                responseBody = #"{"error":"Invalid JSON. Check your request body."}"#
            }

        // --- /compare ---------------------------------------------------------
        } else if path == "/compare" {
            if let original = try? JSONDecoder().decode(DebtPayoffRequest.self, from: fullBodyData) {
                let av = PayoffEngine.calculate(request: DebtPayoffRequest(
                    debts: original.debts, extraMonthlyPayment: original.extraMonthlyPayment,
                    strategy: .avalanche,  subscriptions: original.subscriptions))
                let sn = PayoffEngine.calculate(request: DebtPayoffRequest(
                    debts: original.debts, extraMonthlyPayment: original.extraMonthlyPayment,
                    strategy: .snowball,   subscriptions: original.subscriptions))
                let mo = PayoffEngine.calculate(request: DebtPayoffRequest(
                    debts: original.debts, extraMonthlyPayment: original.extraMonthlyPayment,
                    strategy: .momentum,   subscriptions: original.subscriptions))

                struct Comparison: Codable {
                    let avalanche: PayoffResult
                    let snowball: PayoffResult
                    let momentum: PayoffResult
                    let recommendation: String
                    let interestSavedByAvalanche: Decimal
                    let interestSavedByMomentum: Decimal
                }

                let savedAv = sn.totalInterestPaid - av.totalInterestPaid
                let savedMo = sn.totalInterestPaid - mo.totalInterestPaid
                let rec: String
                if savedMo > savedAv {
                    rec = "Momentum strategy recommended: Combines quick wins with long-term savings."
                } else if savedAv > 0 {
                    rec = "Avalanche strategy recommended: Saves the most interest."
                } else {
                    rec = "Snowball strategy recommended: Builds motivation through quick wins."
                }
                let comparison = Comparison(
                    avalanche: av, snowball: sn, momentum: mo,
                    recommendation: rec,
                    interestSavedByAvalanche: MoneyUtils.roundToTwoDecimals(savedAv),
                    interestSavedByMomentum:  MoneyUtils.roundToTwoDecimals(savedMo))

                if let json = try? encoder.encode(comparison),
                   let str  = String(data: json, encoding: .utf8) {
                    responseBody = str
                } else {
                    statusCode = 500; statusText = "Internal Server Error"
                    responseBody = #"{"error":"Failed to encode response"}"#
                }
            } else {
                statusCode = 400; statusText = "Bad Request"
                responseBody = #"{"error":"Invalid JSON. Check your request body."}"#
            }

        // --- /api/subscriptions/analyze (NEW) ---------------------------------
        } else if path == "/api/subscriptions/analyze" {
            // Extract multipart boundary from Content-Type header
            // e.g. "multipart/form-data; boundary=----WebKitFormBoundaryXYZ"
            let boundary = extractBoundary(from: contentType)

            if let boundary = boundary, !boundary.isEmpty {
                let (code, body) = SubscriptionController.analyze(
                    multipartBody: fullBodyData,
                    boundary: boundary
                )
                statusCode = code
                statusText = code == 200 ? "OK" : (code == 400 ? "Bad Request" : "Service Error")
                responseBody = body
            } else {
                statusCode = 400; statusText = "Bad Request"
                responseBody = #"{"error":"Missing or invalid Content-Type. Expected multipart/form-data with boundary."}"#
            }

        // --- Unknown POST path ------------------------------------------------
        } else {
            statusCode = 404; statusText = "Not Found"
            responseBody = #"{"error":"Unknown endpoint. Use /calculate, /compare, or /api/subscriptions/analyze"}"#
        }

    // --- GET / ----------------------------------------------------------------
    } else if method == "GET" && path == "/" {
        responseBody = #"{"status":"DebtFlow running","endpoints":["/calculate","/compare","/api/subscriptions/analyze"]}"#

    // --- Any other method -----------------------------------------------------
    } else {
        statusCode = 405; statusText = "Method Not Allowed"
        responseBody = #"{"error":"Method not allowed."}"#
    }

    sendResponse(fd: fd, statusCode: statusCode, statusText: statusText, body: responseBody)
}

// MARK: - Helpers

/// Pulls the boundary token out of a Content-Type header value like:
/// `multipart/form-data; boundary=----WebKitFormBoundaryABC`
private func extractBoundary(from contentType: String) -> String? {
    let parts = contentType.components(separatedBy: ";")
    for part in parts {
        let trimmed = part.trimmingCharacters(in: .whitespaces)
        if trimmed.lowercased().hasPrefix("boundary=") {
            return String(trimmed.dropFirst("boundary=".count))
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
    }
    return nil
}

/// Builds and sends an HTTP/1.1 response over the given socket.
private func sendResponse(fd: SOCKET, statusCode: Int, statusText: String, body: String) {
    let header = "HTTP/1.1 \(statusCode) \(statusText)\r\n" +
                 "Content-Type: application/json\r\n" +
                 "Content-Length: \(body.utf8.count)\r\n" +
                 "Access-Control-Allow-Origin: *\r\n" +
                 "\r\n"

    var responseData = Data()
    responseData.append(header.data(using: .utf8)!)
    responseData.append(body.data(using: .utf8)!)

    #if os(Windows)
    _ = responseData.withUnsafeBytes { buf in
        send(fd, buf.baseAddress, Int32(buf.count), 0)
    }
    #else
    _ = responseData.withUnsafeBytes { buf in
        send(fd, buf.baseAddress, buf.count, 0)
    }
    #endif
}
