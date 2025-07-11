import SwiftUI

struct QuickSelectFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var topFrequentFoods: [Food] = []
    @State private var selectedFoods: [Food] = []
    
    var onDone: ([Food]) -> Void
    
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
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(topFrequentFoods.indices, id: \.self) { index in
                        let food = topFrequentFoods[index]
                        let color = tagColors[index % tagColors.count]
                        let isSelected = selectedFoods.contains(where: { $0.id == food.id })
                        
                        Button(action: {
                            if isSelected {
                                selectedFoods.removeAll(where: { $0.id == food.id })
                            } else {
                                selectedFoods.append(food)
                            }
                        }) {
                            Text(String(food.name.prefix(3)))
                                .font(.headline)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 5)
                                .frame(maxWidth: .infinity)
                                .background(isSelected ? color.opacity(0.5) : color.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(color)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(color, lineWidth: isSelected ? 2 : 0)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "quick_select_food_navigation_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "cancel_button")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "done_button")) {
                        onDone(selectedFoods)
                    }
                }
            }
            .onAppear {
                topFrequentFoods = DatabaseManager.shared.getTopFrequentFoods(limit: 20)
            }
        }
    }
}

#Preview {
    QuickSelectFoodView(onDone: { foods in
        print("Selected \(foods.count) foods")
    })
}