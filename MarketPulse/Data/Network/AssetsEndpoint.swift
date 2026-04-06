//
//  AssetsEndpoint.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 29.03.2026.
//

import Foundation

enum AssetsEndpoint {
	static func markets() -> Endpoint {
		Endpoint(
			path: "/coins/markets",
			method: .get,
			queryItems: [
				URLQueryItem(name: "vs_currency", value: "usd"),
				URLQueryItem(name: "order", value: "market_cap_desc"),
				URLQueryItem(name: "per_page", value: "20"),
				URLQueryItem(name: "page", value: "1"),
				URLQueryItem(name: "sparkline", value: "false")
			]
		)
	}
}
