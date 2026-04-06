//
//  AssetDetailDTO.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

struct AssetDetailDTO: Decodable {
	let id: String
	let name: String
	let symbol: String
	let marketData: MarketDataDTO?
	let description: DescriptionDTO?
}

struct MarketDataDTO: Decodable {
	let currentPrice: [String: Double]?
	let priceChangePercentage24H: Double?
	let marketCap: [String: Double]?
	let high24H: [String: Double]?
	let low24H: [String: Double]?
}

struct DescriptionDTO: Decodable {
	let en: String?
}
