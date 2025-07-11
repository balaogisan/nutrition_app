import Foundation

struct Food: Identifiable {
    let id: Int64
    let name: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let date: Date
    var portions: Double
    
    // 根據份數計算實際營養值
    var actualCalories: Double { calories * portions }
    var actualProtein: Double { protein * portions }
    var actualFat: Double { fat * portions }
    var actualCarbs: Double { carbs * portions }
    
    // 初始化時預設1份
    init(id: Int64, name: String, calories: Double, protein: Double, fat: Double, carbs: Double, date: Date, portions: Double = 1.0) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.date = date
        self.portions = portions
    }
}

struct DailySummary {
    let totalCalories: Double
    let totalProtein: Double
    let totalFat: Double
    let totalCarbs: Double
    let date: Date
    let foodCount: Int
    
    var isEmpty: Bool {
        foodCount == 0
    }
}

enum Gender: String, CaseIterable {
    case male = "male"
    case female = "female"
    
    var displayName: String {
        switch self {
        case .male: return String(localized: "gender_male")
        case .female: return String(localized: "gender_female")
        }
    }
}

enum FitnessGoal: String, CaseIterable {
    case buildMuscle = "build_muscle"
    case loseFat = "lose_fat"
    
    var displayName: String {
        switch self {
        case .buildMuscle: return String(localized: "fitness_goal_build_muscle")
        case .loseFat: return String(localized: "fitness_goal_lose_fat")
        }
    }
    
    // 熱量調整係數
    var calorieAdjustmentFactor: Double {
        switch self {
        case .buildMuscle: return 1.1 // 增肌：+10%熱量
        case .loseFat: return 0.85 // 減脂：-15%熱量
        }
    }
    
    // 蛋白質需求係數 (每公斤體重)
    var proteinRequirement: Double {
        switch self {
        case .buildMuscle: return 2.2 // 增肌：2.2g/kg
        case .loseFat: return 2.0 // 減脂：2.0g/kg
        }
    }
    
    // 脂肪比例 (佔總熱量百分比)
    var fatPercentage: Double {
        switch self {
        case .buildMuscle: return 0.30 // 增肌：30%
        case .loseFat: return 0.25 // 減脂：25%
        }
    }
}

struct UserProfile {
    let age: Int
    let gender: Gender
    let weight: Double // kg
    let bodyFatPercentage: Double // %
    let height: Double // cm
    let fitnessGoal: FitnessGoal
    
    static let defaultProfile = UserProfile(
        age: 30,
        gender: .male,
        weight: 70.0,
        bodyFatPercentage: 15.0,
        height: 170.0,
        fitnessGoal: .buildMuscle
    )
    
    // Harris-Benedict 公式計算基礎代謝率 (BMR)
    var bmr: Double {
        switch gender {
        case .male:
            return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * Double(age))
        case .female:
            return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * Double(age))
        }
    }
    
    // 建議每日總消耗量 (TDEE) - 使用輕度活動係數 1.375
    var tdee: Double {
        return bmr * 1.375
    }
    
    // 根據健身目標調整後的熱量目標
    var adjustedCalories: Double {
        return tdee * fitnessGoal.calorieAdjustmentFactor
    }
    
    // 蛋白質目標 (根據健身目標)
    var proteinGoal: Double {
        return weight * fitnessGoal.proteinRequirement
    }
    
    // 脂肪目標 (根據健身目標)
    var fatGoal: Double {
        return adjustedCalories * fitnessGoal.fatPercentage / 9 // 9 kcal per gram of fat
    }
    
    // BMI 計算
    var bmi: Double {
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    // 瘦體重計算
    var leanBodyMass: Double {
        return weight * (1 - bodyFatPercentage / 100)
    }
}

struct NutritionGoals {
    let dailyCalories: Double
    let dailyProtein: Double
    let dailyFat: Double
    
    static let defaultGoals = NutritionGoals(
        dailyCalories: 2000,
        dailyProtein: 50,
        dailyFat: 65
    )
    
    // 根據使用者資料生成建議目標
    static func recommendedGoals(for profile: UserProfile) -> NutritionGoals {
        return NutritionGoals(
            dailyCalories: profile.adjustedCalories,
            dailyProtein: profile.proteinGoal,
            dailyFat: profile.fatGoal
        )
    }
}

struct GoalProgress {
    let caloriesProgress: Double
    let proteinProgress: Double
    let fatProgress: Double
    
    let caloriesRemaining: Double
    let proteinRemaining: Double
    let fatRemaining: Double
    
    let caloriesPercentage: Double
    let proteinPercentage: Double
    let fatPercentage: Double
    
    init(summary: DailySummary, goals: NutritionGoals) {
        caloriesProgress = summary.totalCalories
        proteinProgress = summary.totalProtein
        fatProgress = summary.totalFat
        
        caloriesRemaining = goals.dailyCalories - summary.totalCalories
        proteinRemaining = goals.dailyProtein - summary.totalProtein
        fatRemaining = goals.dailyFat - summary.totalFat
        
        caloriesPercentage = goals.dailyCalories > 0 ? (summary.totalCalories / goals.dailyCalories) * 100 : 0
        proteinPercentage = goals.dailyProtein > 0 ? (summary.totalProtein / goals.dailyProtein) * 100 : 0
        fatPercentage = goals.dailyFat > 0 ? (summary.totalFat / goals.dailyFat) * 100 : 0
    }
}

