//
//  Endpoint.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

import Foundation

enum HTTPMethod: String {
	case get = "GET"
	case post = "POST"
}

struct Endpoint {
	let path: String
	let method: HTTPMethod
	let queryItems: [URLQueryItem]
}
