//
//  AssetsListViewModelTests.swift
//  MarketPulseTests
//
//  Created by Александр Касьянов on 12.04.2026.
//

import XCTest
@testable import MarketPulse

@MainActor
final class AssetsListViewModelTests: XCTestCase {

	func test_loadAssets_emitsLoadingThenLoaded() async {
		let repository = MockAssetRepository()
		let assets = [
			Asset.mock(id: "bitcoin", name: "Bitcoin", symbol: "BTC"),
			Asset.mock(id: "ethereum", name: "Ethereum", symbol: "ETH")
		]

		repository.fetchAssetsResult = .success(.mock(assets: assets))

		let useCase = FetchAssetsUseCase(repository: repository)
		let viewModel = AssetsListViewModel(fetchAssetsUseCase: useCase)

		var receivedStates: [AssetsListViewModel.State] = []
		let expectation = expectation(description: "Receive loaded state")

		viewModel.onStateChanged = { state in
			receivedStates.append(state)

			if case .loaded = state {
				expectation.fulfill()
			}
		}

		viewModel.loadAssets()

		await fulfillment(of: [expectation], timeout: 1.0)

		XCTAssertEqual(repository.lastFetchAssetsPage, 1)
		XCTAssertEqual(repository.lastFetchAssetsLimit, 20)
		XCTAssertEqual(receivedStates.count, 2)

		if case .loading = receivedStates[0] {
		} else {
			XCTFail("Expected first state to be loading")
		}

		if case let .loaded(loadedAssets, _, isFromCache) = receivedStates[1] {
			XCTAssertEqual(loadedAssets, assets)
			XCTAssertFalse(isFromCache)
		} else {
			XCTFail("Expected second state to be loaded")
		}
	}

	func test_loadAssets_withEmptyAssets_emitsEmpty() async {
		let repository = MockAssetRepository()
		repository.fetchAssetsResult = .success(.mock(assets: []))

		let useCase = FetchAssetsUseCase(repository: repository)
		let viewModel = AssetsListViewModel(fetchAssetsUseCase: useCase)

		var receivedStates: [AssetsListViewModel.State] = []
		let expectation = expectation(description: "Receive empty state")

		viewModel.onStateChanged = { state in
			receivedStates.append(state)
			if case .empty = state {
				expectation.fulfill()
			}
		}

		viewModel.loadAssets()

		await fulfillment(of: [expectation], timeout: 1.0)

		XCTAssertEqual(receivedStates.count, 2)

		if case .loading = receivedStates[0] {
		} else {
			XCTFail("Expected first state to be loading")
		}

		if case .empty = receivedStates[1] {
		} else {
			XCTFail("Expected second state to be empty")
		}
	}

	func test_loadAssets_onFailure_emitsError() async {
		let repository = MockAssetRepository()
		repository.fetchAssetsResult = .failure(TestError.somethingWentWrong)

		let useCase = FetchAssetsUseCase(repository: repository)
		let viewModel = AssetsListViewModel(fetchAssetsUseCase: useCase)

		var receivedStates: [AssetsListViewModel.State] = []
		let expectation = expectation(description: "Receive error state")

		viewModel.onStateChanged = { state in
			receivedStates.append(state)
			if case .error = state {
				expectation.fulfill()
			}
		}

		viewModel.loadAssets()

		await fulfillment(of: [expectation], timeout: 1.0)

		XCTAssertEqual(receivedStates.count, 2)

		if case .loading = receivedStates[0] {
		} else {
			XCTFail("Expected first state to be loading")
		}

		if case let .error(message) = receivedStates[1] {
			XCTAssertEqual(message, TestError.somethingWentWrong.localizedDescription)
		} else {
			XCTFail("Expected second state to be error")
		}
	}

