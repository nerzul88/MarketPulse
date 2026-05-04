//
//  FetchFavoritesUseCasesTests.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 12.04.2026.
//

import XCTest
@testable import MarketPulse

final class FetchFavoritesUseCaseTests: XCTestCase {

	func test_execute_returnsFavoritesFromRepository() throws {
		let repository = MockFavoritesRepository()
		let favorites = [
			FavoriteAsset.mock(id: "bitcoin", name: "Bitcoin", symbol: "BTC"),
			FavoriteAsset.mock(id: "ethereum", name: "Ethereum", symbol: "ETH")
		]

		repository.fetchFavoritesResult = .success(favorites)

		let useCase = FetchFavoritesUseCase(repository: repository)

		let result = try useCase.execute()

		XCTAssertEqual(result, favorites)
	}

	func test_execute_throwsWhenRepositoryThrows() {
		let repository = MockFavoritesRepository()
		repository.fetchFavoritesResult = .failure(TestError.somethingWentWrong)

		let useCase = FetchFavoritesUseCase(repository: repository)

		XCTAssertThrowsError(try useCase.execute()) { error in
			XCTAssertEqual(error as? TestError, .somethingWentWrong)
		}
	}
}
