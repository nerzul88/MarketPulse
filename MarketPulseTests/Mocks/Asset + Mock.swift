//
//  Asset + Mock.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 12.04.2026.
//

@testable import MarketPulse

extension Asset {
	static func mock(
		id: String = "bitcoin",
		name: String = "Bitcoin",
		symbol: String = "BTC",
		price: Double = 100_000,
		change24h: Double = 2.5
	) -> Asset {
		Asset(
			id: id,
			name: name,
			symbol: symbol,
			price: price,
			change24h: change24h
		)
	}
}
