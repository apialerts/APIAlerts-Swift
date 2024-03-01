//
//  File.swift
//  
//
//  Created by Mononz on 1/3/2024.
//

import Combine
import Foundation
import SwiftUI

func getEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .useDefaultKeys
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}

func getDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}

enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public class ApiClient {
    public static let shared = ApiClient()

    private init() {}

    private func buildHeaders(_ apiKey: String) async -> [String: String] {
        var headers = [String: String]()
        headers["Authorization"] = "Bearer \(apiKey)"
        headers["Content-Type"] = "application/json"
        headers["X-Integration"] = INTEGRATION_NAME
        headers["X-Version"] = INTEGRATION_VERSION
        return headers
    }

    func request<T: Codable>(apiKey: String, method: HttpMethod, path: String, body: Data? = nil) async -> (Result<T, ErrorObject>) {
        guard let url = URL(string: API_URL + path) else {
            let output = ErrorObject(
                statusCode: 0,
                message: "Invalid request"
            )
            return .failure(output)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = await buildHeaders(apiKey)

        if let body = body {
            request.httpBody = body
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            var statusCode = 0
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
                if statusCode == 200 {
                    let jsonData = try getDecoder().decode(T.self, from: data)
                    return .success(jsonData)
                }
            }
            
            let error = try getDecoder().decode(ErrorResponse.self, from: data)
            let output = ErrorObject(
                statusCode: statusCode,
                message: error.message ?? "Unknown Error"
            )
            return .failure(output)
        } catch {
            let output = ErrorObject(
                statusCode: 0,
                message: "Something went wrong"
            )
            return .failure(output)
        }
    }
}