	func test_search_byName_filtersAssets() async {
		let repository = MockAssetRepository()
		let assets = [
			Asset.mock(id: "bitcoin", name: "Bitcoin", symbol: "BTC"),
			Asset.mock(id: "ethereum", name: "Ethereum", symbol: "ETH")
		]

		repository.fetchAssetsResult = .success(.mock(assets: assets))

		let useCase = FetchAssetsUseCase(repository: repository)
		let viewModel = AssetsListViewModel(fetchAssetsUseCase: useCase)

		let loadExpectation = expectation(description: "Assets loaded")
		let searchExpectation = expectation(description: "Search applied")

		var receivedStates: [AssetsListViewModel.State] = []

		viewModel.onStateChanged = { state in
			receivedStates.append(state)

			if case .loaded(let assets, _, _) = state, assets.count == 2 {
				loadExpectation.fulfill()
			}

			if case .loaded(let assets, _, _) = state, assets.count == 1, assets.first?.name == "Bitcoin" {
				searchExpectation.fulfill()
			}
		}

		viewModel.loadAssets()
		await fulfillment(of: [loadExpectation], timeout: 1.0)

		viewModel.search(query: "bit")
		await fulfillment(of: [searchExpectation], timeout: 1.0)
	}

	func test_search_trimsWhitespaceAndMatchesSymbolCaseInsensitively() async {
		let repository = MockAssetRepository()
		let assets = [
			Asset.mock(id: "bitcoin", name: "Bitcoin", symbol: "BTC"),
			Asset.mock(id: "ethereum", name: "Ethereum", symbol: "ETH")
		]
		let lastUpdated = Date()

		repository.fetchAssetsResult = .success(
			.mock(assets: assets, lastUpdated: lastUpdated, isFromCache: true)
		)

		let useCase = FetchAssetsUseCase(repository: repository)
		let viewModel = AssetsListViewModel(fetchAssetsUseCase: useCase)

		let loadExpectation = expectation(description: "Assets loaded")
		let filteredExpectation = expectation(description: "Assets filtered by symbol")

		viewModel.onStateChanged = { state in
			switch state {
			case .loaded(let loadedAssets, let emittedDate, let isFromCache)
				where loadedAssets.count == 2 && emittedDate == lastUpdated && isFromCache:
				loadExpectation.fulfill()
			case .loaded(let loadedAssets, let emittedDate, let isFromCache)
				where loadedAssets == [assets[1]] && emittedDate == lastUpdated && isFromCache:
				filteredExpectation.fulfill()
			default:
				break
			}
		}

		viewModel.loadAssets()
		await fulfillment(of: [loadExpectation], timeout: 1.0)

		viewModel.search(query: "  eth  ")
		await fulfillment(of: [filteredExpectation], timeout: 1.0)
	}

	func test_search_whenNothingMatches_emitsEmpty() async {
		let repository = MockAssetRepository()
		repository.fetchAssetsResult = .success(.mock(assets: [Asset.mock()]))

		let useCase = FetchAssetsUseCase(repository: repository)
		let viewModel = AssetsListViewModel(fetchAssetsUseCase: useCase)

		let loadExpectation = expectation(description: "Assets loaded")
		let emptyExpectation = expectation(description: "Empty state after search")

		viewModel.onStateChanged = { state in
			switch state {
			case .loaded(let assets, _, _) where assets.count == 1:
				loadExpectation.fulfill()
			case .empty:
				emptyExpectation.fulfill()
			default:
				break
			}
		}

		viewModel.loadAssets()
		await fulfillment(of: [loadExpectation], timeout: 1.0)

		viewModel.search(query: "solana")
		await fulfillment(of: [emptyExpectation], timeout: 1.0)
	}

	func test_loadNextPageIfNeeded_whenThresholdReached_loadsNextPageAndAppendsAssets() async {
		let repository = MockAssetRepository()
		let firstPageAssets = (1...20).map { index in
			Asset.mock(id: "asset-\(index)", name: "Asset \(index)", symbol: "A\(index)")
		}
		let secondPageAssets = [
			Asset.mock(id: "asset-21", name: "Asset 21", symbol: "A21"),
			Asset.mock(id: "asset-22", name: "Asset 22", symbol: "A22")
		]

		repository.fetchAssetsResultsByPage = [
			1: .success(.mock(assets: firstPageAssets, page: 1, canLoadMore: true)),
			2: .success(.mock(assets: secondPageAssets, page: 2, canLoadMore: false))
		]

		let viewModel = AssetsListViewModel(fetchAssetsUseCase: FetchAssetsUseCase(repository: repository))
		let initialExpectation = expectation(description: "Initial page loaded")
		let nextPageExpectation = expectation(description: "Next page loaded")
		var loadedCounts: [Int] = []

		viewModel.onStateChanged = { state in
			if case let .loaded(assets, _, _) = state {
				loadedCounts.append(assets.count)

				if assets.count == 20 {
					initialExpectation.fulfill()
				}

				if assets.count == 22 {
					nextPageExpectation.fulfill()
				}
			}
		}

		viewModel.loadInitialAssets()
		await fulfillment(of: [initialExpectation], timeout: 1.0)

		viewModel.loadNextPageIfNeeded(currentAsset: firstPageAssets[19])
		await fulfillment(of: [nextPageExpectation], timeout: 1.0)

		XCTAssertEqual(repository.fetchAssetsCallCount, 2)
		XCTAssertEqual(repository.lastFetchAssetsPage, 2)
		XCTAssertEqual(Array(loadedCounts.suffix(2)), [20, 22])
	}

