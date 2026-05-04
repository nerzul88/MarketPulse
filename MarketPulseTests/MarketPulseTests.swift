//
//  MarketPulseTests.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 22.03.2026.
//

import XCTest
@testable import MarketPulse

final class FetchAssetDetailUseCaseTests: XCTestCase {

	func test_execute_returnsDetailFromRepository() async throws {
		let repository = MockAssetRepository()
		let detail = AssetDetail.mock()
		repository.fetchAssetDetailResult = .success(detail)

		let useCase = await FetchAssetDetailUseCase(repository: repository)
		let result = try await useCase.execute(id: "bitcoin")

		XCTAssertEqual(result, detail)
		XCTAssertEqual(repository.lastFetchAssetDetailID, "bitcoin")
	}

	func test_execute_rethrowsRepositoryError() async {
		let repository = MockAssetRepository()
		repository.fetchAssetDetailResult = .failure(TestError.somethingWentWrong)

		let useCase = await FetchAssetDetailUseCase(repository: repository)

		do {
			_ = try await useCase.execute(id: "bitcoin")
			XCTFail("Expected execute to throw")
		} catch {
			XCTAssertEqual(error as? TestError, .somethingWentWrong)
		}
	}
}

@MainActor
final class FavoritesViewModelTests: XCTestCase {

	func test_loadFavorites_whenFavoritesExist_emitsLoaded() {
		let repository = MockFavoritesRepository()
		let favorites = [
			FavoriteAsset.mock(id: "bitcoin"),
			FavoriteAsset.mock(id: "ethereum", name: "Ethereum", symbol: "ETH")
		]
		repository.fetchFavoritesResult = .success(favorites)

		let viewModel = FavoritesViewModel(
			fetchFavoritesUseCase: FetchFavoritesUseCase(repository: repository)
		)

		var receivedState: FavoritesViewModel.State?
		viewModel.onStateChanged = { receivedState = $0 }

		viewModel.loadFavorites()

		guard case let .loaded(loadedFavorites)? = receivedState else {
			return XCTFail("Expected loaded state")
		}

		XCTAssertEqual(loadedFavorites, favorites)
	}

	func test_loadFavorites_whenFavoritesAreEmpty_emitsEmpty() {
		let repository = MockFavoritesRepository()
		repository.fetchFavoritesResult = .success([])

		let viewModel = FavoritesViewModel(
			fetchFavoritesUseCase: FetchFavoritesUseCase(repository: repository)
		)

		var receivedState: FavoritesViewModel.State?
		viewModel.onStateChanged = { receivedState = $0 }

		viewModel.loadFavorites()

		guard case .empty? = receivedState else {
			return XCTFail("Expected empty state")
		}
	}

	func test_loadFavorites_whenUseCaseFails_emitsError() {
		let repository = MockFavoritesRepository()
		repository.fetchFavoritesResult = .failure(TestError.somethingWentWrong)

		let viewModel = FavoritesViewModel(
			fetchFavoritesUseCase: FetchFavoritesUseCase(repository: repository)
		)

		var receivedState: FavoritesViewModel.State?
		viewModel.onStateChanged = { receivedState = $0 }

		viewModel.loadFavorites()

		guard case let .error(message)? = receivedState else {
			return XCTFail("Expected error state")
		}

		XCTAssertEqual(message, TestError.somethingWentWrong.localizedDescription)
	}
}

@MainActor
final class AssetDetailViewModelTests: XCTestCase {

	func test_load_emitsLoadingUpdatesFavoriteStatusAndThenLoaded() async {
		let asset = Asset.mock(id: "bitcoin")
		let repository = MockAssetRepository()
		let favoritesRepository = MockFavoritesRepository()
		let detail = AssetDetail.mock(id: "bitcoin")

		repository.fetchAssetDetailResult = .success(detail)
		favoritesRepository.isFavoriteResult = .success(true)

		let viewModel = AssetDetailViewModel(
			asset: asset,
			fetchAssetDetailUseCase: FetchAssetDetailUseCase(repository: repository),
			toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: favoritesRepository),
			isFavoriteUseCase: IsFavoriteUseCase(repository: favoritesRepository)
		)

		var receivedStates: [AssetDetailViewModel.State] = []
		var favoriteStatuses: [Bool] = []
		let loadedExpectation = expectation(description: "Detail loaded")

		viewModel.onStateChanged = { state in
			receivedStates.append(state)
			if case .loaded = state {
				loadedExpectation.fulfill()
			}
		}
		viewModel.onFavoriteStatusChanged = { favoriteStatuses.append($0) }

		viewModel.load()
		await fulfillment(of: [loadedExpectation], timeout: 1.0)

		XCTAssertEqual(favoriteStatuses, [true])
		XCTAssertEqual(favoritesRepository.lastIsFavoriteRequestedID, asset.id)
		XCTAssertEqual(repository.lastFetchAssetDetailID, asset.id)

		guard receivedStates.count == 2 else {
			return XCTFail("Expected two emitted states")
		}

		guard case .loading = receivedStates[0] else {
			return XCTFail("Expected loading state first")
		}

		guard case let .loaded(receivedDetail) = receivedStates[1] else {
			return XCTFail("Expected loaded state second")
		}

