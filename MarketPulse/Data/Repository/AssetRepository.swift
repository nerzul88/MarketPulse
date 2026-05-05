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

	func fetchAssets(page: Int, limit: Int) async throws -> AssetsResponse {
		do {
			let dtos: [AssetDTO] = try await networkClient.request(
				AssetsEndpoint.markets(page: page, perPage: limit)
			)
			let assets = dtos.compactMap { $0.toDomain() }

			if page == 1 {
				do {
					try localStorage.saveAssets(assets)
				} catch {
					print("Failed to cache assets: \(error)")
				}
			}

			return AssetsResponse(
				assets: assets,
				lastUpdated: Date(),
				isFromCache: false,
				page: page,
				canLoadMore: assets.count == limit
			)
		} catch let networkError {
			guard page == 1 else {
				throw networkError
			}

			do {
				let cached = try localStorage.fetchAssets()
				return AssetsResponse(
					assets: cached.assets,
					lastUpdated: cached.lastUpdated,
					isFromCache: true,
					page: 1,
					canLoadMore: false
				)
			} catch {
				throw networkError
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
