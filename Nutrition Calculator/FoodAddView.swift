//
//  FoodAddView.swift
//  Nutrition Calculator
//
//  Created by SHAOYUN HSU on 2025/7/5.
//

import SwiftUI
import PhotosUI

struct FoodAddView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""
    @State private var portions = "1"
    @State private var weighs: String = ""
    @State private var results: [FoodSearchResult] = []
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil
    
    @State private var searchResults: [Food] = []
    @State private var isSearching = false
    @State private var searchDebounceTimer: Timer? = nil

    @State private var isAnalyzing = false
    @State private var isPhotoAnalysisComplete = false
    @State private var isNameSelected = false // Flag to control search result visibility
    @State private var analysisPortions = "1" // For AI analysis

    var date: Date // The date to add the food to
    var onSave: (() -> Void)? // 回傳用 closure

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(String(localized: "food_info_section_header"))) {
                    VStack(alignment: .leading) {
                        TextField(String(localized: "food_name_placeholder"), text: $name)
                        
                        if isAnalyzing {
                            ProgressView("搜尋中...")
                        }
                        
                        if isSearching && !searchResults.isEmpty && !isNameSelected {
                            List(searchResults) { food in
                                Button(action: {
                                    selectFood(food)
                                }) {
                                    VStack(alignment: .leading) {
                                        Text(food.name).font(.headline)
                                        Text(String(format: NSLocalizedString("food_search_result_info", comment: ""), food.calories, food.protein))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            .frame(height: searchResults.isEmpty ? 0 : 150) // Adjust height dynamically
                        }
                    }
                    
                    HStack {
                        TextField(String(localized: "calories_placeholder"), text: $calories)
                            .keyboardType(.decimalPad)
                        Text(String(localized: "calories_title"))
                    }
                    HStack {
                        TextField(String(localized: "protein_placeholder"), text: $protein)
                            .keyboardType(.decimalPad)
                        Text(String(localized: "protein_title"))
                    }
                    HStack {
                        TextField(String(localized: "fat_placeholder"), text: $fat)
                            .keyboardType(.decimalPad)
                        Text(String(localized: "fat_title"))
                    }
                    HStack {
                        TextField(String(localized: "carbs_placeholder"), text: $carbs)
                            .keyboardType(.decimalPad)
                        Text(String(localized: "carbs_title"))
                    }
                    HStack {
                        TextField(String(localized: "portions_placeholder"), text: $portions)
                            .keyboardType(.decimalPad)
                        Text(String(localized: "portions_unit_label"))
                    }
                }
                
                Section(header: Text(String(localized: "recognize_food_from_album_section_header"))) {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text(imageData == nil ? String(localized: "select_photo_button_title") : String(localized: "photo_selected_button_title"))
                            }
                        }
                    if let imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    }

                    if imageData != nil {
                        HStack {
                            Text(String(localized: "analysis_portions_label"))
                            Spacer()
                            TextField("", text: $analysisPortions)
                                .keyboardType(.decimalPad)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text(String(localized: "portions_unit_label"))
                        }
                    }
                    
                    if let imageData {
                        Button(action: {
                            analyzeWithGemini(imageData: imageData)
                        }) {
                            if isAnalyzing {
                                ProgressView(String(localized: "analyzing_message"))
                            } else {
                                Text(String(localized: "analyze_photo_with_gemini_button"))
                            }
                        }
                        .disabled(isAnalyzing)
                    }
                }
            }
            .onChange(of: name) { _, newValue in
                if isPhotoAnalysisComplete {
                    isPhotoAnalysisComplete = false // Reset the flag
                    return
                }
                
                isNameSelected = false // Reset when user types
                searchDebounceTimer?.invalidate()
                
                if newValue.isEmpty {
                    isSearching = false
                    searchResults = []
                    return
                }
                
                isSearching = true
                searchResults = DatabaseManager.shared.searchFood(byName: newValue)
                
                if searchResults.isEmpty {
                    searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
                        searchFoodOnline(foodName: newValue)
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                if let newItem = newValue {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            imageData = data
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "add_food_navigation_title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "cancel_button")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "save_button")) {
                        saveFood()
                    }
                    .disabled(name.isEmpty || calories.isEmpty || protein.isEmpty || fat.isEmpty || carbs.isEmpty)
                }
            }
        }
    }

    private func selectFood(_ food: Food) {
        // Only update the name if it's a food from the local database (id != 0)
        if food.id != 0 {
            name = food.name
        }
        
        calories = String(format: "%.1f", food.calories)
        protein = String(format: "%.1f", food.protein)
        fat = String(format: "%.1f", food.fat)
        carbs = String(format: "%.1f", food.carbs)
        
        if let weighsValue = food.weighs {
            weighs = String(format: "%.1f", weighsValue)
        }
        
        if let resultsValue = food.results {
            results = resultsValue
        }
        
        isNameSelected = true
        isSearching = false
        searchResults = []
    }

    private func saveFood() {
        guard var cal = Double(calories),
              var pro = Double(protein),
              var fa = Double(fat),
              var car = Double(carbs),
              let por = Double(portions) else {
            return
        }
        
        if por > 1.0 {
            cal /= por
            pro /= por
            fa /= por
            car /= por
        }

        DatabaseManager.shared.addFood(
            name: name,
            calories: cal,
            protein: pro,
            fat: fa,
            carbs: car,
            date: date, // Use the provided date
            portions: 1.0, // 永遠以一人份儲存到資料庫
            weighs: Double(weighs),
            results: results
        )
        onSave?() // 通知主畫面刷新
        dismiss()
    }
    
    private func searchFoodOnline(foodName: String) {
        isAnalyzing = true
        print("🌐 FoodAddView: Starting Gemini online search for '\(foodName)'")

        GeminiAPI.shared.searchFoodNutrition(foodName: foodName) { result in
            switch result {
            case .success(let responseText):
                print("📋 FoodAddView: Received response text from online search: \(responseText)")
                
                var jsonText = responseText
                if responseText.contains("```json") {
                    let components = responseText.components(separatedBy: "```json")
                    if components.count > 1 {
                        let afterJson = components[1]
                        let jsonPart = afterJson.components(separatedBy: "```")[0]
                        jsonText = jsonPart.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                
                if let data = jsonText.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ FoodAddView: Successfully parsed JSON from online search")
                    
                    DispatchQueue.main.async {
                        var foodResults: [FoodSearchResult]? = nil
                        if let resultsArray = dict["results"] as? [[String: Any]] {
                            foodResults = resultsArray.compactMap { resultDict in
                                guard let source = resultDict["source"] as? String,
                                      let calories = (resultDict["calories"] as? NSNumber)?.doubleValue,
                                      let protein = (resultDict["protein"] as? NSNumber)?.doubleValue,
                                      let fat = (resultDict["fat"] as? NSNumber)?.doubleValue,
                                      let carbs = (resultDict["carbs"] as? NSNumber)?.doubleValue else {
                                    return nil
                                }
                                return FoodSearchResult(source: source, calories: calories, protein: protein, fat: fat, carbs: carbs)
                            }
                        }
                        
                        let food = Food(
                            id: 0, // Temporary ID
                            name: (dict["name"] as? String) ?? foodName,
                            shortName: "",
                            calories: (dict["calories"] as? NSNumber)?.doubleValue ?? 0,
                            protein: (dict["protein"] as? NSNumber)?.doubleValue ?? 0,
                            fat: (dict["fat"] as? NSNumber)?.doubleValue ?? 0,
                            carbs: (dict["carbs"] as? NSNumber)?.doubleValue ?? 0,
                            date: Date(),
                            portions: 1.0,
                            weighs: (dict["weighs"] as? NSNumber)?.doubleValue,
                            results: foodResults
                        )
                        // Add the online result to the search list for user selection
                        self.searchResults = [food]
                    }
                } else {
                    print("⚠️ FoodAddView: Response from online search is not JSON format")
                }
            case .failure(let error):
                print("❌ FoodAddView: Gemini online search failed: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                isAnalyzing = false
            }
        }
    }
    
    private func analyzeWithGemini(imageData: Data) {
        isAnalyzing = true
        searchDebounceTimer?.invalidate() // Cancel any pending online search
        print("🍽️ FoodAddView: Starting Gemini analysis")
        
        let portionsToAnalyze = Double(analysisPortions) ?? 1.0

        GeminiAPI.shared.analyzeFood(imageData: imageData) { result in
            switch result {
            case .success(let responseText):
                print("📋 FoodAddView: Received response text: \(responseText)")
                
                var jsonText = responseText
                if responseText.contains("```json") {
                    let components = responseText.components(separatedBy: "```json")
                    if components.count > 1 {
                        let afterJson = components[1]
                        let jsonPart = afterJson.components(separatedBy: "```")[0]
                        jsonText = jsonPart.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("🔍 Extracted JSON from markdown: \(jsonText)")
                    }
                }
                
                if let data = jsonText.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ FoodAddView: Successfully parsed JSON dictionary")
                    print("📊 Parsed data: \(dict)")
                    
                    DispatchQueue.main.async {
                        isPhotoAnalysisComplete = true // Set the flag
                        let oldName = self.name
                        let oldCalories = self.calories
                        let oldProtein = self.protein
                        let oldFat = self.fat
                        let oldCarbs = self.carbs
                        
                        self.name = (dict["name"] as? String) ?? ""
                        
                        let caloriesValue = (dict["calories"] as? NSNumber)?.doubleValue ?? 0
                        let proteinValue = (dict["protein"] as? NSNumber)?.doubleValue ?? 0
                        let fatValue = (dict["fat"] as? NSNumber)?.doubleValue ?? 0
                        let carbsValue = (dict["carbs"] as? NSNumber)?.doubleValue ?? 0

                        self.calories = String(format: "%.1f", caloriesValue / portionsToAnalyze)
                        self.protein = String(format: "%.1f", proteinValue / portionsToAnalyze)
                        self.fat = String(format: "%.1f", fatValue / portionsToAnalyze)
                        self.carbs = String(format: "%.1f", carbsValue / portionsToAnalyze)
                        self.portions = String(format: "%.1f", portionsToAnalyze) // Update portions field with analysis portions
                        
                        if let weighsValue = (dict["weighs"] as? NSNumber)?.doubleValue {
                            self.weighs = String(format: "%.1f", weighsValue)
                        }
                        
                        if let resultsArray = dict["results"] as? [[String: Any]] {
                            self.results = resultsArray.compactMap { resultDict in
                                guard let source = resultDict["source"] as? String,
                                      let calories = (resultDict["calories"] as? NSNumber)?.doubleValue,
                                      let protein = (resultDict["protein"] as? NSNumber)?.doubleValue,
                                      let fat = (resultDict["fat"] as? NSNumber)?.doubleValue,
                                      let carbs = (resultDict["carbs"] as? NSNumber)?.doubleValue else {
                                    return nil
                                }
                                return FoodSearchResult(source: source, calories: calories, protein: protein, fat: fat, carbs: carbs)
                            }
                        }

                        print("🔄 FoodAddView: Updated fields (per one portion):")
                        print("   Name: '\(oldName)' → '\(self.name)'")
                        print("   Calories: '\(oldCalories)' → '\(self.calories)'")
                        print("   Protein: '\(oldProtein)' → '\(self.protein)'")
                        print("   Fat: '\(oldFat)' → '\(self.fat)'")
                        print("   Carbs: '\(oldCarbs)' → '\(self.carbs)'''")
                        print("   Weighs: '\(self.weighs)'")
                        print("   Results: '\(self.results)'")
                    }
                } else {
                    print("⚠️ FoodAddView: Response is not JSON format")
                    print("Response text: \(responseText)")
                    
                    DispatchQueue.main.async {
                        print("ℹ️ Image was not recognized as food by Gemini")
                    }
                }
            case .failure(let error):
                print("❌ FoodAddView: Gemini analysis failed: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                isAnalyzing = false
            }
        }
    }

}