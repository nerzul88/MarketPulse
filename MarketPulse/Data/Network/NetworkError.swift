//
//  NetworkError.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 29.03.2026.
//

enum NetworkError: Error {
	case invalidURL
	case requestFailed(Error)
	case invalidResponse
	case unexpectedStatusCode(Int)
	case decodingFailed(Error)
}
