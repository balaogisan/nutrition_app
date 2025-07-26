import SwiftUI

struct QuickSelectFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var topFrequentFoods: [Food] = []
    @State private var selectedFoods: [Food] = []
    
    // For editing food names
    @State private var isEditingName = false
    @State private var editingFood: Food? = nil
    @State private var newFoodShortName: String = ""

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
                        
                        let buttonContent = Text(food.shortName)
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

                        buttonContent
                            .onTapGesture {
                                if isSelected {
                                    selectedFoods.removeAll(where: { $0.id == food.id })
                                } else {
                                    selectedFoods.append(food)
                                }
                            }
                            .onLongPressGesture {
                                editingFood = food
                                newFoodShortName = food.shortName
                                isEditingName = true
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
                refreshTopFoods()
            }
            .alert(String(localized: "edit_food_short_name_alert_title"), isPresented: $isEditingName) {
                TextField(String(localized: "new_food_short_name_placeholder"), text: $newFoodShortName)
                Button(String(localized: "save_button"), action: saveNewFoodShortName)
                Button(String(localized: "cancel_button"), role: .cancel) { }
            } message: {
                Text(String(localized: "edit_food_short_name_alert_message"))
            }
        }
    }

    private func refreshTopFoods() {
        topFrequentFoods = DatabaseManager.shared.getTopFrequentFoods(limit: 32)
    }

    private func saveNewFoodShortName() {
        guard let foodToUpdate = editingFood else { return }
        
        // Validate length: 4 Chinese characters or 8 English letters
        let newShortName = newFoodShortName.trimmingCharacters(in: .whitespacesAndNewlines)
        if newShortName.isEmpty { return }

        let chineseCharCount = newShortName.filter { char in
            char.unicodeScalars.contains { scalar in
                // CJK Unified Ideographs range
                (0x4E00...0x9FFF).contains(scalar.value)
            }
        }.count
        let otherCharCount = newShortName.count - chineseCharCount
        
        if (chineseCharCount * 2 + otherCharCount) > 8 {
            // Optionally, show an error to the user
            print("Error: Short name is too long.")
            return
        }

        DatabaseManager.shared.updateFoodShortName(id: foodToUpdate.id, newShortName: newShortName)
        
        // Refresh the list to show the new name
        refreshTopFoods()
    }
}

#Preview {
    QuickSelectFoodView(onDone: { foods in
        print("Selected \(foods.count) foods")
    })
}