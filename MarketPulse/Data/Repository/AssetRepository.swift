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
		let dtos: [AssetDTO] = try await networkClient.request(AssetsEndpoint.markets())
		return dtos.compactMap { $0.toDomain() }
	}

	func fetchAssetDetail(id: String) async throws -> AssetDetail {
		let dto: AssetDetailDTO = try await networkClient.request(AssetsEndpoint.detail(id: id))

		guard let detail = dto.toDomain() else {
			throw NetworkError.invalidResponse
		}

		return detail
	}
}
