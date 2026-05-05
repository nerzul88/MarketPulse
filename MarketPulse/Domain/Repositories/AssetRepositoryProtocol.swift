//
//  AssetRepositoryProtocol.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

protocol AssetRepositoryProtocol {
	func fetchAssets(page: Int, limit: Int) async throws -> AssetsResponse
	func fetchAssetDetail(id: String) async throws -> AssetDetail
}