		XCTAssertEqual(receivedDetail, detail)
	}

	func test_load_whenDetailFetchFails_emitsError() async {
		let asset = Asset.mock(id: "bitcoin")
		let repository = MockAssetRepository()
		let favoritesRepository = MockFavoritesRepository()

		repository.fetchAssetDetailResult = .failure(TestError.somethingWentWrong)
		favoritesRepository.isFavoriteResult = .success(false)

		let viewModel = AssetDetailViewModel(
			asset: asset,
			fetchAssetDetailUseCase: FetchAssetDetailUseCase(repository: repository),
			toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: favoritesRepository),
			isFavoriteUseCase: IsFavoriteUseCase(repository: favoritesRepository)
		)

		var receivedStates: [AssetDetailViewModel.State] = []
		var favoriteStatuses: [Bool] = []
		let errorExpectation = expectation(description: "Detail error")

		viewModel.onStateChanged = { state in
			receivedStates.append(state)
			if case .error = state {
				errorExpectation.fulfill()
			}
		}
		viewModel.onFavoriteStatusChanged = { favoriteStatuses.append($0) }

		viewModel.load()
		await fulfillment(of: [errorExpectation], timeout: 1.0)

		XCTAssertEqual(favoriteStatuses, [false])

		guard receivedStates.count == 2 else {
			return XCTFail("Expected two emitted states")
		}

		guard case .loading = receivedStates[0] else {
			return XCTFail("Expected loading state first")
		}

		guard case let .error(message) = receivedStates[1] else {
			return XCTFail("Expected error state second")
		}

		XCTAssertEqual(message, TestError.somethingWentWrong.localizedDescription)
	}

	func test_updateFavoriteStatus_whenUseCaseFails_emitsFalse() {
		let favoritesRepository = MockFavoritesRepository()
		favoritesRepository.isFavoriteResult = .failure(TestError.somethingWentWrong)

		let viewModel = AssetDetailViewModel(
			asset: Asset.mock(id: "bitcoin"),
			fetchAssetDetailUseCase: FetchAssetDetailUseCase(repository: MockAssetRepository()),
			toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: favoritesRepository),
			isFavoriteUseCase: IsFavoriteUseCase(repository: favoritesRepository)
		)

		var receivedStatuses: [Bool] = []
		viewModel.onFavoriteStatusChanged = { receivedStatuses.append($0) }

		viewModel.updateFavoriteStatus()

		XCTAssertEqual(receivedStatuses, [false])
	}

	func test_toggleFavorite_whenAssetIsNotFavorite_addsAssetAndUpdatesStatus() {
		let asset = Asset.mock(id: "bitcoin")
		let favoritesRepository = MockFavoritesRepository()
		favoritesRepository.isFavoriteResult = .success(false)

		let viewModel = AssetDetailViewModel(
			asset: asset,
			fetchAssetDetailUseCase: FetchAssetDetailUseCase(repository: MockAssetRepository()),
			toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: favoritesRepository),
			isFavoriteUseCase: IsFavoriteUseCase(repository: favoritesRepository)
		)

		var receivedStatuses: [Bool] = []
		viewModel.onFavoriteStatusChanged = { receivedStatuses.append($0) }

		viewModel.toggleFavorite()

		XCTAssertEqual(favoritesRepository.addedAsset, asset)
		XCTAssertEqual(receivedStatuses, [true])
	}

	func test_toggleFavorite_whenUseCaseFails_emitsError() {
		let repository = FailingAssetDetailFavoritesRepository()
		let viewModel = AssetDetailViewModel(
			asset: Asset.mock(id: "bitcoin"),
			fetchAssetDetailUseCase: FetchAssetDetailUseCase(repository: MockAssetRepository()),
			toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: repository),
			isFavoriteUseCase: IsFavoriteUseCase(repository: repository)
		)

		var receivedMessage: String?
		viewModel.onStateChanged = { state in
			if case let .error(message) = state {
				receivedMessage = message
			}
		}

		viewModel.toggleFavorite()

		XCTAssertEqual(receivedMessage, TestError.somethingWentWrong.localizedDescription)
	}
}

private final class FailingAssetDetailFavoritesRepository: FavoritesRepositoryProtocol {
	func fetchFavorites() throws -> [FavoriteAsset] { [] }
	func addToFavorites(asset: Asset) throws { throw TestError.somethingWentWrong }
	func removeFromFavorites(id: String) throws {}
	func isFavorite(id: String) throws -> Bool { false }
}

private extension AssetDetail {
	static func mock(
		id: String = "bitcoin",
		name: String = "Bitcoin",
		symbol: String = "BTC",
		price: Double = 100_000,
		change24h: Double = 2.5,
		marketCap: Double? = 2_000_000_000,
		high24h: Double? = 101_000,
		low24h: Double? = 99_000,
		overview: String? = "Digital gold"
	) -> AssetDetail {
		AssetDetail(
			id: id,
			name: name,
			symbol: symbol,
			price: price,
			change24h: change24h,
			marketCap: marketCap,
			high24h: high24h,
			low24h: low24h,
			overview: overview
		)
	}
}
