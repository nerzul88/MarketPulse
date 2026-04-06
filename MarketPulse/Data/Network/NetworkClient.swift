//
//  NetworkClient.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 29.03.2026.
//

import Foundation

final class NetworkClient: NetworkClientProtocol {

	private let session: URLSession
	private let configuration: NetworkConfiguration
	private let decoder: JSONDecoder

	init(
		session: URLSession = .shared,
		configuration: NetworkConfiguration = .default,
		decoder: JSONDecoder = {
			let decoder = JSONDecoder()
			decoder.keyDecodingStrategy = .convertFromSnakeCase
			return decoder
		}()
	) {
		self.session = session
		self.configuration = configuration
		self.decoder = decoder
	}

	func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
		guard var urlComponents = URLComponents(string: configuration.baseURL) else {
			throw NetworkError.invalidURL
		}

		urlComponents.path += endpoint.path
		urlComponents.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

		guard let url = urlComponents.url else {
			throw NetworkError.invalidURL
		}

		var request = URLRequest(url: url)
		request.httpMethod = endpoint.method.rawValue

		endpoint.headers.forEach { key, value in
			request.setValue(value, forHTTPHeaderField: key)
		}

		let data: Data
		let response: URLResponse

		do {
			(data, response) = try await session.data(for: request)
		} catch {
			throw NetworkError.requestFailed(error)
		}

		guard let httpResponse = response as? HTTPURLResponse else {
			throw NetworkError.invalidResponse
		}

		guard 200...299 ~= httpResponse.statusCode else {
			throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
		}

		do {
			return try decoder.decode(T.self, from: data)
		} catch {
			throw NetworkError.decodingFailed(error)
		}
	}
}
