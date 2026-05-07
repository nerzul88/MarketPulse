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
	private let userDefaults: UserDefaults
	private var assetDetailsCache: [String: AssetDetail] = [:]
	private let detailRetryDelays: [UInt64] = [
		500_000_000,
		1_000_000_000
	]
	private let detailRequestLimiter = DetailRequestLimiter()

	init(
		networkClient: NetworkClientProtocol,
		localStorage: AssetsLocalStorageProtocol = AssetsLocalStorage(),
		userDefaults: UserDefaults = .standard
	) {
		self.networkClient = networkClient
		self.localStorage = localStorage
		self.userDefaults = userDefaults
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
		if let cachedDetail = assetDetailsCache[id] {
			return cachedDetail
		}

		if let persistedDetail = loadPersistedDetail(id: id) {
			assetDetailsCache[id] = persistedDetail
			return persistedDetail
		}

		do {
			let detail = try await requestAssetDetail(id: id)
			assetDetailsCache[id] = detail
			persistDetail(detail)
			return detail
		} catch {
			if let persistedDetail = loadPersistedDetail(id: id) {
				assetDetailsCache[id] = persistedDetail
				return persistedDetail
			}

			if let cachedDetail = assetDetailsCache[id] {
				return cachedDetail
			}

			throw error
		}
	}

	private func requestAssetDetail(id: String) async throws -> AssetDetail {
		var retryAttempt = 0

		while true {
			do {
				await detailRequestLimiter.waitIfNeeded()
				let dto: AssetDetailDTO = try await networkClient.request(AssetsEndpoint.detail(id: id))

				guard let detail = dto.toDomain() else {
					throw NetworkError.invalidResponse
				}

				return detail
			} catch let NetworkError.unexpectedStatusCode(statusCode)
				where statusCode == 429 && retryAttempt < detailRetryDelays.count {
				let delay = detailRetryDelays[retryAttempt]
				retryAttempt += 1
				try await Task.sleep(nanoseconds: delay)
			} catch {
				throw error
			}
		}
	}
}

private actor DetailRequestLimiter {
	private let minimumIntervalNanoseconds: UInt64 = 1_500_000_000
	private var lastRequestStartedAt: UInt64?

	func waitIfNeeded() async {
		let now = DispatchTime.now().uptimeNanoseconds

		if let lastRequestStartedAt {
			let elapsed = now &- lastRequestStartedAt

			if elapsed < minimumIntervalNanoseconds {
				let remainingDelay = minimumIntervalNanoseconds - elapsed
				try? await Task.sleep(nanoseconds: remainingDelay)
			}
		}

		lastRequestStartedAt = DispatchTime.now().uptimeNanoseconds
	}
}

private extension AssetRepository {
	var persistedDetailsStorageKey: String { "persisted_asset_details" }

	func loadPersistedDetail(id: String) -> AssetDetail? {
		guard
			let data = userDefaults.data(forKey: persistedDetailsStorageKey),
			let persistedDetails = try? JSONDecoder().decode([String: PersistedAssetDetail].self, from: data),
			let persistedDetail = persistedDetails[id]
		else {
			return nil
		}

		return persistedDetail.assetDetail
	}

	func persistDetail(_ detail: AssetDetail) {
		var persistedDetails: [String: PersistedAssetDetail] = [:]

		if
			let data = userDefaults.data(forKey: persistedDetailsStorageKey),
			let decodedDetails = try? JSONDecoder().decode([String: PersistedAssetDetail].self, from: data)
		{
			persistedDetails = decodedDetails
		}

		persistedDetails[detail.id] = PersistedAssetDetail(assetDetail: detail)

		if let encoded = try? JSONEncoder().encode(persistedDetails) {
			userDefaults.set(encoded, forKey: persistedDetailsStorageKey)
		}
	}
}

private struct PersistedAssetDetail: Codable {
	let id: String
	let name: String
	let symbol: String
	let price: Double
	let change24h: Double
	let marketCap: Double?
	let high24h: Double?
	let low24h: Double?
	let overview: String?

	init(assetDetail: AssetDetail) {
		id = assetDetail.id
		name = assetDetail.name
		symbol = assetDetail.symbol
		price = assetDetail.price
		change24h = assetDetail.change24h
		marketCap = assetDetail.marketCap
		high24h = assetDetail.high24h
		low24h = assetDetail.low24h
		overview = assetDetail.overview
	}

	var assetDetail: AssetDetail {
		AssetDetail(
			id: id,
			name: name,
			symbol: symbol,
			price: price,
			change24h: change24h,
			marketCap: marketCap,
			high24h: high24h,
			low24h: low24h,
			overview: overview
		)
	}
}