	func test_loadNextPageIfNeeded_whenNotNearEnd_doesNotLoadNextPage() async {
		let repository = MockAssetRepository()
		let firstPageAssets = (1...20).map { index in
			Asset.mock(id: "asset-\(index)", name: "Asset \(index)", symbol: "A\(index)")
		}

		repository.fetchAssetsResult = .success(.mock(assets: firstPageAssets, page: 1, canLoadMore: true))

		let viewModel = AssetsListViewModel(fetchAssetsUseCase: FetchAssetsUseCase(repository: repository))
		let expectation = expectation(description: "Initial page loaded")

		viewModel.onStateChanged = { state in
			if case .loaded = state {
				expectation.fulfill()
			}
		}

		viewModel.loadInitialAssets()
		await fulfillment(of: [expectation], timeout: 1.0)

		viewModel.loadNextPageIfNeeded(currentAsset: firstPageAssets[5])

		XCTAssertEqual(repository.fetchAssetsCallCount, 1)
	}

	func test_loadNextPageIfNeeded_whenSearchIsActive_doesNotLoadNextPage() async {
		let repository = MockAssetRepository()
		let firstPageAssets = (1...20).map { index in
			Asset.mock(id: "asset-\(index)", name: "Asset \(index)", symbol: "A\(index)")
		}

		repository.fetchAssetsResult = .success(.mock(assets: firstPageAssets, page: 1, canLoadMore: true))

		let viewModel = AssetsListViewModel(fetchAssetsUseCase: FetchAssetsUseCase(repository: repository))
		let loadExpectation = expectation(description: "Initial page loaded")

		viewModel.onStateChanged = { state in
			if case .loaded(let assets, _, _) = state, assets.count == 20 {
				loadExpectation.fulfill()
			}
		}

		viewModel.loadInitialAssets()
		await fulfillment(of: [loadExpectation], timeout: 1.0)

		viewModel.search(query: "asset 1")
		try? await Task.sleep(nanoseconds: 500_000_000)
		viewModel.loadNextPageIfNeeded(currentAsset: firstPageAssets[19])

		XCTAssertEqual(repository.fetchAssetsCallCount, 1)
	}

	func test_loadNextPageIfNeeded_togglesPaginationLoadingCallback() async {
		let repository = MockAssetRepository()
		let firstPageAssets = (1...20).map { index in
			Asset.mock(id: "asset-\(index)", name: "Asset \(index)", symbol: "A\(index)")
		}
		let secondPageAssets = [Asset.mock(id: "asset-21", name: "Asset 21", symbol: "A21")]

		repository.fetchAssetsResultsByPage = [
			1: .success(.mock(assets: firstPageAssets, page: 1, canLoadMore: true)),
			2: .success(.mock(assets: secondPageAssets, page: 2, canLoadMore: false))
		]

		let viewModel = AssetsListViewModel(fetchAssetsUseCase: FetchAssetsUseCase(repository: repository))
		let initialExpectation = expectation(description: "Initial page loaded")
		let nextPageExpectation = expectation(description: "Next page finished")
		var paginationStates: [Bool] = []

		viewModel.onStateChanged = { state in
			if case .loaded(let assets, _, _) = state, assets.count == 20 {
				initialExpectation.fulfill()
			}
			if case .loaded(let assets, _, _) = state, assets.count == 21 {
				nextPageExpectation.fulfill()
			}
		}
		viewModel.onPaginationStateChanged = { paginationStates.append($0) }

		viewModel.loadInitialAssets()
		await fulfillment(of: [initialExpectation], timeout: 1.0)

		viewModel.loadNextPageIfNeeded(currentAsset: firstPageAssets[19])
		await fulfillment(of: [nextPageExpectation], timeout: 1.0)

		XCTAssertEqual(paginationStates, [true, false])
	}

