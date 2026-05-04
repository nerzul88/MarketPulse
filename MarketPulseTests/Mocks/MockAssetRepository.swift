//
//  MockAssetRepository.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 12.04.2026.
//

@testable import MarketPulse

final class MockAssetRepository: AssetRepositoryProtocol {

	var fetchAssetsResult: Result<AssetsResponse, Error>?
	var fetchAssetDetailResult: Result<AssetDetail, Error>?
	var fetchAssetsCallCount = 0
	var lastFetchAssetDetailID: String?

	func fetchAssets() async throws -> AssetsResponse {
		fetchAssetsCallCount += 1

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
