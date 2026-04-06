//
//  AssetTableViewCell.swift
//  MarketPulse
//
//  Created by Александр Касьянов on 06.04.2026.
//

import UIKit

final class AssetTableViewCell: UITableViewCell {

	static let reuseIdentifier = "AssetTableViewCell"

	private lazy var symbolLabel: UILabel = {
		let label = UILabel()
		label.font = .boldSystemFont(ofSize: 18)
		return label
	}()
	private lazy var nameLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 14)
		label.textColor = .secondaryLabel
		return label
	}()
	private lazy var priceLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 16, weight: .medium)
		label.textAlignment = .right
		return label
	}()
	private lazy var changeLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 14, weight: .medium)
		label.textAlignment = .right
		return label
	}()
	private lazy var leftStack: UIStackView = {
		let stackView = UIStackView(arrangedSubviews: [symbolLabel, nameLabel])
		stackView.axis = .vertical
		stackView.spacing = 4
		return stackView
	}()
	private lazy var rightStack: UIStackView = {
		let stackView = UIStackView(arrangedSubviews: [priceLabel, changeLabel])
		stackView.axis = .vertical
		stackView.spacing = 4
		stackView.alignment = .trailing
		return stackView
	}()
	private lazy var containerStack: UIStackView = {
		let stackView = UIStackView(arrangedSubviews: [leftStack, rightStack])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .horizontal
		stackView.alignment = .center
		stackView.distribution = .fill
		stackView.spacing = 12
		return stackView
	}()

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setupUI()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		symbolLabel.text = nil
		nameLabel.text = nil
		priceLabel.text = nil
		changeLabel.text = nil
	}

	func configure(with asset: Asset) {
		symbolLabel.text = asset.symbol
		nameLabel.text = asset.name
		priceLabel.text = Self.formatPrice(asset.price)
		changeLabel.text = Self.formatChange(asset.change24h)
		changeLabel.textColor = asset.change24h >= 0 ? .systemGreen : .systemRed
	}

	private func setupUI() {
		accessoryType = .disclosureIndicator

		contentView.addSubview(containerStack)

		NSLayoutConstraint.activate([
			containerStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
			containerStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
			containerStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
			containerStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
		])
	}

	private static func formatPrice(_ price: Double) -> String {
		if price >= 1 {
			return String(format: "$%.2f", price)
		} else {
			return String(format: "$%.4f", price)
		}
	}

	private static func formatChange(_ change: Double) -> String {
		let sign = change > 0 ? "+" : ""
		return "\(sign)\(String(format: "%.2f", change))%"
	}
}
