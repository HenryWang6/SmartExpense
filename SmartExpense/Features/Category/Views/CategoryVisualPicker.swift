import SwiftUI

struct CategoryVisualPicker: View {
    @ObservedObject var category: ExpenseCategory
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Configuration
    private let colors: [String] = [
        "#2ECC71", // Emerald
        "#27AE60", // Money Green
        "#1ABC9C", // Teal
        "#3498DB", // Sky Blue
        "#34495E", // Navy
        "#5B5EA6", // Indigo
        "#9B59B6", // Purple
        "#E0BBE4", // Lavender
        "#E74C3C", // Coral Red
        "#D35400", // Pumpkin
        "#F39C12", // Tangerine
        "#F1C40F", // Sunflower
        "#6D4C41", // Coffee
        "#95A5A6", // Slate
        "#2C3E50", // Carbon
        "#C0392B"  // Berry
    ]
    
    private let sfSymbols: [String] = [
        "house.fill",
        "car.fill",
        "cart.fill",
        "creditcard.fill",
        "gamecontroller.fill",
        "pill.fill",
        "cross.fill",
        "leaf.fill",
        "bolt.fill",
        "bus.fill",
        "airplane",
        "graduationcap.fill",
        "gift.fill",
        "cart.badge.plus",
        "banknote.fill",
        "cup.and.saucer.fill",
        "fork.knife",
        "tshirt.fill"
    ]
    
    // Common emojis for expenses
    private let emojis: [String] = [
        "🍔", "🛒", "⛽", "🏠", "💡", "🎮", 
        "🎬", "💊", "👟", "✈️", "🚍", "🎓", 
        "👶", "🐾", "💇", "🎁", "💰", "📱", 
        "💻", "📚", "🍺", "☕", "🍕", "🔧"
    ]
    
    enum IconType: String, CaseIterable {
        case emoji = "Emoji"
        case sfSymbol = "SF Symbol"
    }
    
    @State private var selectedIconType: IconType = .emoji
    
    private let columns = [
        GridItem(.adaptive(minimum: 44))
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Handle Indicator (Optional visual cue)
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            // MARK: - Header / Preview
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex ?? "#999999"))
                    .frame(width: 80, height: 80)
                
                if category.iconType == "sfSymbol" {
                    Image(systemName: category.iconValue ?? "questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                } else {
                    Text(category.iconValue ?? "?")
                        .font(.system(size: 40))
                }
            }
            // Add a subtle bounce animation when icon changes?
            .animation(.interactiveSpring(), value: category.iconValue)
            .animation(.interactiveSpring(), value: category.colorHex)
            
            // MARK: - Icon Type Picker
            Picker("Icon Type", selection: $selectedIconType) {
                ForEach(IconType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedIconType) { newValue in
                handleTypeChange(newValue)
            }

            // MARK: - Icon Selection
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Icons Grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        if selectedIconType == .emoji {
                            ForEach(emojis, id: \.self) { emoji in
                                IconCell(
                                    content: Text(emoji).font(.largeTitle),
                                    isSelected: category.iconValue == emoji
                                ) {
                                    category.iconValue = emoji
                                    category.iconType = "emoji"
                                }
                            }
                        } else {
                            ForEach(sfSymbols, id: \.self) { symbol in
                                IconCell(
                                    content: Image(systemName: symbol).font(.title2).foregroundColor(.primary),
                                    isSelected: category.iconValue == symbol
                                ) {
                                    category.iconValue = symbol
                                    category.iconType = "sfSymbol"
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // MARK: - Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(colors, id: \.self) { hex in
                                ColorCell(
                                    hex: hex,
                                    isSelected: category.colorHex?.uppercased() == hex.uppercased()
                                ) {
                                    category.colorHex = hex
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .padding()
        .onAppear {
            initializeState()
        }
    }
    
    // MARK: - Helpers
    
    private func initializeState() {
        if category.iconType == "sfSymbol" {
            selectedIconType = .sfSymbol
        } else {
            selectedIconType = .emoji
        }
    }
    
    private func handleTypeChange(_ newValue: IconType) {
        if newValue == .sfSymbol {
            // If switching to SF Symbol and current is emoji, default to first symbol if needed
            category.iconType = "sfSymbol"
            if !sfSymbols.contains(category.iconValue ?? "") {
                category.iconValue = sfSymbols.first
            }
        } else {
            // Switching to Emoji
            category.iconType = "emoji"
            if !emojis.contains(category.iconValue ?? "") {
                category.iconValue = emojis.first
            }
        }
    }
}

// MARK: - Subviews

struct IconCell<Content: View>: View {
    let content: Content
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.15) : Color.clear)
            
            content
        }
        .frame(width: 50, height: 50)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct ColorCell: View {
    let hex: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 40, height: 40)
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .shadow(radius: 1)
            }
        }
        .frame(width: 44, height: 44)
        .onTapGesture(perform: action)
    }
}
