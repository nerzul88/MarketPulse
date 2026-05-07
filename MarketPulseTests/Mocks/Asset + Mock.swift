//
//  Asset + Mock.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 12.04.2026.
//

@testable import MarketPulse
import Foundation

extension Asset {
	static func mock(
		id: String = "bitcoin",
		name: String = "Bitcoin",
		symbol: String = "BTC",
		imageURL: URL? = nil,
		price: Double = 100_000,
		change24h: Double = 2.5,
		marketCap: Double? = 2_000_000_000,
		high24h: Double? = 101_000,
		low24h: Double? = 99_000
	) -> Asset {
		Asset(
			id: id,
			name: name,
			symbol: symbol,
			imageURL: imageURL,
			price: price,
			change24h: change24h,
			marketCap: marketCap,
			high24h: high24h,
			low24h: low24h
		)
	}
}
