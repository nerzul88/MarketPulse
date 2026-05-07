//
//  AssetDTO+Mapping.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 22.03.2026.
//

import Foundation

extension AssetDTO {
	func toDomain() -> Asset? {
		guard let currentPrice else { return nil }

		return Asset(
			id: id,
			name: name,
			symbol: symbol.uppercased(),
			imageURL: image.flatMap(URL.init(string:)),
			price: currentPrice,
			change24h: priceChangePercentage24H ?? 0,
			marketCap: marketCap,
			high24h: high24H,
			low24h: low24H
		)
	}
}
