//
//  AssetDetail.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

struct AssetDetail: Equatable {
	let id: String
	let name: String
	let symbol: String
	let price: Double
	let change24h: Double
	let marketCap: Double?
	let high24h: Double?
	let low24h: Double?
	let overview: String?
}