	func test_loadNextPageIfNeeded_onFailure_emitsPaginationErrorWithoutMainErrorState() async {
		let repository = MockAssetRepository()
		let firstPageAssets = (1...20).map { index in
			Asset.mock(id: "asset-\(index)", name: "Asset \(index)", symbol: "A\(index)")
		}

		repository.fetchAssetsResultsByPage = [
			1: .success(.mock(assets: firstPageAssets, page: 1, canLoadMore: true)),
			2: .failure(TestError.somethingWentWrong)
		]

		let viewModel = AssetsListViewModel(fetchAssetsUseCase: FetchAssetsUseCase(repository: repository))
		let initialExpectation = expectation(description: "Initial page loaded")
		let paginationErrorExpectation = expectation(description: "Pagination error emitted")
		var receivedErrorState = false
		var receivedPaginationMessages: [String?] = []

		viewModel.onStateChanged = { state in
			switch state {
			case .loaded(let assets, _, _) where assets.count == 20:
				initialExpectation.fulfill()
			case .error:
				receivedErrorState = true
			default:
				break
			}
		}
		viewModel.onPaginationErrorChanged = { message in
			receivedPaginationMessages.append(message)

			if message == TestError.somethingWentWrong.localizedDescription {
				paginationErrorExpectation.fulfill()
			}
		}

		viewModel.loadInitialAssets()
		await fulfillment(of: [initialExpectation], timeout: 1.0)

		viewModel.loadNextPageIfNeeded(currentAsset: firstPageAssets[19])
		await fulfillment(of: [paginationErrorExpectation], timeout: 1.0)

		XCTAssertFalse(receivedErrorState)
		XCTAssertEqual(receivedPaginationMessages, [TestError.somethingWentWrong.localizedDescription])
	}

	func test_retryNextPageLoad_afterPaginationError_retriesAndAppendsAssets() async {
		let repository = MockAssetRepository()
		let firstPageAssets = (1...20).map { index in
			Asset.mock(id: "asset-\(index)", name: "Asset \(index)", symbol: "A\(index)")
		}
		let secondPageAssets = [
			Asset.mock(id: "asset-21", name: "Asset 21", symbol: "A21")
		]

		var secondPageAttemptCount = 0
		repository.fetchAssetsHandler = { page, _ in
			switch page {
			case 1:
				return .mock(assets: firstPageAssets, page: 1, canLoadMore: true)
			case 2:
				secondPageAttemptCount += 1
				if secondPageAttemptCount == 1 {
					throw TestError.somethingWentWrong
				}
				return .mock(assets: secondPageAssets, page: 2, canLoadMore: false)
			default:
				return .mock(assets: [])
			}
		}

		let viewModel = AssetsListViewModel(fetchAssetsUseCase: FetchAssetsUseCase(repository: repository))
		let initialExpectation = expectation(description: "Initial page loaded")
		let paginationErrorExpectation = expectation(description: "Pagination error emitted")
		let retriedPageExpectation = expectation(description: "Retried page loaded")
		var receivedPaginationMessages: [String?] = []

		viewModel.onStateChanged = { state in
			if case let .loaded(assets, _, _) = state {
				if assets.count == 20 {
					initialExpectation.fulfill()
				}

				if assets.count == 21 {
					retriedPageExpectation.fulfill()
				}
			}
		}
		viewModel.onPaginationErrorChanged = { message in
			receivedPaginationMessages.append(message)

			if message == TestError.somethingWentWrong.localizedDescription {
				paginationErrorExpectation.fulfill()
			}
		}

		viewModel.loadInitialAssets()
		await fulfillment(of: [initialExpectation], timeout: 1.0)

		viewModel.loadNextPageIfNeeded(currentAsset: firstPageAssets[19])
		await fulfillment(of: [paginationErrorExpectation], timeout: 1.0)

		viewModel.retryNextPageLoad()
		await fulfillment(of: [retriedPageExpectation], timeout: 1.0)

		XCTAssertEqual(secondPageAttemptCount, 2)
		XCTAssertEqual(receivedPaginationMessages, [TestError.somethingWentWrong.localizedDescription, nil])
	}

