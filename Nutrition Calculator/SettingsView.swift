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
                Section(header: Text(String(localized: "personal_info_section_header"))) {
                    HStack {
                        Text(String(localized: "age_label"))
                        Spacer()
                        TextField(String(localized: "age_placeholder"), text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text(String(localized: "years_old_unit"))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(String(localized: "gender_label"))
                        Spacer()
                        Picker(String(localized: "gender_picker_title"), selection: $selectedGender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.displayName).tag(gender)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                    }
                    
                    HStack {
                        Text(String(localized: "weight_label"))
                        Spacer()
                        TextField(String(localized: "weight_placeholder"), text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(String(localized: "kg_unit"))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(String(localized: "body_fat_percentage_label"))
                        Spacer()
                        TextField(String(localized: "body_fat_percentage_placeholder"), text: $bodyFatPercentage)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(String(localized: "percentage_unit"))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(String(localized: "height_label"))
                        Spacer()
                        TextField(String(localized: "height_placeholder"), text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(String(localized: "cm_unit"))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(String(localized: "fitness_goal_label"))
                        Spacer()
                        Picker(String(localized: "fitness_goal_picker_title"), selection: $selectedFitnessGoal) {
                            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                                Text(goal.displayName).tag(goal)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                    }
                }
                
                Section(header: Text(String(localized: "daily_nutrition_goals_section_header"))) {
                    HStack {
                        Text(String(localized: "calories_goal_label"))
                            .foregroundColor(.red)
                        Spacer()
                        TextField(String(localized: "calories_goal_placeholder"), text: $dailyCalories)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(String(localized: "kcal_unit"))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(String(localized: "protein_goal_label"))
                            .foregroundColor(.blue)
                        Spacer()
                        TextField(String(localized: "protein_goal_placeholder"), text: $dailyProtein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(String(localized: "g_unit"))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(String(localized: "fat_goal_label"))
                            .foregroundColor(.orange)
                        Spacer()
                        TextField(String(localized: "fat_goal_placeholder"), text: $dailyFat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(String(localized: "g_unit"))
                            .foregroundColor(.secondary)
                    }
                    
                    Button(String(localized: "generate_recommendation_button")) {
                        generateRecommendations()
                    }
                    .foregroundColor(.orange)
                }
                
                Section(footer: Text(String(localized: "settings_footer_text"))) {
                    Button(String(localized: "save_settings_button")) {
                        saveSettings()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
            .navigationTitle(String(localized: "nutrition_goal_settings_navigation_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "cancel_button")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
            .alert(String(localized: "settings_saved_alert_title"), isPresented: $showSaveAlert) {
                Button(String(localized: "ok_button")) {
                    dismiss()
                }
            } message: {
                Text(String(localized: "settings_saved_alert_message"))
            }
            .alert(String(localized: "recommended_nutrition_goals_alert_title"), isPresented: $showRecommendationAlert) {
                Button(String(localized: "use_recommended_values_button")) {
                    if let recommended = recommendedGoals {
                        dailyCalories = String(format: "%.0f", recommended.dailyCalories)
                        dailyProtein = String(format: "%.1f", recommended.dailyProtein)
                        dailyFat = String(format: "%.1f", recommended.dailyFat)
                    }
                }
                Button(String(localized: "cancel_button"), role: .cancel) { }
            } message: {
                if let recommended = recommendedGoals {
                    Text(String(format: NSLocalizedString("recommended_goals_message", comment: ""), selectedFitnessGoal.displayName as CVarArg, recommended.dailyCalories, recommended.dailyProtein, recommended.dailyFat))
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