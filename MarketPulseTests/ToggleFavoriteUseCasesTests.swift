//
//  ToggleFavoriteUseCasesTests.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 12.04.2026.
//

import XCTest
@testable import MarketPulse

final class ToggleFavoriteUseCaseTests: XCTestCase {

	func test_execute_whenAssetIsNotFavorite_addsToFavorites() throws {
		let repository = MockFavoritesRepository()
		let useCase = ToggleFavoriteUseCase(repository: repository)

		let asset = Asset.mock(
			id: "bitcoin",
			name: "Bitcoin",
			symbol: "BTC"
		)

		try useCase.execute(asset: asset, isFavorite: false)

		XCTAssertEqual(repository.addedAsset, asset)
		XCTAssertNil(repository.removedFavoriteID)
	}

	func test_execute_whenAssetIsFavorite_removesFromFavorites() throws {
		let repository = MockFavoritesRepository()
		let useCase = ToggleFavoriteUseCase(repository: repository)

		let asset = Asset.mock(
			id: "bitcoin",
			name: "Bitcoin",
			symbol: "BTC"
		)

		try useCase.execute(asset: asset, isFavorite: true)

		XCTAssertEqual(repository.removedFavoriteID, asset.id)
		XCTAssertNil(repository.addedAsset)
	}

	func test_execute_whenAddingFails_rethrowsError() {
		let repository = FailingAddFavoritesRepository()
		let useCase = ToggleFavoriteUseCase(repository: repository)
		let asset = Asset.mock()

		XCTAssertThrowsError(try useCase.execute(asset: asset, isFavorite: false)) { error in
			XCTAssertEqual(error as? TestError, .somethingWentWrong)
		}
	}

	func test_execute_whenRemovingFails_rethrowsError() {
		let repository = FailingRemoveFavoritesRepository()
		let useCase = ToggleFavoriteUseCase(repository: repository)
		let asset = Asset.mock()

		XCTAssertThrowsError(try useCase.execute(asset: asset, isFavorite: true)) { error in
			XCTAssertEqual(error as? TestError, .somethingWentWrong)
		}
	}
}

private final class FailingAddFavoritesRepository: FavoritesRepositoryProtocol {
	func fetchFavorites() throws -> [FavoriteAsset] { [] }
	func addToFavorites(asset: Asset) throws { throw TestError.somethingWentWrong }
	func removeFromFavorites(id: String) throws {}
	func isFavorite(id: String) throws -> Bool { false }
}

private final class FailingRemoveFavoritesRepository: FavoritesRepositoryProtocol {
	func fetchFavorites() throws -> [FavoriteAsset] { [] }
	func addToFavorites(asset: Asset) throws {}
	func removeFromFavorites(id: String) throws { throw TestError.somethingWentWrong }
	func isFavorite(id: String) throws -> Bool { false }
}
