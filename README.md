# 營養計算機 (Nutrition Calculator)

這是一款基於 SwiftUI 開發的 iOS 營養計算機應用程式。它能幫助使用者追蹤每日的飲食攝取，並透過 AI 分析食物照片，自動計算營養成分。使用者可以設定個人化的營養目標，並追蹤達成進度。

## ✨ 主要功能

- **手動記錄**：使用者可以手動輸入食物的名稱與營養成分（熱量、蛋白質、脂肪、碳水化合物）。
- **AI 照片分析**：使用 Google Gemini Vision API，透過上傳食物照片，自動辨識並填入營養資訊。
- **每日營養總結**：在主畫面上方顯示當日攝取的總熱量、蛋白質、脂肪和碳水化合物。
- **個人化目標設定**：
    - 輸入年齡、身高、體重、體脂等個人資料。
    - 選擇增肌或減脂等健身目標。
    - 應用程式會根據個人資料和目標，建議每日營養攝取量。
- **進度追蹤**：透過可滑動的資訊卡，清晰地看到今日攝取與目標之間的差距。
- **份量調整**：在主畫面可快速增加或減少食物份量，營養總結會即時更新。
- **本地資料儲存**：所有飲食記錄和個人設定都安全地儲存在裝置本地的 SQLite 資料庫中。

## 🛠️ 技術棧與架構

- **UI 框架**: SwiftUI
- **程式語言**: Swift
- **資料庫**: [SQLite.swift](https://github.com/stephencelis/SQLite.swift) - 用於本地資料庫操作的型別安全 ORM。
- **AI 服務**: Google Gemini Vision API - 用於食物圖像分析。
- **架構模式**:
    - 採用類 MVC 的架構風格，並結合 SwiftUI 的響應式編程范式。
    - **模型 (Model)**: `Food`, `UserProfile`, `NutritionGoals` 等純數據結構。
    - **視圖 (View)**: SwiftUI 視圖，如 `ContentView`, `FoodAddView`, `SettingsView`。
    - **控制器/服務 (Controller/Service)**: 使用單例模式 (Singleton) 的 `DatabaseManager` 和 `GeminiAPI` 來管理數據和 API 請求。

## 🚀 安裝與設定

### 1. 取得專案

```bash
git clone https://github.com/YOUR_USERNAME/Nutrition-Calculator.git
cd Nutrition-Calculator
```

### 2. 設定 Google Gemini API 金鑰

為了讓 AI 照片分析功能正常運作，您需要設定自己的 Google Gemini API 金鑰。

1.  在 `Nutrition Calculator/` 資料夾下，建立一個名為 `Secrets.xcconfig` 的檔案。

    ```bash
    touch "Nutrition Calculator/Secrets.xcconfig"
    ```

2.  在 `Secrets.xcconfig` 檔案中加入以下內容，並將 `YOUR_API_KEY_HERE` 替換成您自己的金鑰：

    ```
    GEMINI_API_KEY = YOUR_API_KEY_HERE
    ```

3.  **重要**: 開啟 Xcode，在專案設定中，將 `Secrets.xcconfig` 檔案連結到您的 Target Build Settings。

    - 前往 `Project Navigator` -> `Nutrition Calculator` (專案) -> `TARGETS` -> `Nutrition Calculator`。
    - 選擇 `Build Settings` -> `All` -> `Levels`。
    - 在 `Configurations` 中，將 `Debug` 和 `Release` 的 `Based on Configuration File` 設定為 `Secrets`。

### 3. 開啟專案

使用 Xcode 開啟 `Nutrition Calculator.xcodeproj` 即可。

## 🏗️ 建置與執行

您可以使用 Xcode 直接建置和執行，或使用以下指令碼：

```bash
# 為模擬器建置 (建議)
xcodebuild -project "Nutrition Calculator.xcodeproj" -scheme "Nutrition Calculator" -destination 'platform=iOS Simulator,name=iPhone 15' build

# 執行所有測試
xcodebuild -project "Nutrition Calculator.xcodeproj" -scheme "Nutrition Calculator" test
```

## 🤝 貢獻

歡迎提交 Pull Request 或回報問題。如果您有任何建議或想新增功能，請隨時提出！

## 📄 授權

本專案採用 [MIT License](LICENSE)。
