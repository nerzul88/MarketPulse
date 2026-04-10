//
//  AssetRepository.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

import Foundation

final class AssetRepository: AssetRepositoryProtocol {

	private let networkClient: NetworkClientProtocol
	private let localStorage: AssetsLocalStorageProtocol

	init(
		networkClient: NetworkClientProtocol,
		localStorage: AssetsLocalStorageProtocol = AssetsLocalStorage()
	) {
		self.networkClient = networkClient
		self.localStorage = localStorage
	}

	func fetchAssets() async throws -> AssetsResponse {
		do {
			let dtos: [AssetDTO] = try await networkClient.request(AssetsEndpoint.markets())
			let assets = dtos.compactMap { $0.toDomain() }

			do {
				try localStorage.saveAssets(assets)
			} catch {
				print("Failed to cache assets: \(error)")
			}

			return AssetsResponse(
				assets: assets,
				lastUpdated: Date(),
				isFromCache: false
			)
		} catch {
			do {
				let cached = try localStorage.fetchAssets()
				return AssetsResponse(
					assets: cached.assets,
					lastUpdated: cached.lastUpdated,
					isFromCache: true
				)
			} catch {
				throw error
			}
		}
	}

	func fetchAssetDetail(id: String) async throws -> AssetDetail {
		let dto: AssetDetailDTO = try await networkClient.request(AssetsEndpoint.detail(id: id))

		guard let detail = dto.toDomain() else {
			throw NetworkError.invalidResponse
		}

		return detail
	}
}
