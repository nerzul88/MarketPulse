//
//  AssetDetailDTO+Mapping.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

import Foundation

extension AssetDetailDTO {
	func toDomain() -> AssetDetail? {
		guard let price = marketData?.currentPrice?["usd"] else { return nil }

		let cleanedOverview = description?.en?
			.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
			.trimmingCharacters(in: .whitespacesAndNewlines)

		return AssetDetail(
			id: id,
			name: name,
			symbol: symbol.uppercased(),
			price: price,
			change24h: marketData?.priceChangePercentage24H ?? 0,
			marketCap: marketData?.marketCap?["usd"],
			high24h: marketData?.high24H?["usd"],
			low24h: marketData?.low24H?["usd"],
			overview: cleanedOverview?.isEmpty == true ? nil : cleanedOverview
		)
	}
}
