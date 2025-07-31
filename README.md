# 營養計算機 (Nutrition Calculator)

這是一款使用 SwiftUI 開發的 iOS 應用程式，旨在幫助使用者輕鬆追蹤每日的營養攝取，並根據個人身體數據和健身目標，提供個人化的營養建議。

## 🌟 主要特色

*   **AI 食物辨識**：透過整合 Google Gemini API，使用者只需拍攝食物照片，App 即可自動辨識食物名稱並填入其營養成分（熱量、蛋白質、脂肪、碳水化合物）。
*   **個人化營養目標**：
    *   使用者可以輸入年齡、身高、體重、體脂等個人資料。
    *   可設定「增肌」或「減脂」等不同的健身目標。
    *   App 會根據 Harris-Benedict 公式計算基礎代謝率 (BMR) 和每日總消耗量 (TDEE)，並結合健身目標，自動生成建議的每日營養攝取目標。
*   **詳細的每日追蹤**：
    *   主畫面以分頁方式呈現過去七日的飲食紀錄。
    *   清晰的目標進度條，顯示當日熱量、蛋白質、脂肪的攝取進度。
    *   可隨時調整當日食物的份量。
*   **快速新增食物**：
    *   提供「快速選取」功能，列出最常吃的食物，��擊即可快速加入。
    *   新增食物時，會自動搜尋歷史紀錄，方便再次輸入。
*   **本地數據儲存**：所有飲食紀錄、個人資料和目標都安全地儲存在裝置本地的 SQLite 資料庫中，確保隱私。

## 🚀 如何使用

1.  **設定個人目標**：
    *   初次使用時，請至「設定」頁面 (主畫面左上角的齒輪圖示)。
    *   填寫您的個人資料（年齡、性別、體重等）和健身目標。
    *   您可以手動設定每日營養目標，或點擊「根據個人資料生成建議目標」來自動計算。
2.  **新增食物**：
    *   點擊主畫面右上角的「+ 新增今日食物」。
    *   **手動輸入**：直接填寫食物的各項營養數值。
    *   **AI 辨識**：點擊「選擇照片」，從相簿選取食物圖片，然後點擊「用 Gemini 分析照片自動填入」。
    *   **歷史搜尋**：在輸入食物名稱時，下方會自動顯示符合的歷史紀錄，點擊即可帶入。
3.  **快速選取**：
    *   在主畫面的「今日」頁面，向左滑動可進入「快速選取食物」頁面。
    *   這裡會顯示您最常吃的食物，點擊即可加入一整份。
4.  **查看與管理**：
    *   在主畫面左右滑動，可以查看過去七天的飲食紀錄。
    *   在食物清單上向左滑��，可以刪除該筆紀錄。
    *   點擊今日食物旁的 `+` / `-` 按鈕，可以快速調整份量。

## 🛠️ 所用技術

*   **UI 框架**: SwiftUI
*   **資料庫**: SQLite.swift (用於操作本地 SQLite 資料庫)
*   **AI 模型**: Google Gemini API (用於圖像辨識與營養分析)
*   **圖片選擇**: PhotosUI

## 📋 安裝與設定

1.  **Clone 專案**：
    ```bash
    git clone https://github.com/shaoyunhsu/Nutrition-Calculator.git
    ```
2.  **開啟專案**：
    使用 Xcode 開啟 `Nutrition Calculator.xcodeproj`。

3.  **設定 Gemini API 金鑰**：
    *   前往 [Google AI Studio](https://aistudio.google.com/app/apikey) 取得您的 API 金鑰。
    *   在 Xcode 中，找到 `Nutrition Calculator` Target。
    *   前往 `Build Settings` -> `User-Defined`。
    *   找到名為 `GEMINI_API_KEY` 的設定。
    *   將您的 Google Gemini API 金鑰貼入此欄位。

    ![Xcode Build Settings](https://i.imgur.com/your-image-link.png)  <!-- 這裡可以換成設定教學圖片 -->

4.  **編譯與執行**：
    選擇您的模擬器或實體裝置，點擊 "Run" 按鈕。

## 🏛️ 資料庫實體關係圖 (ERD)

```mermaid
erDiagram
    foods {
        INTEGER id PK "主鍵"
        TEXT name
        TEXT shortName
        REAL calories
        REAL protein
        REAL fat
        REAL carbs
        REAL date
        REAL portions
        REAL weighs "可選"
        TEXT results "JSON 字串，可選"
        TEXT imagePath "可選"
    }

    user_profiles {
        INTEGER id PK "主鍵"
        INTEGER age
        TEXT gender
        REAL weight
        REAL body_fat_percentage
        REAL height
        TEXT fitness_goal
        REAL created_at
    }

    nutrition_goals {
        INTEGER id PK "主鍵"
        REAL daily_calories
        REAL daily_protein
        REAL daily_fat
        REAL created_at
    }

    user_profiles ||..o{ nutrition_goals : "生成建議"
    user_profiles ||..o{ foods : "影響"
    nutrition_goals ||..o{ foods : "作為目標"
}
```

## Build comments
```bash
ad91ce7eab9e19c6bab06887d54c3f5867471c44 add nutrient names in Add new Food view
126fc7eabf0184e3b86ef2b6fbcbb1cddd94 add portion services field.
977767452262cb0b356f5d7a0826a1377a5df5e3 UiUpdate:short name
4fb2a5f49a6f95958fc0f0c19720d06c029294d7 project configuration update
f45fce0593c74a78238efc620b043c3e0264603d multilang update
9fdb81544f40a1f4008a8d65d6b63dd0b0fec6f6 add default value for db update
ae8540dd032f62d8342c995a9b0b5e55292f79d2 claude.md updated
b6987a46645df6d7311db79ef0f533dcd913ff52 multi-language version
11cc07c30e6b8a1a6e81ebc8446c4715141292a1 Ignore Package.resolved
db5c1d0c87b79bdc729ced6ef0126d3ad15eed9b number decimal format
fa3267098b3fc92099452825f7139fa95e2135cd adjust gesture
6ceaf13b134b34569335b6f9d644eb833e242a26 add icon
a4afa074d09cc5c7b445ab17acb29079e10db355 layout tuning
5c58f5c49f1178ae87ca500a05ae94316385c9b4 mobile device test
```

---
由 SHAOYUN HSU 於 2025 年製作。