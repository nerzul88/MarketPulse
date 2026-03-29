//
//  AssetRepositoryProtocol.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

import Foundation

protocol AssetRepositoryProtocol {
	func fetchAssets() async throws -> [Asset]
}
