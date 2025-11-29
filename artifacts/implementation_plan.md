# Implementation Plan - SmartExpense

## User Review Required

> [!NOTE]
> This plan covers the Core Data Model implementation. We will define the entities required for the MVP.

## Proposed Changes

### Data Model
#### [MODIFY] [SmartExpense.xcdatamodeld](file:///Users/henry/Project/SmartExpense/SmartExpense/SmartExpense.xcdatamodeld)
- Define `Receipt` entity:
    - `id`: UUID
    - `merchantName`: String?
    - `date`: Date
    - `totalAmount`: Double
    - `imagePath`: String?
    - `isVoiceInput`: Boolean
    - `createdAt`: Date
- Define `ReceiptItem` entity:
    - `id`: UUID
    - `name`: String
    - `price`: Double
    - `quantity`: Int16
    - `receipt`: Relationship to `Receipt`
- Define `VoiceExpense` entity (optional, or merge into Receipt with flag):
    - For MVP, we will use `Receipt` with `isVoiceInput = true` as per PRD suggestion to keep it simple, but we can separate if preferred. *Decision: Use single Receipt entity for v1.*

### Persistence
#### [MODIFY] [Persistence.swift](file:///Users/henry/Project/SmartExpense/SmartExpense/Persistence.swift)
- Ensure `PersistenceController` is set up correctly for the updated model.

## Verification Plan

### Automated Tests
- Create a unit test to verify:
    - Saving a `Receipt`.
    - Fetching `Receipts`.
    - Deleting a `Receipt`.

### Manual Verification
- Build the app to ensure no Core Data model compilation errors.


