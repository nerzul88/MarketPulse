//
//  AssetDetailViewController.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

import UIKit

final class AssetDetailViewController: UIViewController {

	private let viewModel: AssetDetailViewModel

	private let scrollView: UIScrollView = {
		let scrollView = UIScrollView()
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		return scrollView
	}()
	private let contentView: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()
	private let stackView: UIStackView = {
		let stackView = UIStackView()
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .vertical
		stackView.spacing = 12
		return stackView
	}()
	private let activityIndicator: UIActivityIndicatorView = {
		let indicator = UIActivityIndicatorView(style: .large)
		indicator.translatesAutoresizingMaskIntoConstraints = false
		return indicator
	}()
	private let nameLabel: UILabel = {
		let label = UILabel()
		label.font = .boldSystemFont(ofSize: 24)
		return label
	}()
	private let symbolLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 18)
		label.textColor = .secondaryLabel
		return label
	}()
	private let priceLabel = UILabel()
	private let changeLabel = UILabel()
	private let marketCapLabel = UILabel()
	private let highLowLabel = UILabel()
	private let overviewLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 15)
		label.textColor = .label
		label.lineBreakMode = .byWordWrapping
		return label
	}()

	init(viewModel: AssetDetailViewModel) {
		self.viewModel = viewModel
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		scrollView.isHidden = true
		setupUI()
		bindViewModel()
		viewModel.load()
	}

	private func setupUI() {
		view.backgroundColor = .systemBackground

		[nameLabel, symbolLabel, priceLabel, changeLabel, marketCapLabel, highLowLabel, overviewLabel].forEach {
			$0.numberOfLines = 0
			stackView.addArrangedSubview($0)
		}

		view.addSubview(scrollView)
		view.addSubview(activityIndicator)
		scrollView.addSubview(contentView)
		contentView.addSubview(stackView)

		NSLayoutConstraint.activate([
			scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

			contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
			contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
			contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
			contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

			contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

			stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
			stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
			stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
			stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

			activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
	}

	private func bindViewModel() {
		viewModel.onStateChanged = { [weak self] state in
			self?.handle(state: state)
		}
	}

	private func handle(state: AssetDetailViewModel.State) {
		switch state {
		case .loading:
			scrollView.isHidden = true
			activityIndicator.startAnimating()

		case .loaded(let detail):
			activityIndicator.stopAnimating()
			scrollView.isHidden = false
			configure(with: detail)

		case .error(let message):
			activityIndicator.stopAnimating()
			scrollView.isHidden = false
			showErrorAlert(message: message)
		}
	}

	private func configure(with detail: AssetDetail) {
		title = detail.symbol
		nameLabel.text = detail.name
		symbolLabel.text = detail.symbol
		priceLabel.text = "Price: \(String(format: "$%.2f", detail.price))"
		changeLabel.text = "24h: \(String(format: "%.2f", detail.change24h))%"
		marketCapLabel.text = "Market Cap: \(formatOptionalCurrency(detail.marketCap))"
		highLowLabel.text = "24h High / Low: \(formatOptionalCurrency(detail.high24h)) / \(formatOptionalCurrency(detail.low24h))"
		overviewLabel.text = detail.overview?.isEmpty == false ? detail.overview : "No description available"
	}

	private func formatOptionalCurrency(_ value: Double?) -> String {
		guard let value else { return "N/A" }
		return String(format: "$%.2f", value)
	}

	private func showErrorAlert(message: String) {
		guard presentedViewController == nil else { return }

		let alert = UIAlertController(
			title: "Something went wrong",
			message: message,
			preferredStyle: .alert
		)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		present(alert, animated: true)
	}
}
