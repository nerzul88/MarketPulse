//
//  AssetRepositoryTests.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 12.04.2026.
//

import XCTest
@testable import MarketPulse

@MainActor
final class AssetRepositoryTests: XCTestCase {

	func test_fetchAssets_onNetworkSuccess_returnsFreshAssetsAndSavesCache() async throws {
		let networkClient = MockNetworkClient()
		let localStorage = MockAssetsLocalStorage()

		let dtos = [
			AssetDTO(
				id: "bitcoin",
				name: "Bitcoin",
				symbol: "btc",
				image: nil,
				currentPrice: 100_000,
				priceChangePercentage24H: 2.5,
				marketCap: 2_000_000_000,
				high24H: 101_500,
				low24H: 98_000
			)
		]

		networkClient.result = .success(dtos)

		let repository = AssetRepository(
			networkClient: networkClient,
			localStorage: localStorage
		)

		let response = try await repository.fetchAssets(page: 1, limit: 20)

		XCTAssertEqual(response.assets.count, 1)
		XCTAssertFalse(response.isFromCache)
		XCTAssertEqual(response.page, 1)
		XCTAssertFalse(response.canLoadMore)
		XCTAssertTrue(localStorage.saveWasCalled)
		XCTAssertEqual(localStorage.savedAssets.first?.id, "bitcoin")
	}

	func test_fetchAssets_onNetworkSuccess_filtersOutInvalidDTOs() async throws {
		let networkClient = MockNetworkClient()
		let localStorage = MockAssetsLocalStorage()

		networkClient.result = .success([
			AssetDTO(
				id: "bitcoin",
				name: "Bitcoin",
				symbol: "btc",
				image: nil,
				currentPrice: 100_000,
				priceChangePercentage24H: 2.5,
				marketCap: 2_000_000_000,
				high24H: 101_500,
				low24H: 98_000
			),
			AssetDTO(
				id: "broken",
				name: "Broken",
				symbol: "brk",
				image: nil,
				currentPrice: nil,
				priceChangePercentage24H: 1.0,
				marketCap: nil,
				high24H: nil,
				low24H: nil
			)
		])

		let repository = AssetRepository(
			networkClient: networkClient,
			localStorage: localStorage
		)

		let response = try await repository.fetchAssets(page: 1, limit: 20)

		XCTAssertEqual(response.assets, [Asset.mock(id: "bitcoin", name: "Bitcoin", symbol: "BTC")])
		XCTAssertEqual(localStorage.savedAssets, response.assets)
	}

	func test_fetchAssets_whenSavingCacheFails_stillReturnsFreshAssets() async throws {
		let networkClient = MockNetworkClient()
		let localStorage = MockAssetsLocalStorage()

		networkClient.result = .success([
			AssetDTO(
				id: "bitcoin",
				name: "Bitcoin",
				symbol: "btc",
				image: nil,
				currentPrice: 100_000,
				priceChangePercentage24H: 2.5,
				marketCap: 2_000_000_000,
				high24H: 101_500,
				low24H: 98_000
			)
		])
		localStorage.saveResult = .failure(TestError.somethingWentWrong)

		let repository = AssetRepository(
			networkClient: networkClient,
			localStorage: localStorage
		)

		let response = try await repository.fetchAssets(page: 1, limit: 20)

		XCTAssertEqual(response.assets.count, 1)
		XCTAssertFalse(response.isFromCache)
		XCTAssertTrue(localStorage.saveWasCalled)
	}

	func test_fetchAssets_onNetworkFailure_returnsCachedAssets() async throws {
		let networkClient = MockNetworkClient()
		let localStorage = MockAssetsLocalStorage()

		networkClient.result = .failure(TestError.somethingWentWrong)

		let cachedAssets = [
			Asset.mock(id: "ethereum", name: "Ethereum", symbol: "ETH")
		]

		localStorage.fetchResult = .success(
			CachedAssets(assets: cachedAssets, lastUpdated: Date())
		)

		let repository = AssetRepository(
			networkClient: networkClient,
			localStorage: localStorage
		)

		let response = try await repository.fetchAssets(page: 1, limit: 20)

		XCTAssertEqual(response.assets, cachedAssets)
		XCTAssertTrue(response.isFromCache)
		XCTAssertFalse(response.canLoadMore)
		XCTAssertTrue(localStorage.fetchWasCalled)
	}

