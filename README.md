# KrakenWatch 🦑

A personal portfolio tracker for Kraken cryptocurrency exchange that displays your account balance in multiple currencies simultaneously.

## Features

- **Multi-Currency View**: See your total balance in both USDT and BTC at the same time
- **Real-Time Updates**: Refresh your balances directly from Kraken's API
- **Secure Integration**: Uses official Kraken API with read-only permissions
- **Clean UI**: Simple, Material Design interface optimized for quick balance checks

## Why KrakenWatch?

The official Kraken mobile app only allows you to view your portfolio in one currency at a time. KrakenWatch solves this by showing your balances in multiple currencies simultaneously, giving you a better overview of your holdings.

## Getting Started

### Prerequisites

- Flutter SDK (managed via FVM)
- Kraken account with API access
- macOS (currently configured for macOS desktop)

### Setup

1. **Clone and install dependencies:**
   ```bash
   fvm flutter pub get
   ```

2. **Configure your Kraken API credentials:**
   - Follow instructions in [SETUP.md](SETUP.md) to get your API keys
   - Update `lib/config/api_config.dart` with your credentials

3. **Run the app:**
   ```bash
   fvm flutter run --device-id=macos
   ```

### API Permissions

This app requires **read-only** access to your Kraken account with the "Query Funds" permission enabled. It cannot make trades or withdrawals.

## Project Structure

```
lib/
├── config/
│   └── api_config.dart     # API credentials configuration
├── models/
│   └── balance.dart        # Data models for API responses
├── services/
│   └── kraken_api.dart     # Kraken API integration
└── main.dart               # Main app UI
```

## Security

- API credentials are kept in a separate config file
- The config file is excluded from version control
- Only read-only API permissions are required
- All API calls use proper HMAC-SHA512 authentication

## Contributing

This is a personal project, but feel free to fork and modify for your own use.
