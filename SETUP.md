# KrakenWatch Setup Instructions

## Getting Your Kraken API Keys

1. **Log into your Kraken account** at [kraken.com](https://kraken.com)

2. **Navigate to API Settings**:
   - Go to Settings → API
   - Or directly visit: https://kraken.com/u/security/api

3. **Generate a new API Key**:
   - Click "Generate New Key"
   - Give it a description like "KrakenWatch Portfolio Tracker"
   - **Required Permissions**: Select "Query Funds" (this gives access to account balance)
   - Leave all other permissions unchecked for security
   - Click "Generate Key"

4. **Save Your Credentials**:
   - Copy the **API Key** (public key)
   - Copy the **Private Key** (secret key)
   - **Important**: The private key is only shown once!

## Setting Up the App

1. **Update API Configuration**:
   - Open `lib/config/api_config.dart`
   - Replace `YOUR_KRAKEN_API_KEY_HERE` with your actual API key
   - Replace `YOUR_KRAKEN_API_SECRET_HERE` with your actual API secret

2. **Run the App**:
   ```bash
   fvm flutter run --device-id=macos
   ```

3. **Test the Connection**:
   - Click "Refresh Balances" in the app
   - You should see your actual USDT and BTC balances

## Security Notes

- **Never commit your API keys to version control**
- The `api_config.dart` file should be added to `.gitignore`
- Only grant "Query Funds" permission - this is read-only access
- You can revoke the API key at any time from your Kraken account

## Troubleshooting

- **"Invalid API key"**: Double-check your API key and secret
- **"Permission denied"**: Ensure "Query Funds" permission is enabled
- **"Invalid signature"**: Check that your API secret is correct and complete
- **Network errors**: Check your internet connection

## Supported Balance Types

The app currently displays:
- **USDT Balance**: Tether (USDT) holdings
- **BTC Balance**: Bitcoin (BTC) holdings

Other currencies in your Kraken account won't be displayed in this basic version.