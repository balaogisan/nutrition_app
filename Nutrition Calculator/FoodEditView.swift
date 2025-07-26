
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
