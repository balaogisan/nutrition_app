
import SwiftUI

struct FoodEditView: View {
    @Environment(\.dismiss) var dismiss
    @State var food: Food
    
    @State private var showingDeleteConfirm = false

    var onSave: (Food) -> Void
    var onDelete: (Int64) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(String(localized: "food_info_section_header"))) {
                    TextField(String(localized: "food_name_placeholder"), text: $food.name)
                    HStack {
                        TextField(String(localized: "calories_placeholder"), value: $food.calories, format: .number)
                            .keyboardType(.decimalPad)
                        Text(String(localized: "calories_title"))
                    }
                    HStack {
                        TextField(String(localized: "protein_placeholder"), value: $food.protein, format: .number)
                            .keyboardType(.decimalPad)
                        Text(String(localized: "protein_title"))
                    }
                    HStack {
                        TextField(String(localized: "fat_placeholder"), value: $food.fat, format: .number)
                            .keyboardType(.decimalPad)
                        Text(String(localized: "fat_title"))
                    }
                    HStack {
                        TextField(String(localized: "carbs_placeholder"), value: $food.carbs, format: .number)
                            .keyboardType(.decimalPad)
                        Text(String(localized: "carbs_title"))
                    }
                }
                
                if let results = food.results, !results.isEmpty {
                    Section {
                        ForEach(results) { result in
                            VStack(alignment: .leading) {
                                Text(result.source)
                                    .font(.headline)
                                Text("熱量: \(result.calories, specifier: "%.1f") 大卡, 蛋白質: \(result.protein, specifier: "%.1f") 克, 脂肪: \(result.fat, specifier: "%.1f") 克, 碳水: \(result.carbs, specifier: "%.1f") 克")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section(header: Text(String(localized: "record_info_section_header"))) {
                    HStack {
                        Text(String(localized: "creation_date_label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(food.date.formatted(date: .long, time: .standard))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Text(String(localized: "delete_food_button_title"))
                    }
                }
            }
            .navigationTitle(String(localized: "edit_food_navigation_title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "cancel_button")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "save_button")) {
                        onSave(food)
                        dismiss()
                    }
                }
            }
            .alert(String(localized: "delete_food_confirm_title"), isPresented: $showingDeleteConfirm) {
                Button(String(localized: "delete_button"), role: .destructive) {
                    onDelete(food.id)
                    dismiss()
                }
                Button(String(localized: "cancel_button"), role: .cancel) { }
            } message: {
                Text(String(localized: "delete_food_confirm_message"))
            }
        }
    }
}