	func test_fetchAssets_whenNetworkAndCacheFail_rethrowsNetworkError() async {
		let networkClient = MockNetworkClient()
		let localStorage = MockAssetsLocalStorage()

		networkClient.result = .failure(TestError.somethingWentWrong)
		localStorage.fetchResult = .failure(NetworkError.invalidResponse)

		let repository = AssetRepository(
			networkClient: networkClient,
			localStorage: localStorage
		)

		do {
			_ = try await repository.fetchAssets(page: 1, limit: 20)
			XCTFail("Expected fetchAssets to throw")
		} catch {
			XCTAssertEqual(error as? TestError, .somethingWentWrong)
		}
	}

	func test_fetchAssets_onSecondPageSuccess_doesNotOverwriteCache() async throws {
		let networkClient = MockNetworkClient()
		let localStorage = MockAssetsLocalStorage()

		networkClient.result = .success([
			AssetDTO(
				id: "solana",
				name: "Solana",
				symbol: "sol",
				image: nil,
				currentPrice: 150,
				priceChangePercentage24H: 4.1,
				marketCap: 75_000_000_000,
				high24H: 155,
				low24H: 145
			)
		])

		let repository = AssetRepository(
			networkClient: networkClient,
			localStorage: localStorage
		)

		let response = try await repository.fetchAssets(page: 2, limit: 20)

		XCTAssertEqual(response.page, 2)
		XCTAssertFalse(localStorage.saveWasCalled)
	}

	func test_fetchAssets_onSecondPageFailure_rethrowsNetworkErrorWithoutCacheFallback() async {
		let networkClient = MockNetworkClient()
		let localStorage = MockAssetsLocalStorage()

		networkClient.result = .failure(TestError.somethingWentWrong)
		localStorage.fetchResult = .success(
			CachedAssets(assets: [Asset.mock()], lastUpdated: Date())
		)

		let repository = AssetRepository(
			networkClient: networkClient,
			localStorage: localStorage
		)

		do {
			_ = try await repository.fetchAssets(page: 2, limit: 20)
			XCTFail("Expected fetchAssets to throw")
		} catch {
			XCTAssertEqual(error as? TestError, .somethingWentWrong)
			XCTAssertFalse(localStorage.fetchWasCalled)
		}
	}

	func test_fetchAssetDetail_onSuccess_returnsMappedDetail() async throws {
		let networkClient = MockNetworkClient()
		let localStorage = MockAssetsLocalStorage()

		networkClient.result = .success(
			AssetDetailDTO(
				id: "bitcoin",
				name: "Bitcoin",
				symbol: "btc",
				marketData: MarketDataDTO(
					currentPrice: ["usd": 100_000],
					priceChangePercentage24H: 2.5,
					marketCap: ["usd": 2_000_000_000],
					high24H: ["usd": 101_500],
					low24H: ["usd": 98_000]
				),
				description: DescriptionDTO(en: "<p>Digital gold</p>")
			)
		)

		let repository = AssetRepository(
			networkClient: networkClient,
			localStorage: localStorage
		)

		let detail = try await repository.fetchAssetDetail(id: "bitcoin")

		XCTAssertEqual(
			detail,
			AssetDetail(
				id: "bitcoin",
				name: "Bitcoin",
				symbol: "BTC",
				price: 100_000,
				change24h: 2.5,
				marketCap: 2_000_000_000,
				high24h: 101_500,
				low24h: 98_000,
				overview: "Digital gold"
			)
		)
	}

	func test_fetchAssetDetail_whenMappingFails_throwsInvalidResponse() async {
		let networkClient = MockNetworkClient()
		let localStorage = MockAssetsLocalStorage()

		networkClient.result = .success(
			AssetDetailDTO(
				id: "bitcoin",
				name: "Bitcoin",
				symbol: "btc",
				marketData: MarketDataDTO(
					currentPrice: nil,
					priceChangePercentage24H: nil,
					marketCap: nil,
					high24H: nil,
					low24H: nil
				),
				description: DescriptionDTO(en: nil)
			)
		)

		let repository = AssetRepository(
			networkClient: networkClient,
			localStorage: localStorage
		)

		do {
			_ = try await repository.fetchAssetDetail(id: "bitcoin")
			XCTFail("Expected fetchAssetDetail to throw")
		} catch NetworkError.invalidResponse {
		} catch {
			XCTFail("Expected invalidResponse, got \(error)")
		}
	}

