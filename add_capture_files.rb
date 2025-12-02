#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'SmartExpense.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find or create the Capture group
smart_expense_group = project.main_group['SmartExpense']
features_group = smart_expense_group['Features'] || smart_expense_group.new_group('Features')
capture_group = features_group['Capture'] || features_group.new_group('Capture')

# Create subgroups
models_group = capture_group['Models'] || capture_group.new_group('Models')
views_group = capture_group['Views'] || capture_group.new_group('Views')
viewmodels_group = capture_group['ViewModels'] || capture_group.new_group('ViewModels')
services_group = capture_group['Services'] || capture_group.new_group('Services')

# Add files to Models group
models_files = [
  'SmartExpense/Features/Capture/Models/CaptureOption.swift',
  'SmartExpense/Features/Capture/Models/ExtractedReceiptData.swift'
]

models_files.each do |file_path|
  file_ref = models_group.new_file(file_path)
  target.add_file_references([file_ref])
end

# Add files to Views group
views_files = [
  'SmartExpense/Features/Capture/Views/CaptureCoordinatorView.swift',
  'SmartExpense/Features/Capture/Views/CaptureMenuView.swift',
  'SmartExpense/Features/Capture/Views/ImagePickerView.swift',
  'SmartExpense/Features/Capture/Views/ImagePreviewView.swift',
  'SmartExpense/Features/Capture/Views/LineItemRowView.swift',
  'SmartExpense/Features/Capture/Views/ProcessingView.swift',
  'SmartExpense/Features/Capture/Views/ReceiptEditView.swift',
  'SmartExpense/Features/Capture/Views/VoiceExpenseReviewView.swift',
  'SmartExpense/Features/Capture/Views/VoiceRecordingView.swift'
]

views_files.each do |file_path|
  file_ref = views_group.new_file(file_path)
  target.add_file_references([file_ref])
end

# Add files to ViewModels group
viewmodels_files = [
  'SmartExpense/Features/Capture/ViewModels/ReceiptEditViewModel.swift'
]

viewmodels_files.each do |file_path|
  file_ref = viewmodels_group.new_file(file_path)
  target.add_file_references([file_ref])
end

# Add files to Services group
services_files = [
  'SmartExpense/Features/Capture/Services/FileStorageService.swift',
  'SmartExpense/Features/Capture/Services/PermissionsManager.swift',
  'SmartExpense/Features/Capture/Services/ReceiptOCRService.swift',
  'SmartExpense/Features/Capture/Services/SpeechRecognitionService.swift',
  'SmartExpense/Features/Capture/Services/VoiceExpenseParser.swift'
]

services_files.each do |file_path|
  file_ref = services_group.new_file(file_path)
  target.add_file_references([file_ref])
end

project.save

puts "Successfully added Capture feature files to Xcode project"
