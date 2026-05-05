//
//  MockAssetRepository.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 12.04.2026.
//

@testable import MarketPulse

final class MockAssetRepository: AssetRepositoryProtocol {

	var fetchAssetsResult: Result<AssetsResponse, Error>?
	var fetchAssetsResultsByPage: [Int: Result<AssetsResponse, Error>] = [:]
	var fetchAssetsDelayByPage: [Int: UInt64] = [:]
	var fetchAssetsHandler: ((Int, Int) async throws -> AssetsResponse)?
	var fetchAssetDetailResult: Result<AssetDetail, Error>?
	var fetchAssetsCallCount = 0
	var lastFetchAssetsPage: Int?
	var lastFetchAssetsLimit: Int?
	var lastFetchAssetDetailID: String?

	func fetchAssets(page: Int, limit: Int) async throws -> AssetsResponse {
		fetchAssetsCallCount += 1
		lastFetchAssetsPage = page
		lastFetchAssetsLimit = limit

		if let fetchAssetsHandler {
			return try await fetchAssetsHandler(page, limit)
		}

		if let delay = fetchAssetsDelayByPage[page] {
			try? await Task.sleep(nanoseconds: delay)
		}

		if let result = fetchAssetsResultsByPage[page] {
			return try result.get()
		}

		guard let result = fetchAssetsResult else {
			fatalError("fetchAssetsResult was not set")
		}

		return try result.get()
	}

	func fetchAssetDetail(id: String) async throws -> AssetDetail {
		lastFetchAssetDetailID = id

		guard let result = fetchAssetDetailResult else {
			fatalError("fetchAssetDetailResult was not set")
		}

		return try result.get()
	}
}
