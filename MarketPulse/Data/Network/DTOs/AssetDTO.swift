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
	let currentPrice: Double
	let priceChangePercentage24H: Double

	enum CodingKeys: String, CodingKey {
		case id
		case name
		case symbol
		case currentPrice = "current_price"
		case priceChangePercentage24H = "price_change_percentage_24h"
	}
}
