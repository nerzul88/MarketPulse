//
//  NetworkError.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 29.03.2026.
//

import Foundation

enum NetworkError: Error {
	case invalidURL
	case requestFailed(Error)
	case invalidResponse
	case unexpectedStatusCode(Int)
	case decodingFailed(Error)
}

extension NetworkError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .invalidURL:
			return "Failed to build the request URL."
		case .requestFailed(let error):
			return "Network request failed: \(error.localizedDescription)"
		case .invalidResponse:
			return "Received an invalid response from the server."
		case .unexpectedStatusCode(let statusCode):
			return "Server returned an unexpected status code: \(statusCode)."
		case .decodingFailed:
			return "Failed to decode data from the server."
		}
	}
}
