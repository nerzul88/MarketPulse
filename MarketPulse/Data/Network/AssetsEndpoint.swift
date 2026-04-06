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

	static func detail(id: String) -> Endpoint {
		Endpoint(
			path: "/coins/\(id)",
			method: .get,
			queryItems: [
				URLQueryItem(name: "localization", value: "false"),
				URLQueryItem(name: "tickers", value: "false"),
				URLQueryItem(name: "market_data", value: "true"),
				URLQueryItem(name: "community_data", value: "false"),
				URLQueryItem(name: "developer_data", value: "false"),
				URLQueryItem(name: "sparkline", value: "false")
			]
		)
	}
}
