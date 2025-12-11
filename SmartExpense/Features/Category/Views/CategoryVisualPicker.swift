import SwiftUI

struct CategoryVisualPicker: View {
    @ObservedObject var category: ExpenseCategory
    
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
        "bolt.fill"
    ]
    
    enum IconType: String, CaseIterable {
        case emoji = "Emoji"
        case sfSymbol = "SF Symbol"
    }
    
    @State private var selectedIconType: IconType = .emoji
    @State private var emojiText: String = ""
    
    private let columns = [
        GridItem(.adaptive(minimum: 44))
    ]
    
    var body: some View {
        VStack(spacing: 24) {
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
            .padding(.top, 20)
            
            // MARK: - Icon Type Picker
            Picker("Icon Type", selection: $selectedIconType) {
                ForEach(IconType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedIconType) { newValue in
                // Update model when switching types if needed, 
                // or just wait for user to select an icon.
                // For better UX, we might want to preserve the previous value or default.
                if newValue == .sfSymbol {
                    category.iconType = "sfSymbol"
                    // If current icon is not an SF symbol, maybe default to first one?
                    if !sfSymbols.contains(category.iconValue ?? "") {
                        category.iconValue = sfSymbols.first
                    }
                } else {
                    category.iconType = "emoji"
                    // If current icon is a long SF symbol string, maybe default to a smiley?
                    // But we can let the emoji input handle it.
                    if (category.iconValue?.count ?? 0) > 2 {
                         category.iconValue = "😀"
                         emojiText = "😀"
                    } else {
                        emojiText = category.iconValue ?? ""
                    }
                }
            }

            // MARK: - Icon Selection
            if selectedIconType == .emoji {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emoji")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter Emoji", text: $emojiText)
                        .font(.system(size: 50))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .onChange(of: emojiText) { newValue in
                            // Limit to 1 character approximately (emojis can be multiple scalars)
                            if newValue.count > 0 {
                                let lastChar = String(newValue.suffix(1))
                                if emojiText != lastChar {
                                    emojiText = lastChar
                                }
                                category.iconValue = emojiText
                            }
                        }
                        .onAppear {
                            emojiText = category.iconValue ?? ""
                        }
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(sfSymbols, id: \.self) { symbol in
                            ZStack {
                                Circle()
                                    .fill(category.iconValue == symbol ? Color.blue.opacity(0.2) : Color.clear)
                                
                                Image(systemName: symbol)
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 44, height: 44)
                            .onTapGesture {
                                category.iconValue = symbol
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 120) // Limit height
            }
            
            Divider()
            
            // MARK: - Color Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(colors, id: \.self) { hex in
                        ZStack {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                            
                            if category.colorHex?.uppercased() == hex.uppercased() {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .shadow(radius: 1)
                            }
                        }
                        .frame(width: 44, height: 44) // Touch target
                        .onTapGesture {
                            category.colorHex = hex
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Initialize local state from model
            if category.iconType == "sfSymbol" {
                selectedIconType = .sfSymbol
            } else {
                selectedIconType = .emoji
                emojiText = category.iconValue ?? ""
            }
        }
    }
}
