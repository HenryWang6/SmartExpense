# Adding Capture Feature Files to Xcode

Since the automated script requires additional dependencies, please follow these manual steps to add the Capture feature files to your Xcode project:

## Steps to Add Files

1. **Open Xcode project**
   - Open `SmartExpense.xcodeproj` in Xcode

2. **Create Capture group structure**
   - In the Project Navigator, right-click on `SmartExpense/Features`
   - Select "New Group" and name it `Capture`
   - Inside `Capture`, create four subgroups:
     - `Models`
     - `Views`
     - `ViewModels`
     - `Services`

3. **Add files to each group**
   
   **Models group:**
   - Right-click on `Models` → "Add Files to SmartExpense..."
   - Navigate to `SmartExpense/Features/Capture/Models/`
   - Select both `.swift` files
   - Make sure "Copy items if needed" is UNCHECKED
   - Make sure "SmartExpense" target is CHECKED
   - Click "Add"

   **Views group:**
   - Right-click on `Views` → "Add Files to SmartExpense..."
   - Navigate to `SmartExpense/Features/Capture/Views/`
   - Select all 9 `.swift` files
   - Make sure "Copy items if needed" is UNCHECKED
   - Make sure "SmartExpense" target is CHECKED
   - Click "Add"

   **ViewModels group:**
   - Right-click on `ViewModels` → "Add Files to SmartExpense..."
   - Navigate to `SmartExpense/Features/Capture/ViewModels/`
   - Select the `.swift` file
   - Make sure "Copy items if needed" is UNCHECKED
   - Make sure "SmartExpense" target is CHECKED
   - Click "Add"

   **Services group:**
   - Right-click on `Services` → "Add Files to SmartExpense..."
   - Navigate to `SmartExpense/Features/Capture/Services/`
   - Select all 5 `.swift` files
   - Make sure "Copy items if needed" is UNCHECKED
   - Make sure "SmartExpense" target is CHECKED
   - Click "Add"

4. **Update Info.plist for permissions**
   - In Project Navigator, select `SmartExpense/Info.plist` (or open it from project settings)
   - Add the following permission keys with descriptions:
     - `NSCameraUsageDescription`: "Camera access is required to scan receipts"
     - `NSPhotoLibraryUsageDescription`: "Photo library access is required to select receipt images"
     - `NSMicrophoneUsageDescription`: "Microphone access is required for voice expense input"
     - `NSSpeechRecognitionUsageDescription`: "Speech recognition is required to transcribe voice expenses"

5. **Build the project**
   - Press Cmd+B to build
   - Fix any compilation errors if they appear

## Alternative: Use Xcode's "Add Files" Feature

You can also add all files at once:
1. Right-click on `SmartExpense/Features` in Project Navigator
2. Select "Add Files to SmartExpense..."
3. Navigate to and select the entire `Capture` folder
4. Make sure "Create groups" is selected (NOT "Create folder references")
5. Make sure "Copy items if needed" is UNCHECKED
6. Make sure "SmartExpense" target is CHECKED
7. Click "Add"

This will preserve the folder structure automatically.
