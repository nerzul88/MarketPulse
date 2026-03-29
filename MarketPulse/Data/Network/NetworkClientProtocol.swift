//
//  NetworkClientProtocol.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

import Foundation

protocol NetworkClientProtocol {
	func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}
