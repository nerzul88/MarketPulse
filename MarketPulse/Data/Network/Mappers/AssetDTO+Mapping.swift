//
//  AssetDTO+Mapping.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

import Foundation

extension AssetDTO {
	func toDomain() -> Asset {
		Asset(
			id: id,
			name: name,
			symbol: symbol.uppercased(),
			price: currentPrice,
			change24h: priceChangePercentage24H
		)
	}
}
