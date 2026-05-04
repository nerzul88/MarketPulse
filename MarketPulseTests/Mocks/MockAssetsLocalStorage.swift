//
//  MockAssetsLocalStorage.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 12.04.2026.
//

@testable import MarketPulse

final class MockAssetsLocalStorage: AssetsLocalStorageProtocol {

	var savedAssets: [Asset] = []
	var fetchResult: Result<CachedAssets, Error>?
	var saveResult: Result<Void, Error>?
	var saveWasCalled = false
	var fetchWasCalled = false

	func saveAssets(_ assets: [Asset]) throws {
		saveWasCalled = true
		savedAssets = assets

		try saveResult?.get()
	}

	func fetchAssets() throws -> CachedAssets {
		fetchWasCalled = true

		guard let fetchResult else {
			fatalError("fetchResult was not set")
		}

		return try fetchResult.get()
	}
}
