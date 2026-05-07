//
//  AssetDTO.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

import Foundation

struct AssetDTO: Decodable {
	let id: String
	let name: String
	let symbol: String
	let image: String?
	let currentPrice: Double?
	let priceChangePercentage24H: Double?
	let marketCap: Double?
	let high24H: Double?
	let low24H: Double?
}
