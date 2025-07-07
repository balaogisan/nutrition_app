# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.


## Project Overview

This is a SwiftUI-based iOS nutrition calculator app that allows users to:
- Track food intake with nutritional information (calories, protein, fat, carbs)
- Add food items manually or by analyzing photos with Google's Gemini AI
- Store food data locally using SQLite database

## App feature request
2025-7-5:
  -起始就可以輸入{營養目標值}：每日熱量預算，每日目標蛋白質，每日目標脂肪。
  -基本資料
  -增肌還是減脂週期
  -依據數據給出建議營養目標值
  -統計今日營養攝取，與目標值的差距。
  Design:
    提供一個設定icon在左上角。點進去即可設定目標值。
    訊息顯示：
      位置：在每日營養總計的BOX設計成可以左右滑動，看到下一組資訊{目標值差距}

## Architecture

### Design Patterns

**Architecture Style**: Simple MVC-like pattern with SwiftUI's reactive paradigm:
- **Model**: `Food` struct (pure data model)
- **View**: SwiftUI views with `@State` bindings
- **Controller/Service**: Singleton services for data and API operations

**Key Patterns**:
- **Singleton Pattern**: `DatabaseManager` and `GeminiAPI` for global access
- **Repository Pattern**: `DatabaseManager` abstracts data persistence
- **Reactive Programming**: SwiftUI's data binding for automatic UI updates

### Component Relationships

```
Nutrition_CalculatorApp (Entry Point)
├── ContentView (Main List View)
    ├── FoodAddView (Modal Sheet)
    │   ├── GeminiAPI (Image Analysis)
    │   └── DatabaseManager (Data Persistence)
    └── DatabaseManager (Data Retrieval)
```

**Core Components**:
- `FoodModel.swift` - `Food` struct conforming to `Identifiable`
- `DatabaseManager.swift` - Singleton with SQLite.swift ORM for type-safe operations
- `ContentView.swift` - Main list with swipe-to-delete functionality
- `FoodAddView.swift` - Complex form with photo analysis and JSON parsing
- `GeminiAPI.swift` - Google Gemini Vision API integration with comprehensive error handling

### Data Flow

**Creation**: User input → FoodAddView → DatabaseManager → SQLite
**Reading**: ContentView → DatabaseManager → SQLite → UI update
**AI Analysis**: Photo → GeminiAPI → JSON parsing → Form auto-fill

### Key Dependencies

- **SQLite.swift v0.15.4** - Database ORM for local storage
- **PhotosUI** - System photo picker integration
- **Google Gemini Vision API** - AI-powered food analysis

### Database Schema

Foods table structure:
- `id` (Int64, primary key, auto-increment)
- `name` (String)
- `calories` (Double)
- `protein` (Double)
- `fat` (Double)
- `carbs` (Double)
- `date` (Date)

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project "Nutrition Calculator.xcodeproj" -scheme "Nutrition Calculator" build

# Build for simulator (recommended for development)
xcodebuild -project "Nutrition Calculator.xcodeproj" -scheme "Nutrition Calculator" -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for device
xcodebuild -project "Nutrition Calculator.xcodeproj" -scheme "Nutrition Calculator" -destination 'platform=iOS,name=iPhone' build

# Clean build folder
xcodebuild -project "Nutrition Calculator.xcodeproj" -scheme "Nutrition Calculator" clean
```

### Testing
```bash
# Run all tests
xcodebuild -project "Nutrition Calculator.xcodeproj" -scheme "Nutrition Calculator" test

# Run unit tests only
xcodebuild -project "Nutrition Calculator.xcodeproj" -scheme "Nutrition Calculator" test -only-testing:"Nutrition CalculatorTests"

# Run UI tests only
xcodebuild -project "Nutrition Calculator.xcodeproj" -scheme "Nutrition Calculator" test -only-testing:"Nutrition CalculatorUITests"
```

**Note**: Test coverage is minimal - only placeholder tests exist currently.

## Important Implementation Details

### Localization
- App interface is in Chinese (Traditional)
- Chinese comments in code indicate localized development

### Data Persistence
- Database file: `nutrition.sqlite3` in app's documents directory
- Single table design with auto-incrementing primary key
- No data migration strategy implemented
- All nutritional values stored as Double for precision

### AI Integration
- Gemini Vision API with sophisticated JSON parsing
- Supports markdown-wrapped JSON responses
- Comprehensive error handling and logging
- **Security Issue**: API key hardcoded in `GeminiAPI.swift:12`

### API Response Format
```json
{"name":"...", "calories":..., "protein":..., "fat":..., "carbs":...}
```

### Platform Support
- iOS 18.5+ deployment target
- Multi-platform: iOS, macOS, visionOS
- Automatic code signing enabled
