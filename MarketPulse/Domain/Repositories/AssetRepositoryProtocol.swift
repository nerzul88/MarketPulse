//
//  AssetRepositoryProtocol.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

protocol AssetRepositoryProtocol {
	func fetchAssets() async throws -> [Asset]
	func fetchAssetDetail(id: String) async throws -> AssetDetail
}
