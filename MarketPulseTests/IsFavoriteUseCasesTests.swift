//
//  IsFavoriteUseCasesTests.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 12.04.2026.
//

import XCTest
@testable import MarketPulse

final class IsFavoriteUseCaseTests: XCTestCase {

	func test_execute_returnsTrueWhenRepositoryReturnsTrue() throws {
		let repository = MockFavoritesRepository()
		repository.isFavoriteResult = .success(true)

		let useCase = IsFavoriteUseCase(repository: repository)

		let result = try useCase.execute(id: "bitcoin")

		XCTAssertTrue(result)
	}

	func test_execute_returnsFalseWhenRepositoryReturnsFalse() throws {
		let repository = MockFavoritesRepository()
		repository.isFavoriteResult = .success(false)

		let useCase = IsFavoriteUseCase(repository: repository)

		let result = try useCase.execute(id: "bitcoin")

		XCTAssertFalse(result)
	}

	func test_execute_throwsWhenRepositoryThrows() {
		let repository = MockFavoritesRepository()
		repository.isFavoriteResult = .failure(TestError.somethingWentWrong)

		let useCase = IsFavoriteUseCase(repository: repository)

		XCTAssertThrowsError(try useCase.execute(id: "bitcoin")) { error in
			XCTAssertEqual(error as? TestError, .somethingWentWrong)
		}
	}
}
