# 🏍️ Mileage Tracker - Flutter Android App

A smart fuel tracking app for your bike that uses **AI (Claude Vision API)** to automatically extract data from your speedometer and fuel machine photos.

---

## ✨ Features

- 📸 **Camera capture** of speedometer and petrol machine
- 🤖 **AI-powered extraction** — reads odometer and fuel data automatically
- 📊 **Dashboard** with average mileage, charts, and statistics
- 📋 **History** with all fill-ups and per-entry mileage
- 💾 **Local SQLite storage** — works offline, data never lost
- 📤 **CSV Export** — copy to clipboard and paste into Google Sheets
- 🌙 **Dark theme** with speedometer-inspired UI

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK 3.0+
- Android Studio / VS Code
- Android device or emulator (API 21+)

### Step 1: Clone & Install
```bash
cd fuel_tracker
flutter pub get
```

### Step 2: Get a Free Claude API Key
1. Visit **https://console.anthropic.com**
2. Sign up (free account)
3. Go to **API Keys** → **Create Key**
4. Copy your key (starts with `sk-ant-...`)

> 💡 Free tier gives **$5 credit** = hundreds of image extractions!

### Step 3: Run the App
```bash
flutter run
```

### Step 4: Configure API Key
1. Open the app → tap **Settings** tab
2. Paste your Claude API key
3. Tap **Save API Key**

---

## 📱 How to Use

### Adding a Fill-up Entry:
1. Go to **Add Entry** tab
2. Tap **Speedometer** card → take photo of odometer
3. Tap **Fuel Machine** card → take photo of machine display
4. AI extracts the numbers automatically
5. Review/edit the values if needed
6. Tap **Save Entry**

### Viewing Stats:
- **Dashboard** → average mileage, total spend, distance, charts
- **History** → all entries, swipe left to delete

### Export to Google Sheets:
1. Go to **Settings** → tap **Copy CSV to Clipboard**
2. Open Google Sheets → paste the data

---

## 🏗️ Project Structure

```
lib/
├── main.dart                    # Entry point
├── models/
│   └── fuel_entry.dart          # Data models
├── services/
│   ├── database_service.dart    # SQLite operations
│   └── ai_extraction_service.dart  # Claude API calls
├── screens/
│   ├── home_screen.dart         # Bottom nav container
│   ├── dashboard_screen.dart    # Stats & charts
│   ├── add_entry_screen.dart    # Add new fill-up
│   ├── history_screen.dart      # All entries
│   └── settings_screen.dart    # API key & export
├── widgets/
│   ├── image_capture_card.dart  # Photo capture UI
│   └── extracted_data_chip.dart # Extraction status chip
└── utils/
    └── app_theme.dart           # Colors & theme
```

---

## 🔧 Dependencies

| Package | Purpose |
|---------|---------|
| `sqflite` | Local SQLite database |
| `image_picker` | Camera & gallery access |
| `http` | Claude API calls |
| `fl_chart` | Mileage trend charts |
| `google_fonts` | Typography |
| `shared_preferences` | Store API key |
| `permission_handler` | Camera permissions |
| `uuid` | Unique entry IDs |
| `intl` | Date & currency formatting |

---

## 🧮 Mileage Calculation

Mileage is calculated between **consecutive fill-ups**:

```
Mileage (km/L) = (Current Odometer - Previous Odometer) / Liters Filled
Average Mileage = Sum of all individual mileages / Number of entries
```

---

## 📊 Data Storage

All data is stored **locally** on your phone using SQLite:
- No internet required to view history
- Data persists across app restarts
- Only Claude API calls need internet (for photo extraction)

---

## 🔒 Privacy

- Your photos are stored only on your device
- Only the image is sent to Anthropic's API for text extraction
- Your API key is stored locally in shared preferences
- No data is sent to any other server

---

## 🐛 Troubleshooting

**AI extraction not working?**
- Check your API key in Settings
- Ensure you have internet connection
- Make sure photos are clear and well-lit
- You can always type values manually

**Camera not working?**
- Grant camera permission when prompted
- Check app permissions in Android Settings

---

## 📄 License

MIT License - Free to use and modify
