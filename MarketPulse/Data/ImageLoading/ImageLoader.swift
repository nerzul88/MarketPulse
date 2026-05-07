//
//  ImageLoader.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 07.05.2026.
//

import UIKit

protocol ImageLoaderProtocol {
	func loadImage(from url: URL) async throws -> UIImage
}

final class ImageLoader: ImageLoaderProtocol {

	private let cache = NSCache<NSURL, UIImage>()
	private let session: URLSession

	init(session: URLSession = .shared) {
		self.session = session
		cache.countLimit = 300
	}

	func loadImage(from url: URL) async throws -> UIImage {
		let key = url as NSURL

		if let cachedImage = cache.object(forKey: key) {
			return cachedImage
		}

		let (data, response) = try await session.data(from: url)

		guard !Task.isCancelled else {
			throw CancellationError()
		}

		guard
			let httpResponse = response as? HTTPURLResponse,
			(200...299).contains(httpResponse.statusCode),
			let image = UIImage(data: data)
		else {
			throw ImageLoaderError.invalidData
		}

		cache.setObject(image, forKey: key)
		return image
	}
}

enum ImageLoaderError: Error {
	case invalidData
}
