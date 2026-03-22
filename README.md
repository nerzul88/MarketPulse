# MarketPulse

Track markets. Stay informed. Act faster.

Production-like iOS app for tracking financial assets with real-time data, offline mode, and price alerts.

![preview](screenshots/preview.png)

## 🚀 Features

- Real-time market data
- Debounced search with cancellation
- Favorites with local persistence
- Offline mode with cached data
- Pull-to-refresh
- Local price alerts
- Clean architecture (MVVM + DI)

## 🏗 Architecture

The project follows a modular and testable architecture:

- MVVM (Presentation layer)
- Domain layer with use cases
- Data layer with repository pattern
- Dependency Injection via protocols

Structure:

Presentation → View / ViewModel  
Domain → Models / UseCases  
Data → Repository / Network / Persistence

## ⚙️ Tech Stack

- Swift
- UIKit + SwiftUI
- Async/Await (Structured Concurrency)
- URLSession
- Core Data
- XCTest
- Swift Package Manager

## 🌐 Networking

- Generic network layer
- Decodable parsing
- Error handling & mapping
- Request cancellation (search)
- Retry logic for transient failures

## 💾 Persistence

- Core Data used for:
  - caching market data
  - storing favorites
- Offline-first approach
- Last update timestamp tracking

## 🧪 Testing

- ViewModel unit tests
- Repository tests with mocked network layer
- Mapping validation tests

## 📸 Screenshots

| Market | Details | Favorites |
|-------|--------|----------|
| img | img | img |

## ▶️ Getting Started

1. Clone the repo
2. Open `.xcodeproj`
3. Run on simulator

## 🔮 Future Improvements

- Background data refresh
- Widget support
- Advanced charting
- Push notifications via backend
- Snapshot testing

## 📄 License

This project is licensed under the MIT License.
