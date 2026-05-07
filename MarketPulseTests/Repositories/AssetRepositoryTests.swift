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
				priceChangePercentage24H: 2.5
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
				priceChangePercentage24H: 2.5
			),
			AssetDTO(
				id: "broken",
				name: "Broken",
				symbol: "brk",
				image: nil,
				currentPrice: nil,
				priceChangePercentage24H: 1.0
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
				priceChangePercentage24H: 2.5
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
				priceChangePercentage24H: 4.1
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
}
