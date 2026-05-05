//
//  AssetsEndpoint.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 29.03.2026.
//

import Foundation

enum AssetsEndpoint {
	static func markets(page: Int, perPage: Int) -> Endpoint {
		Endpoint(
			path: "/coins/markets",
			method: .get,
			queryItems: [
				URLQueryItem(name: "vs_currency", value: "usd"),
				URLQueryItem(name: "order", value: "market_cap_desc"),
				URLQueryItem(name: "per_page", value: "\(perPage)"),
				URLQueryItem(name: "page", value: "\(page)"),
				URLQueryItem(name: "sparkline", value: "false")
			]
		)
	}

	static func detail(id: String) -> Endpoint {
		var allowedCharacters = CharacterSet.urlPathAllowed
		allowedCharacters.remove(charactersIn: "/")
		let encodedID = id.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? id

		return Endpoint(
			path: "/coins/\(encodedID)",
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
