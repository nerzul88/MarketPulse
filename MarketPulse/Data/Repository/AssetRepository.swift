//
//  AssetRepository.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

import Foundation

final class AssetRepository: AssetRepositoryProtocol {

	private let networkClient: NetworkClientProtocol

	init(networkClient: NetworkClientProtocol) {
		self.networkClient = networkClient
	}

	func fetchAssets() async throws -> [Asset] {
		// пока просто заглушка
		return []
	}
}
