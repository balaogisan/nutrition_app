//
//  QuickSelectFoodView.swift
//  Nutrition Calculator
//
//  Created by SHAOYUN HSU on 2025/7/6.
//

import SwiftUI

struct QuickSelectFoodView: View {
    @State private var topFrequentFoods: [Food] = []
    var onFoodSelected: (Food) -> Void
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // 定義一組顏色
    let tagColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .indigo, .purple,
        .pink, .mint, .teal, .cyan, .brown, .gray
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(topFrequentFoods.indices, id: \.self) { index in
                    let food = topFrequentFoods[index]
                    let color = tagColors[index % tagColors.count] // 循環使用顏色
                    
                    Button(action: {
                        onFoodSelected(food)
                    }) {
                        Text(String(food.name.prefix(3)))
                            .font(.headline)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 5)
                            .frame(maxWidth: .infinity)
                            .background(color.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(color)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            topFrequentFoods = DatabaseManager.shared.getTopFrequentFoods(limit: 20)
        }
    }
}

#Preview {
    QuickSelectFoodView(onFoodSelected: { food in
        print("Selected: \(food.name)")
    })
}
