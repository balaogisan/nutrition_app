# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.


## Project Overview

This is a SwiftUI-based iOS nutrition calculator app that allows users to:
- Track food intake with nutritional information (calories, protein, fat, carbs)
- Add food items manually or by analyzing photos with Google's Gemini AI
- Store food data locally using SQLite database

## App feature request
2025-7-9
  -Add Icon
  $ swip to delet item not smoothly
  $ add process indicator as request gemini.
  

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

  2025-7-6:
  


  Checked-顯示最近七天的數據，向左滑可以看前一天
  
  Checked-因此在畫面設計變更：
    1.[今日]食物清單標題移到 今日營養統計之下。
    2.向左滑可以看前一日，再向左滑就可以看前天的資料。總共會有七日的資料，包含今日。
    3.標題要改成日期變數。除了今日。前一天的改成{日期}營養統計{日期}食物清單
    4. default 主頁顯示今日的數據頁

  Checked-新增食物頁：在食物名稱 輸入時每一字，都能去資料庫 模糊搜尋 顯示找到類似的 食物名稱 清單，可以快速選擇食物帶入營養數值。無需一個一個輸入已經存在資料庫的食物。類似在google box搜尋 幫忙顯示常用關鍵字。

-今日數據向右滑，顯示七天統計圖。再向右滑是30天統計圖。

成本優化：傳一張圖最小要多大。
  -那個模型最便宜
  -已經有的食物，就不要問AI。

  -食物快捷 (summary)
  -先問食物名，搜尋資料庫，找不到才用AI

  - 今日食物清單向右滑，增加一頁，{快速選取食物}將前20名食物建立標籤，每一標籤代表一個食物，標注文字食物前三個字。點一下標籤，將會將該標籤指到食物添加到今日食物。




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
