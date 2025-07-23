//
//  Untitled.swift
//  Nutrition Calculator
//
//  Created by SHAOYUN HSU on 2025/7/5.
//
import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?

    // 食物資料表
    let foods = Table("foods")
    let id = Expression<Int64>("id")
    let name = Expression<String>("name")
    let shortName = Expression<String>("shortName")
    let calories = Expression<Double>("calories")
    let protein = Expression<Double>("protein")
    let fat = Expression<Double>("fat")
    let carbs = Expression<Double>("carbs")
    let date = Expression<Date>("date")
    let portions = Expression<Double>("portions")
    
    // 營養目標資料表
    let goals = Table("nutrition_goals")
    let goalId = Expression<Int64>("id")
    let dailyCalories = Expression<Double>("daily_calories")
    let dailyProtein = Expression<Double>("daily_protein")
    let dailyFat = Expression<Double>("daily_fat")
    let createdAt = Expression<Date>("created_at")
    
    // 使用者個人資料表
    let userProfiles = Table("user_profiles")
    let profileId = Expression<Int64>("id")
    let age = Expression<Int>("age")
    let gender = Expression<String>("gender")
    let weight = Expression<Double>("weight")
    let bodyFatPercentage = Expression<Double>("body_fat_percentage")
    let height = Expression<Double>("height")
    let fitnessGoal = Expression<String>("fitness_goal")
    let profileCreatedAt = Expression<Date>("created_at")

    private init() {
        // 找到 app document 資料夾路徑
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbPath = documentDirectory.appendingPathComponent("nutrition.sqlite3").path
        do {
            db = try Connection(dbPath)
            createTable()
        } catch {
            print("無法開啟資料庫: \(error)")
        }
    }

    private func createTable() {
        do {
            // 建立食物資料表
            try db?.run(foods.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(name)
                t.column(shortName, defaultValue: "") // Add shortName with a default value
                t.column(calories)
                t.column(protein)
                t.column(fat)
                t.column(carbs)
                t.column(date)
                t.column(portions, defaultValue: 1.0)
            })
            
            // Add shortName column for existing tables (for backward compatibility)
            do {
                try db?.run("ALTER TABLE foods ADD COLUMN shortName TEXT DEFAULT ''")
            } catch {
                // Ignore error if column already exists
            }
            
            // 新增份數欄位 (為舊版本相容性)
            do {
                try db?.run("ALTER TABLE foods ADD COLUMN portions REAL DEFAULT 1.0")
            } catch {
                // 如果欄位已存在，忽略錯誤
            }
            
            // 建立營養目標資料表
            try db?.run(goals.create(ifNotExists: true) { t in
                t.column(goalId, primaryKey: .autoincrement)
                t.column(dailyCalories)
                t.column(dailyProtein)
                t.column(dailyFat)
                t.column(createdAt)
            })
            
            // 建立使用者個人資料表
            try db?.run(userProfiles.create(ifNotExists: true) { t in
                t.column(profileId, primaryKey: .autoincrement)
                t.column(age)
                t.column(gender)
                t.column(weight)
                t.column(bodyFatPercentage)
                t.column(height)
                t.column(fitnessGoal)
                t.column(profileCreatedAt)
            })
            
            // 新增健身目標欄位 (為舊版本相容性)
            do {
                try db?.run("ALTER TABLE user_profiles ADD COLUMN fitness_goal TEXT DEFAULT 'build_muscle'")
            } catch {
                // 如果欄位已存在，忽略錯誤
            }
        } catch {
            print("建立資料表失敗: \(error)")
        }
    }

    // 範例：新增一筆食物
    func addFood(name: String, calories: Double, protein: Double, fat: Double, carbs: Double, date: Date = Date(), portions: Double = 1.0) {
        do {
            let shortName = String(name.prefix(3))
            let insert = foods.insert(
                self.name <- name,
                self.shortName <- shortName,
                self.calories <- calories,
                self.protein <- protein,
                self.fat <- fat,
                self.carbs <- carbs,
                self.date <- date,
                self.portions <- portions
            )
            try db?.run(insert)
        } catch {
            print("新增食物失敗: \(error)")
        }
    }
    
    
    func getAllFoods() -> [Food] {
        var result: [Food] = []
        do {
            for food in try db!.prepare(foods) {
                let item = Food(
                    id: food[id],
                    name: food[name],
                    shortName: food[shortName],
                    calories: food[calories],
                    protein: food[protein],
                    fat: food[fat],
                    carbs: food[carbs],
                    date: food[date],
                    portions: food[portions]
                )
                result.append(item)
            }
        } catch {
            print("查詢食物失敗: \(error)")
        }
        return result
    }
    
    func deleteFood(id: Int64) {
        do {
            let food = foods.filter(self.id == id)
            try db?.run(food.delete())
            print("刪除食物成功: ID \(id)")
        } catch {
            print("刪除食物失敗: \(error)")
        }
    }
    
    func getFoods(for date: Date) -> [Food] {
        var result: [Food] = []
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            let query = foods.filter(self.date >= startOfDay && self.date < endOfDay)
            for food in try db!.prepare(query) {
                let item = Food(
                    id: food[id],
                    name: food[name],
                    shortName: food[shortName],
                    calories: food[calories],
                    protein: food[protein],
                    fat: food[fat],
                    carbs: food[carbs],
                    date: food[self.date],
                    portions: food[portions]
                )
                result.append(item)
            }
        } catch {
            print("查詢指定日期食物失敗: \(error)")
        }
        return result
    }
    
    func getSummary(for date: Date) -> DailySummary {
        let foodsForDate = getFoods(for: date)
        
        let totalCalories = foodsForDate.reduce(0) { $0 + $1.actualCalories }
        let totalProtein = foodsForDate.reduce(0) { $0 + $1.actualProtein }
        let totalFat = foodsForDate.reduce(0) { $0 + $1.actualFat }
        let totalCarbs = foodsForDate.reduce(0) { $0 + $1.actualCarbs }
        
        return DailySummary(
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            totalFat: totalFat,
            totalCarbs: totalCarbs,
            date: date,
            foodCount: foodsForDate.count
        )
    }
    
    // 舊方法，保留但內部呼叫新方法
    func getTodayFoods() -> [Food] {
        return getFoods(for: Date())
    }
    
    func getTodaySummary() -> DailySummary {
        return getSummary(for: Date())
    }
    
    // 儲存營養目標
    func saveNutritionGoals(_ nutritionGoals: NutritionGoals) {
        do {
            // 先刪除舊的目標設定
            try db?.run(goals.delete())
            
            // 插入新的目標設定
            let insert = goals.insert(
                self.dailyCalories <- nutritionGoals.dailyCalories,
                self.dailyProtein <- nutritionGoals.dailyProtein,
                self.dailyFat <- nutritionGoals.dailyFat,
                self.createdAt <- Date()
            )
            try db?.run(insert)
            print("營養目標儲存成功")
        } catch {
            print("儲存營養目標失敗: \(error)")
        }
    }
    
    // 讀取營養目標
    func getNutritionGoals() -> NutritionGoals {
        do {
            if let goal = try db?.pluck(goals.order(createdAt.desc)) {
                return NutritionGoals(
                    dailyCalories: goal[dailyCalories],
                    dailyProtein: goal[dailyProtein],
                    dailyFat: goal[dailyFat]
                )
            }
        } catch {
            print("讀取營養目標失敗: \(error)")
        }
        return NutritionGoals.defaultGoals
    }
    
    // 取得目標進度 (可傳入特定日期的總結)
    func getGoalProgress(for summary: DailySummary) -> GoalProgress {
        let goals = getNutritionGoals()
        return GoalProgress(summary: summary, goals: goals)
    }
    
    // 取得今日目標進度 (舊版相容)
    func getGoalProgress() -> GoalProgress {
        let summary = getTodaySummary()
        return getGoalProgress(for: summary)
    }
    
    // 儲存使用者個人資料
    func saveUserProfile(_ profile: UserProfile) {
        do {
            // 先刪除舊的個人資料
            try db?.run(userProfiles.delete())
            
            // 插入新的個人資料
            let insert = userProfiles.insert(
                self.age <- profile.age,
                self.gender <- profile.gender.rawValue,
                self.weight <- profile.weight,
                self.bodyFatPercentage <- profile.bodyFatPercentage,
                self.height <- profile.height,
                self.fitnessGoal <- profile.fitnessGoal.rawValue,
                self.profileCreatedAt <- Date()
            )
            try db?.run(insert)
            print("使用者個人資料儲存成功")
        } catch {
            print("儲存使用者個人資料失敗: \(error)")
        }
    }
    
    // 讀取使用者個人資料
    func getUserProfile() -> UserProfile {
        do {
            if let profile = try db?.pluck(userProfiles.order(profileCreatedAt.desc)) {
                return UserProfile(
                    age: profile[age],
                    gender: Gender(rawValue: profile[gender]) ?? .male,
                    weight: profile[weight],
                    bodyFatPercentage: profile[bodyFatPercentage],
                    height: profile[height],
                    fitnessGoal: FitnessGoal(rawValue: profile[fitnessGoal]) ?? .buildMuscle
                )
            }
        } catch {
            print("讀取使用者個人資料失敗: \(error)")
        }
        return UserProfile.defaultProfile
    }
    
    // 更新食物份數
    func updateFoodPortions(id: Int64, portions: Double) {
        do {
            let food = foods.filter(self.id == id)
            try db?.run(food.update(self.portions <- portions))
            print("更新食物份數成功: ID \(id), 份數: \(portions)")
        } catch {
            print("更新食物份數失敗: \(error)")
        }
    }

    // 更新食物名稱
    func updateFoodName(id: Int64, newName: String) {
        do {
            let food = foods.filter(self.id == id)
            try db?.run(food.update(self.name <- newName))
            print("更新食物名稱成功: ID \(id), 新名稱: \(newName)")
        } catch {
            print("更新食物名稱失敗: \(error)")
        }
    }

    func updateFoodShortName(id: Int64, newShortName: String) {
        do {
            let food = foods.filter(self.id == id)
            try db?.run(food.update(self.shortName <- newShortName))
            print("更新食物簡稱成功: ID \(id), 新簡稱: \(newShortName)")
        } catch {
            print("更新食物簡稱失敗: \(error)")
        }
    }
    
    // 取得建議營養目標
    func getRecommendedGoals() -> NutritionGoals {
        let profile = getUserProfile()
        return NutritionGoals.recommendedGoals(for: profile)
    }
    
    // 根據名稱模糊搜尋食物，回傳不重複的最新項目
    func searchFood(byName query: String) -> [Food] {
        var result: [Food] = []
        guard !query.isEmpty, let db = db else { return result }

        let sql = """
            SELECT id, name, shortName, calories, protein, fat, carbs, date, portions FROM foods
            WHERE id IN (
                SELECT MAX(id) FROM foods GROUP BY name
            )
            AND name LIKE ?
            LIMIT 5
        """

        do {
            let statement = try db.prepare(sql, "%\(query)%")
            for row in statement {
                // 使用安全的 as? 轉型，並提供預設值，避免閃退
                let foodId = row[0] as? Int64 ?? 0
                let foodName = row[1] as? String ?? ""
                let foodShortName = row[2] as? String ?? ""
                let foodCalories = row[3] as? Double ?? 0.0
                let foodProtein = row[4] as? Double ?? 0.0
                let foodFat = row[5] as? Double ?? 0.0
                let foodCarbs = row[6] as? Double ?? 0.0
                
                // 對日期做更安全的處理
                let timeInterval = row[7] as? Double ?? Date().timeIntervalSince1970
                let foodDate = Date(timeIntervalSince1970: timeInterval)
                
                let foodPortions = row[8] as? Double ?? 1.0

                let item = Food(
                    id: foodId,
                    name: foodName,
                    shortName: foodShortName,
                    calories: foodCalories,
                    protein: foodProtein,
                    fat: foodFat,
                    carbs: foodCarbs,
                    date: foodDate,
                    portions: foodPortions
                )
                result.append(item)
            }
        } catch {
            print("原生 SQL 搜尋食物失敗: \(error)")
        }
        return result
    }
    
    // 取得最常出現的食物
    func getTopFrequentFoods(limit: Int) -> [Food] {
        var result: [Food] = []
        guard let db = db else { return result }
        
        let sql = """
            SELECT f.id, f.name, f.shortName, f.calories, f.protein, f.fat, f.carbs, f.date, f.portions
            FROM foods f
            INNER JOIN (
                SELECT name, MAX(id) as max_id
                FROM foods
                GROUP BY name
            ) AS latest_foods
            ON f.id = latest_foods.max_id
            GROUP BY f.name
            ORDER BY COUNT(f.name) DESC
            LIMIT ?
        """
        
        do {
            let statement = try db.prepare(sql, limit)
            for row in statement {
                let foodId = row[0] as? Int64 ?? 0
                let foodName = row[1] as? String ?? ""
                let foodShortName = row[2] as? String ?? ""
                let foodCalories = row[3] as? Double ?? 0.0
                let foodProtein = row[4] as? Double ?? 0.0
                let foodFat = row[5] as? Double ?? 0.0
                let foodCarbs = row[6] as? Double ?? 0.0
                let timeInterval = row[7] as? Double ?? Date().timeIntervalSince1970
                let foodDate = Date(timeIntervalSince1970: timeInterval)
                let foodPortions = row[8] as? Double ?? 1.0
                
                let item = Food(
                    id: foodId,
                    name: foodName,
                    shortName: foodShortName,
                    calories: foodCalories,
                    protein: foodProtein,
                    fat: foodFat,
                    carbs: foodCarbs,
                    date: foodDate,
                    portions: foodPortions
                )
                result.append(item)
            }
        } catch {
            print("查詢最常出現食物失敗: \(error)")
        }
        return result
    }
}


