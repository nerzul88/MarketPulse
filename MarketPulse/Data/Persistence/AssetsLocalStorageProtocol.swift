//
//  AssetsLocalStorageProtocol.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 10.04.2026.
//

protocol AssetsLocalStorageProtocol {
	func saveAssets(_ assets: [Asset]) throws
	func fetchAssets() throws -> CachedAssets
}