	func test_loadInitialAssets_cancelsStalePaginationResponse() async {
		let repository = MockAssetRepository()
		let firstPageAssets = (1...20).map { index in
			Asset.mock(id: "asset-\(index)", name: "Asset \(index)", symbol: "A\(index)")
		}
		let refreshedAssets = (1...20).map { index in
			Asset.mock(id: "refresh-\(index)", name: "Refresh \(index)", symbol: "R\(index)")
		}
		let staleSecondPageAssets = [
			Asset.mock(id: "stale-21", name: "Stale 21", symbol: "S21"),
			Asset.mock(id: "stale-22", name: "Stale 22", symbol: "S22")
		]

		repository.fetchAssetsResultsByPage = [
			1: .success(.mock(assets: firstPageAssets, page: 1, canLoadMore: true)),
			2: .success(.mock(assets: staleSecondPageAssets, page: 2, canLoadMore: false))
		]

		let viewModel = AssetsListViewModel(fetchAssetsUseCase: FetchAssetsUseCase(repository: repository))
		let initialExpectation = expectation(description: "Initial page loaded")
		let refreshedExpectation = expectation(description: "Refreshed first page loaded")
		var loadedSnapshots: [[Asset]] = []
		var hasTriggeredRefresh = false

		viewModel.onStateChanged = { state in
			guard case let .loaded(assets, _, _) = state else { return }
			loadedSnapshots.append(assets)

			if assets == firstPageAssets {
				initialExpectation.fulfill()
				return
			}

			if hasTriggeredRefresh, assets == refreshedAssets {
				refreshedExpectation.fulfill()
			}
		}

		viewModel.loadInitialAssets()
		await fulfillment(of: [initialExpectation], timeout: 1.0)

		repository.fetchAssetsDelayByPage[2] = 300_000_000
		repository.fetchAssetsResultsByPage[1] = .success(.mock(assets: refreshedAssets, page: 1, canLoadMore: true))

		viewModel.loadNextPageIfNeeded(currentAsset: firstPageAssets[19])
		hasTriggeredRefresh = true
		viewModel.loadInitialAssets()

		await fulfillment(of: [refreshedExpectation], timeout: 1.0)
		try? await Task.sleep(nanoseconds: 400_000_000)

		guard let finalAssets = loadedSnapshots.last else {
			return XCTFail("Expected final assets snapshot")
		}
		XCTAssertEqual(finalAssets, refreshedAssets)
		XCTAssertFalse(finalAssets.contains(where: { $0.id == "stale-21" }))
	}

	func test_loadInitialAssets_cancelsPreviousInitialLoadResponse() async {
		let repository = MockAssetRepository()
		let staleAssets = (1...20).map { index in
			Asset.mock(id: "stale-\(index)", name: "Stale \(index)", symbol: "S\(index)")
		}
		let refreshedAssets = (1...20).map { index in
			Asset.mock(id: "fresh-\(index)", name: "Fresh \(index)", symbol: "F\(index)")
		}

		var pageOneRequestCount = 0
		repository.fetchAssetsHandler = { page, _ in
			guard page == 1 else {
				return .mock(assets: [])
			}

			pageOneRequestCount += 1

			if pageOneRequestCount == 1 {
				try? await Task.sleep(nanoseconds: 300_000_000)
				return .mock(assets: staleAssets, page: 1, canLoadMore: true)
			}

			return .mock(assets: refreshedAssets, page: 1, canLoadMore: true)
		}

		let viewModel = AssetsListViewModel(fetchAssetsUseCase: FetchAssetsUseCase(repository: repository))
		let refreshedExpectation = expectation(description: "Latest refresh wins")
		var loadedSnapshots: [[Asset]] = []

		viewModel.onStateChanged = { state in
			guard case let .loaded(assets, _, _) = state else { return }
			loadedSnapshots.append(assets)

			if assets == refreshedAssets {
				refreshedExpectation.fulfill()
			}
		}

		viewModel.loadInitialAssets()
		viewModel.loadInitialAssets()

		await fulfillment(of: [refreshedExpectation], timeout: 1.0)
		try? await Task.sleep(nanoseconds: 400_000_000)

		guard let finalAssets = loadedSnapshots.last else {
			return XCTFail("Expected final assets snapshot")
		}

		XCTAssertEqual(repository.fetchAssetsCallCount, 2)
		XCTAssertEqual(finalAssets, refreshedAssets)
		XCTAssertFalse(finalAssets.contains(where: { $0.id == "stale-1" }))
	}
}
