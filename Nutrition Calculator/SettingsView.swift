//
//  SettingsView.swift
//  Nutrition Calculator
//
//  Created by SHAOYUN HSU on 2025/7/5.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 營養目標
    @State private var dailyCalories: String = ""
    @State private var dailyProtein: String = ""
    @State private var dailyFat: String = ""
    
    // 個人資料
    @State private var age: String = ""
    @State private var selectedGender: Gender = .male
    @State private var weight: String = ""
    @State private var bodyFatPercentage: String = ""
    @State private var height: String = ""
    @State private var selectedFitnessGoal: FitnessGoal = .buildMuscle
    
    @State private var showSaveAlert = false
    @State private var showRecommendationAlert = false
    @State private var recommendedGoals: NutritionGoals?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("個人資料")) {
                    HStack {
                        Text("年齡")
                        Spacer()
                        TextField("30", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("歲")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("性別")
                        Spacer()
                        Picker("性別", selection: $selectedGender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.displayName).tag(gender)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                    }
                    
                    HStack {
                        Text("體重")
                        Spacer()
                        TextField("70", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("體脂率")
                        Spacer()
                        TextField("15", text: $bodyFatPercentage)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("身高")
                        Spacer()
                        TextField("170", text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("健身目標")
                        Spacer()
                        Picker("健身目標", selection: $selectedFitnessGoal) {
                            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                                Text(goal.displayName).tag(goal)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                    }
                }
                
                Section(header: Text("每日營養目標")) {
                    HStack {
                        Text("熱量目標")
                            .foregroundColor(.red)
                        Spacer()
                        TextField("2000", text: $dailyCalories)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kcal")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("蛋白質目標")
                            .foregroundColor(.blue)
                        Spacer()
                        TextField("50", text: $dailyProtein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("脂肪目標")
                            .foregroundColor(.orange)
                        Spacer()
                        TextField("65", text: $dailyFat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("根據個人資料生成建議目標") {
                        generateRecommendations()
                    }
                    .foregroundColor(.orange)
                }
                
                Section(footer: Text("設定個人資料和每日營養攝取目標，幫助您追蹤營養均衡")) {
                    Button("儲存設定") {
                        saveSettings()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
            .navigationTitle("營養目標設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
            .alert("設定已儲存", isPresented: $showSaveAlert) {
                Button("確定") {
                    dismiss()
                }
            } message: {
                Text("您的個人資料和營養目標已成功更新")
            }
            .alert("建議營養目標", isPresented: $showRecommendationAlert) {
                Button("使用建議值") {
                    if let recommended = recommendedGoals {
                        dailyCalories = String(format: "%.0f", recommended.dailyCalories)
                        dailyProtein = String(format: "%.1f", recommended.dailyProtein)
                        dailyFat = String(format: "%.1f", recommended.dailyFat)
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                if let recommended = recommendedGoals {
                    Text("根據您的個人資料和「\(selectedFitnessGoal.displayName)」目標，建議的每日營養目標為：\n熱量：\(recommended.dailyCalories, specifier: "%.0f") kcal\n蛋白質：\(recommended.dailyProtein, specifier: "%.1f") g\n脂肪：\(recommended.dailyFat, specifier: "%.1f") g")
                }
            }
        }
    }
    
    private func loadCurrentSettings() {
        let goals = DatabaseManager.shared.getNutritionGoals()
        dailyCalories = String(format: "%.0f", goals.dailyCalories)
        dailyProtein = String(format: "%.1f", goals.dailyProtein)
        dailyFat = String(format: "%.1f", goals.dailyFat)
        
        let profile = DatabaseManager.shared.getUserProfile()
        age = String(profile.age)
        selectedGender = profile.gender
        weight = String(format: "%.1f", profile.weight)
        bodyFatPercentage = String(format: "%.1f", profile.bodyFatPercentage)
        height = String(format: "%.1f", profile.height)
        selectedFitnessGoal = profile.fitnessGoal
    }
    
    private func saveSettings() {
        guard let calories = Double(dailyCalories),
              let protein = Double(dailyProtein),
              let fat = Double(dailyFat),
              let userAge = Int(age),
              let userWeight = Double(weight),
              let userBodyFat = Double(bodyFatPercentage),
              let userHeight = Double(height),
              calories > 0, protein > 0, fat > 0,
              userAge > 0, userWeight > 0, userBodyFat >= 0, userHeight > 0 else {
            return
        }
        
        let goals = NutritionGoals(
            dailyCalories: calories,
            dailyProtein: protein,
            dailyFat: fat
        )
        
        let profile = UserProfile(
            age: userAge,
            gender: selectedGender,
            weight: userWeight,
            bodyFatPercentage: userBodyFat,
            height: userHeight,
            fitnessGoal: selectedFitnessGoal
        )
        
        DatabaseManager.shared.saveNutritionGoals(goals)
        DatabaseManager.shared.saveUserProfile(profile)
        showSaveAlert = true
    }
    
    private func generateRecommendations() {
        guard let userAge = Int(age),
              let userWeight = Double(weight),
              let userBodyFat = Double(bodyFatPercentage),
              let userHeight = Double(height),
              userAge > 0, userWeight > 0, userBodyFat >= 0, userHeight > 0 else {
            return
        }
        
        let profile = UserProfile(
            age: userAge,
            gender: selectedGender,
            weight: userWeight,
            bodyFatPercentage: userBodyFat,
            height: userHeight,
            fitnessGoal: selectedFitnessGoal
        )
        
        recommendedGoals = NutritionGoals.recommendedGoals(for: profile)
        showRecommendationAlert = true
    }
}

#Preview {
    SettingsView()
}