	func test_fetchAssetDetail_whenDetailIsCached_returnsCachedValueWithoutNetworkCall() async throws {
		let networkClient = MockNetworkClient()
		let localStorage = MockAssetsLocalStorage()

		networkClient.result = .success(
			AssetDetailDTO(
				id: "bitcoin",
				name: "Bitcoin",
				symbol: "btc",
				marketData: MarketDataDTO(
					currentPrice: ["usd": 100_000],
					priceChangePercentage24H: 2.5,
					marketCap: ["usd": 2_000_000_000],
					high24H: ["usd": 101_500],
					low24H: ["usd": 98_000]
				),
				description: DescriptionDTO(en: "<p>Digital gold</p>")
			)
		)

		let repository = AssetRepository(
			networkClient: networkClient,
			localStorage: localStorage
		)

		let firstDetail = try await repository.fetchAssetDetail(id: "bitcoin")
		networkClient.result = .failure(NetworkError.unexpectedStatusCode(429))
		let secondDetail = try await repository.fetchAssetDetail(id: "bitcoin")

		XCTAssertEqual(firstDetail, secondDetail)
	}

	func test_fetchAssetDetail_whenRateLimited_retriesAndReturnsDetail() async throws {
		let networkClient = MockNetworkClient()
		let localStorage = MockAssetsLocalStorage()

		networkClient.resultsQueue = [
			.failure(NetworkError.unexpectedStatusCode(429)),
			.success(
				AssetDetailDTO(
					id: "bitcoin",
					name: "Bitcoin",
					symbol: "btc",
					marketData: MarketDataDTO(
						currentPrice: ["usd": 100_000],
						priceChangePercentage24H: 2.5,
						marketCap: ["usd": 2_000_000_000],
						high24H: ["usd": 101_500],
						low24H: ["usd": 98_000]
					),
					description: DescriptionDTO(en: "<p>Digital gold</p>")
				)
			)
		]

		let repository = AssetRepository(
			networkClient: networkClient,
			localStorage: localStorage
		)

		let detail = try await repository.fetchAssetDetail(id: "bitcoin")

		XCTAssertEqual(detail.name, "Bitcoin")
		XCTAssertEqual(detail.marketCap, 2_000_000_000)
	}

	func test_fetchAssetDetail_whenPersistedDetailExists_returnsItWithoutNetworkCall() async throws {
		let suiteName = "AssetRepositoryTests.PersistentDetail.\(UUID().uuidString)"
		let userDefaults = UserDefaults(suiteName: suiteName)!
		userDefaults.removePersistentDomain(forName: suiteName)
		defer {
			userDefaults.removePersistentDomain(forName: suiteName)
		}

		let persistedDetail = AssetDetail(
			id: "solana",
			name: "Solana",
			symbol: "SOL",
			price: 89.04,
			change24h: 0.43,
			marketCap: 513_924_003_02,
			high24h: 90.28,
			low24h: 87.72,
			overview: "Solana overview"
		)

		let persistedPayload = [
			"solana": PersistedAssetDetailPayload(
				id: persistedDetail.id,
				name: persistedDetail.name,
				symbol: persistedDetail.symbol,
				price: persistedDetail.price,
				change24h: persistedDetail.change24h,
				marketCap: persistedDetail.marketCap,
				high24h: persistedDetail.high24h,
				low24h: persistedDetail.low24h,
				overview: persistedDetail.overview
			)
		]
		let encodedPayload = try XCTUnwrap(try? JSONEncoder().encode(persistedPayload))
		userDefaults.set(encodedPayload, forKey: "persisted_asset_details")

		let repository = AssetRepository(
			networkClient: MockNetworkClient(),
			localStorage: MockAssetsLocalStorage(),
			userDefaults: userDefaults
		)

		let detail = try await repository.fetchAssetDetail(id: "solana")

		XCTAssertEqual(detail, persistedDetail)
	}
}

private struct PersistedAssetDetailPayload: Codable {
	let id: String
	let name: String
	let symbol: String
	let price: Double
	let change24h: Double
	let marketCap: Double?
	let high24h: Double?
	let low24h: Double?
	let overview: String?
}
