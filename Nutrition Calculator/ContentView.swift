//
//  ContentView.swift
//  Nutrition Calculator
//
//  Created by SHAOYUN HSU on 2025/7/5.
//

import SwiftUI

// 承載單日所有數據的結構
struct DailyData: Identifiable {
    let id = UUID()
    var date: Date
    var foods: [Food]
    var summary: DailySummary
    var goalProgress: GoalProgress
    var summaryPageIndex: Int = 0
}

struct ContentView: View {
    @State private var dailyData: [DailyData] = []
    @State private var currentPageIndex: Int = 6 // 預設顯示今日 (第7天)
    @State private var showAdd = false
    @State private var showSettings = false
    @State private var showQuickSelect = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if dailyData.isEmpty {
                    ProgressView(String(localized: "loading_message"))
                } else {
                    TabView(selection: $currentPageIndex) {
                        ForEach(dailyData.indices, id: \.self) { index in
                            dailyDataView(for: index)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus")
                        Text(String(localized: "add_food_button"))
                    }
                }
            }
            .onAppear(perform: refreshData)
            .sheet(isPresented: $showAdd) {
                FoodAddView(onSave: refreshData)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showQuickSelect) {
                if let index = dailyData.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
                    QuickSelectFoodView(onDone: { selectedFoods in
                        for food in selectedFoods {
                            DatabaseManager.shared.addFood(
                                name: food.name,
                                calories: food.calories,
                                protein: food.protein,
                                fat: food.fat,
                                carbs: food.carbs
                            )
                        }
                        refreshData(forDayIndex: index)
                        showQuickSelect = false // Dismiss the sheet
                    })
                }
            }
        }
    }
    
    // 根據當前頁面動態生成導覽列標題
    private var navigationTitle: String {
        guard !dailyData.isEmpty else { return String(localized: "loading_message") }
        let date = dailyData[currentPageIndex].date
        if Calendar.current.isDateInToday(date) {
            return String(localized: "today_title")
        } else {
            return dateFormatter.string(from: date)
        }
    }

    // 單日的完整視圖
    @ViewBuilder
    private func dailyDataView(for index: Int) -> some View {
        let data = dailyData[index]
        
        VStack(spacing: 20) {
            // 目標進度視圖
            goalProgressPage(for: data)
                .frame(height: 140)
                .padding(.horizontal)
            
            // 食物列表標題
            listHeader(for: data.date)
            
            // 根據是否為今日，顯示不同的食物列表或快速選取頁面
            if Calendar.current.isDateInToday(data.date) {
                // 今日食物清單頁
                List {
                    ForEach(data.foods) { food in
                        foodRow(food: food)
                    }
                    .onDelete { offsets in
                        deleteFood(at: offsets, forDayIndex: index)
                    }
                }
                .listStyle(PlainListStyle())
            } else {
                // 歷史食物清單頁
                List {
                    ForEach(data.foods) { food in
                        foodRow(food: food)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // 移到 List 上方的標題
    private func listHeader(for date: Date) -> some View {
        HStack {
            Text(String(localized: "food_list_title"))
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            Spacer()
            
            // 只有今日才顯示快速選取按鈕
            if Calendar.current.isDateInToday(date) {
                Button(action: {
                    // 切換到快速選取食物頁面
                    showQuickSelect = true
                }) {
                    Text(String(localized: "quick_select_button"))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.blue.opacity(0.1)))
                }
                .padding(.trailing)
            }
        }
        .padding(.top, 10)
    }

    // 目標進度頁
    private func goalProgressPage(for data: DailyData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "goal_progress_title"))
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text(String(format: NSLocalizedString("total_foods_count_message", comment: ""), data.summary.foodCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            VStack(spacing: 6) {
                let goals = DatabaseManager.shared.getNutritionGoals()
                goalProgressRow(title: String(localized: "calories_title"), current: data.goalProgress.caloriesProgress, target: goals.dailyCalories, unit: "kcal", percentage: data.goalProgress.caloriesPercentage, color: .red)
                goalProgressRow(title: String(localized: "protein_title"), current: data.goalProgress.proteinProgress, target: goals.dailyProtein, unit: "g", percentage: data.goalProgress.proteinPercentage, color: .blue)
                goalProgressRow(title: String(localized: "fat_title"), current: data.goalProgress.fatProgress, target: goals.dailyFat, unit: "g", percentage: data.goalProgress.fatPercentage, color: .orange)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }

    private func goalProgressRow(title: String, current: Double, target: Double, unit: String, percentage: Double, color: Color) -> some View {
        HStack {
            Text("\(title): \(current, specifier: "%.1f") / \(target, specifier: "%.1f") \(unit)")
                .font(.subheadline).foregroundColor(color)
            Spacer()
            Text("\(percentage, specifier: "%.1f")%")
                .font(.system(.caption, design: .rounded).bold())
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.15))
                .clipShape(Capsule())
        }
    }

    private func foodRow(food: Food) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(food.name).font(.headline)
                    Spacer()
                    // 只有今天的食物可以調整份量
                    if Calendar.current.isDateInToday(food.date) {
                        HStack(spacing: 8) {
                            Button(action: { adjustPortions(for: food, change: -1.0) }) {
                                Image(systemName: "minus.circle").foregroundColor(.red).font(.title3)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Text(String(format: NSLocalizedString("portions_unit", comment: ""), food.portions))
                                .font(.subheadline).foregroundColor(.blue)
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1)).cornerRadius(8)
                            
                            Button(action: { adjustPortions(for: food, change: 1.0) }) {
                                Image(systemName: "plus.circle").foregroundColor(.green).font(.title3)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                Text(String(format: NSLocalizedString("calories_protein_info", comment: ""), food.actualCalories, food.actualProtein))
                    .font(.subheadline)
                Text(String(format: NSLocalizedString("fat_carbs_info", comment: ""), food.actualFat, food.actualCarbs))
                    .font(.caption).foregroundColor(.secondary)
                Text(String(format: NSLocalizedString("date_info", comment: ""), food.date.formatted(.dateTime.year().month().day().hour().minute()) as CVarArg))
                    .font(.caption2).foregroundColor(.gray)
            }
        }
    }

    // 刪除指定日期的食物
    func deleteFood(at offsets: IndexSet, forDayIndex index: Int) {
        let foodsToDelete = offsets.map { dailyData[index].foods[$0] }
        for food in foodsToDelete {
            DatabaseManager.shared.deleteFood(id: food.id)
        }
        refreshData(forDayIndex: index)
    }

    // 刷新數據
    func refreshData() {
        var newDailyData: [DailyData] = []
        let calendar = Calendar.current
        let today = Date()
        
        for i in (0...6).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            
            let foods = DatabaseManager.shared.getFoods(for: date)
            let summary = DatabaseManager.shared.getSummary(for: date)
            let goalProgress = DatabaseManager.shared.getGoalProgress(for: summary)
            
            newDailyData.append(DailyData(date: date, foods: foods, summary: summary, goalProgress: goalProgress))
        }
        
        self.dailyData = newDailyData
        // 確保刷新後頁面停留在今日
        if currentPageIndex != 6 {
            currentPageIndex = 6
        }
    }
    
    // 只刷新特定日期的數據
    func refreshData(forDayIndex index: Int) {
        guard dailyData.indices.contains(index) else { return }
        
        let date = dailyData[index].date
        let foods = DatabaseManager.shared.getFoods(for: date)
        let summary = DatabaseManager.shared.getSummary(for: date)
        let goalProgress = DatabaseManager.shared.getGoalProgress(for: summary)
        
        dailyData[index].foods = foods
        dailyData[index].summary = summary
        dailyData[index].goalProgress = goalProgress
    }

    // 調整份量 (只對今日有效)
    func adjustPortions(for food: Food, change: Double) {
        let newPortions = max(1.0, food.portions + change)
        DatabaseManager.shared.updateFoodPortions(id: food.id, portions: newPortions)
        
        // 只刷新今日的數據
        refreshData(forDayIndex: 6)
    }
}
