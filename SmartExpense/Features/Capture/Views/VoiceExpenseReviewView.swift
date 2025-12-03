//
//  VoiceExpenseReviewView.swift
//  SmartExpense
//
//  Created by Henry Wang on 2025-11-29.
//

import SwiftUI
import CoreData

struct VoiceExpenseReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let transcription: String
    
    @State private var merchantName: String = ""
    @State private var totalAmount: String = ""
    @State private var date: Date = Date()
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Transcription card
                        transcriptionCard
                        
                        // Parsed data card
                        parsedDataCard
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Review Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveExpense) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                parseTranscription()
            }
        }
    }
    
    private var transcriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
                
                Text("What you said")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Text(transcription)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray6))
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    private var parsedDataCard: some View {
        VStack(spacing: 16) {
            // Merchant
            VStack(alignment: .leading, spacing: 8) {
                Text("Merchant")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                TextField("Merchant name", text: $merchantName)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
            }
            
            HStack(spacing: 12) {
                // Amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    HStack {
                        Text("$")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $totalAmount)
                            .font(.system(size: 18, weight: .bold))
                            .keyboardType(.decimalPad)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                }
                .frame(maxWidth: .infinity)
                
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    DatePicker("", selection: $date, displayedComponents: [.date])
                        .labelsHidden()
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        )
    }
    
    private func parseTranscription() {
        let parsed = VoiceExpenseParser.parse(transcription)
        
        if let amount = parsed.amount {
            totalAmount = String(format: "%.2f", amount)
        }
        
        if let merchant = parsed.merchant {
            merchantName = merchant
        }
    }
    
    private func saveExpense() {
        // Validate
        guard !merchantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Merchant name is required"
            showError = true
            return
        }
        
        guard let amount = Double(totalAmount), amount > 0 else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }
        
        isSaving = true
        
        // Create Receipt entity
        let receipt = Receipt(context: viewContext)
        receipt.id = UUID()
        receipt.merchantName = merchantName.trimmingCharacters(in: .whitespacesAndNewlines)
        receipt.date = date
        receipt.totalAmount = amount
        receipt.isVoiceInput = true
        receipt.captureMethod = "voice"
        receipt.createdAt = Date()
        receipt.updatedAt = Date()
        
        // Save context
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save expense: \(error.localizedDescription)"
            showError = true
            isSaving = false
        }
    }
}

#Preview {
    VoiceExpenseReviewView(transcription: "Spent $45 at Starbucks for coffee and snacks")
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
