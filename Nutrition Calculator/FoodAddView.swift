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
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil
    
    @State private var searchResults: [Food] = []
    @State private var isSearching = false

    var onSave: (() -> Void)? // 回傳用 closure

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(String(localized: "food_info_section_header"))) {
                    TextField(String(localized: "food_name_placeholder"), text: $name)
                    
                    if isSearching && !searchResults.isEmpty {
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
                    }
                    
                    TextField(String(localized: "calories_placeholder"), text: $calories)
                        .keyboardType(.decimalPad)
                    TextField(String(localized: "protein_placeholder"), text: $protein)
                        .keyboardType(.decimalPad)
                    TextField(String(localized: "fat_placeholder"), text: $fat)
                        .keyboardType(.decimalPad)
                    TextField(String(localized: "carbs_placeholder"), text: $carbs)
                        .keyboardType(.decimalPad)
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
                    
                    if let imageData {
                        Button(String(localized: "analyze_photo_with_gemini_button")) {
                            analyzeWithGemini(imageData: imageData)
                        }
                    }
                }
            }
            .onChange(of: name) { _, newValue in
                if newValue.isEmpty {
                    isSearching = false
                    searchResults = []
                } else {
                    isSearching = true
                    searchResults = DatabaseManager.shared.searchFood(byName: newValue)
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
        name = food.name
        calories = String(format: "%.1f", food.calories)
        protein = String(format: "%.1f", food.protein)
        fat = String(format: "%.1f", food.fat)
        carbs = String(format: "%.1f", food.carbs)
        
        // 清空搜尋結果並隱藏列表
        isSearching = false
        searchResults = []
    }

    private func saveFood() {
        guard let cal = Double(calories),
              let pro = Double(protein),
              let fa = Double(fat),
              let car = Double(carbs) else {
            return
        }
        DatabaseManager.shared.addFood(
            name: name,
            calories: cal,
            protein: pro,
            fat: fa,
            carbs: car
        )
        onSave?() // 通知主畫面刷新
        dismiss()
    }
    
    private func analyzeWithGemini(imageData: Data) {
        print("🍽️ FoodAddView: Starting Gemini analysis")
        
        GeminiAPI.shared.analyzeFood(imageData: imageData) { result in
            switch result {
            case .success(let responseText):
                print("📋 FoodAddView: Received response text: \(responseText)")
                
                // Extract JSON from markdown format if present
                var jsonText = responseText
                if responseText.contains("```json") {
                    // Extract content between ```json and ```
                    let components = responseText.components(separatedBy: "```json")
                    if components.count > 1 {
                        let afterJson = components[1]
                        let jsonPart = afterJson.components(separatedBy: "```")[0]
                        jsonText = jsonPart.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("🔍 Extracted JSON from markdown: \(jsonText)")
                    }
                }
                
                // Try to parse as JSON
                if let data = jsonText.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ FoodAddView: Successfully parsed JSON dictionary")
                    print("📊 Parsed data: \(dict)")
                    
                    DispatchQueue.main.async {
                        let oldName = self.name
                        let oldCalories = self.calories
                        let oldProtein = self.protein
                        let oldFat = self.fat
                        let oldCarbs = self.carbs
                        
                        self.name = (dict["name"] as? String) ?? ""
                        if let cal = dict["calories"] { self.calories = "\(cal)" }
                        if let pro = dict["protein"] { self.protein = "\(pro)" }
                        if let fat = dict["fat"] { self.fat = "\(fat)" }
                        if let car = dict["carbs"] { self.carbs = "\(car)" }
                        
                        print("🔄 FoodAddView: Updated fields:")
                        print("   Name: '\(oldName)' → '\(self.name)'")
                        print("   Calories: '\(oldCalories)' → '\(self.calories)'")
                        print("   Protein: '\(oldProtein)' → '\(self.protein)'")
                        print("   Fat: '\(oldFat)' → '\(self.fat)'")
                        print("   Carbs: '\(oldCarbs)' → '\(self.carbs)'")
                    }
                } else {
                    print("⚠️ FoodAddView: Response is not JSON format")
                    print("Response text: \(responseText)")
                    
                    // Show alert to user that the image wasn't recognized as food
                    DispatchQueue.main.async {
                        // Here you could show an alert or update UI to indicate the image wasn't recognized
                        print("ℹ️ Image was not recognized as food by Gemini")
                    }
                }
            case .failure(let error):
                print("❌ FoodAddView: Gemini analysis failed: \(error.localizedDescription)")
            }
        }
    }

}

