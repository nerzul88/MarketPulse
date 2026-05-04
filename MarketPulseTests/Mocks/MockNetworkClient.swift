//
//  MockNetworkClient.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

final class MockNetworkClient: NetworkClientProtocol {

	var result: Result<Any, Error>?

	func request<T>(_ endpoint: Endpoint) async throws -> T where T : Decodable {
		guard let result else {
			fatalError("Mock result was not set")
		}

		switch result {
		case .success(let value):
			guard let typedValue = value as? T else {
				fatalError("Mock value could not be cast to \(T.self)")
			}
			return typedValue

		case .failure(let error):
			throw error
		}
	}
}
