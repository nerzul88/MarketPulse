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
}
