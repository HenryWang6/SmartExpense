# SmartExpense iOS App - Development Guidelines

## Project Documentation

### Documentation Updates
- **ALWAYS** update project documentation when making significant changes to:
  - Architecture decisions (update ARCHITECTURE.md if exists, or create one)
  - API endpoints or data models (update API.md or README.md)
  - Dependencies (update README.md with new packages and their purposes)
  - Features (update FEATURES.md or README.md)
  - Configuration changes (document in appropriate config files)

- When adding new files, classes, or modules:
  - Add inline documentation (Swift doc comments)
  - Update relevant documentation files
  - Consider adding to architecture diagrams or README if significant

- Documentation files to maintain:
  - README.md: Project overview, setup instructions, dependencies
  - ARCHITECTURE.md: System design, patterns used, module structure
  - CHANGELOG.md: Track significant changes and features

## iOS Development Best Practices

### Code Quality & Architecture

1. **Swift Style Guide**
   - Follow Apple's Swift API Design Guidelines
   - Use meaningful variable and function names
   - Prefer `let` over `var` when possible
   - Use guard statements for early returns
   - Avoid force unwrapping; use optional binding or nil coalescing

2. **Architecture Patterns**
   - Use MVVM (Model-View-ViewModel) or VIPER for complex features
   - Keep ViewControllers lightweight; move business logic to ViewModels
   - Use protocols for dependency injection and testability
   - Separate concerns: UI, business logic, and data layers

3. **SwiftUI vs UIKit**
   - Prefer SwiftUI for new features when targeting iOS 14+
   - Document reasons when using UIKit (if required)
   - Maintain consistency within the app

4. **Error Handling**
   - Use Result types for operations that can fail
   - Implement proper error handling with user-friendly messages
   - Log errors appropriately (consider using a logging framework)

5. **Memory Management**
   - Avoid retain cycles; use `weak` or `unowned` for closures
   - Follow ARC best practices
   - Profile memory usage periodically

### Project Structure

```
SmartExpense/
├── App/
│   ├── AppDelegate.swift / App.swift
│   └── SceneDelegate.swift (if UIKit)
├── Features/
│   └── [FeatureName]/
│       ├── Models/
│       ├── Views/
│       ├── ViewModels/
│       ├── Services/
│       └── Components/
├── Core/
│   ├── Networking/
│   ├── Storage/
│   ├── Utilities/
│   └── Extensions/
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.strings
│   └── Fonts/
└── Supporting Files/
    ├── Info.plist
    └── Config/
```

### Dependencies & Package Management

1. **Swift Package Manager (SPM)**
   - Prefer SPM over CocoaPods or Carthage
   - Document all dependencies in README.md with purpose
   - Pin versions for production stability
   - Keep dependencies minimal and well-maintained

2. **Third-Party Libraries**
   - Evaluate necessity before adding
   - Prefer native solutions when possible
   - Document reasons for using external libraries
   - Regular security audits of dependencies

### Testing

1. **Test Coverage**
   - Write unit tests for business logic (ViewModels, Services)
   - Write UI tests for critical user flows
   - Maintain test coverage >70% for core functionality
   - Run tests before committing changes

2. **Testing Strategy**
   - Use XCTest framework
   - Mock dependencies in unit tests
   - Test error cases, not just happy paths
   - Keep tests fast and independent

### Performance & Optimization

1. **Build Performance**
   - Use modular architecture to reduce compile times
   - Profile build times periodically
   - Use build configurations appropriately (Debug vs Release)

2. **Runtime Performance**
   - Optimize image loading and caching
   - Lazy load content when possible
   - Profile app performance using Instruments
   - Monitor memory leaks

3. **Network Optimization**
   - Implement request caching where appropriate
   - Use pagination for large data sets
   - Handle offline scenarios gracefully

### Security & Privacy

1. **Data Protection**
   - Store sensitive data in Keychain, not UserDefaults
   - Use secure network communication (HTTPS only)
   - Implement proper authentication flows
   - Follow OAuth2 best practices if using third-party auth

2. **Privacy**
   - Request permissions only when needed
   - Explain why permissions are required
   - Follow App Store privacy guidelines
   - Implement proper data retention policies

### Accessibility

1. **iOS Accessibility**
   - Add accessibility labels to UI elements
   - Support VoiceOver navigation
   - Test with Dynamic Type
   - Ensure sufficient color contrast
   - Support accessibility shortcuts

### UI Design & Styling

1. **Design Style: Liquid Glass**
   - Use modern liquid glass morphism design aesthetic
   - Implement frosted glass effects with blur and transparency
   - Create depth with subtle shadows and layered elements
   - Use smooth, fluid animations and transitions
   - Apply backdrop filters and blur effects appropriately
   - Maintain clean, minimalist layouts with breathing room

2. **Color Palette Restrictions**
   - **STRICTLY FORBIDDEN COLORS:** Blue, Purple, Cyan, Turquoise
   - Avoid gradient-based color schemes entirely
   - Prefer solid colors with appropriate opacity for glass effects
   - Use monochromatic or analogous color schemes (warm tones, earth tones, or neutral grays)
   - Consider colors like: Warm grays, soft whites, subtle greens, muted oranges, earth tones
   - Ensure sufficient contrast for accessibility despite glass effects

3. **Implementation Guidelines**
   - Use SwiftUI `.background()` with `.ultraThinMaterial` or `.regularMaterial` for glass effects
   - Apply `blur()` modifiers for depth and visual separation
   - Use subtle shadows (`shadow()` modifier) for elevation
   - Implement smooth animations with `withAnimation` or `Animation.spring()`
   - Maintain consistency across all screens and components

## Git & Version Control

1. **Commit Messages**
   - Use clear, concise, descriptive commit messages
   - Reference issues/tickets when applicable
   - Follow conventional commits format:
     - `feat:` for new features
     - `fix:` for bug fixes
     - `docs:` for documentation
     - `refactor:` for code refactoring
     - `test:` for tests
     - `chore:` for maintenance

2. **Branch Strategy**
   - Use feature branches for new features
   - Keep main/master branch stable
   - Regular merges to avoid large conflicts

## Specific Instructions for AI Assistant

1. **When Making Changes:**
   - Always explain what you're changing and why
   - Update related documentation files
   - Consider impact on existing code
   - Check for breaking changes

2. **When Adding Features:**
   - Follow the established architecture pattern
   - Create feature folders with proper structure
   - Add appropriate tests
   - Update README.md with feature description
   - Consider accessibility from the start
   - Follow liquid glass design style with color restrictions (no blue, purple, cyan, turquoise, or gradients)

3. **When Refactoring:**
   - Maintain backward compatibility when possible
   - Update all affected tests
   - Document architectural decisions
   - Ensure no functionality is broken

4. **When Fixing Bugs:**
   - Understand root cause before fixing
   - Add tests to prevent regression
   - Document the fix in commit message

5. **Code Generation:**
   - Generate clean, readable code
   - Include proper error handling
   - Add inline comments for complex logic
   - Use descriptive names
   - For UI code: Always follow liquid glass design style and color restrictions

6. **File Organization:**
   - Place files in appropriate directories
   - Keep related files together
   - Follow the project structure guidelines above

7. **Dependencies:**
   - Ask before adding new dependencies
   - Research alternatives
   - Document why a dependency is needed

## Communication

- Be explicit about changes and their impact
- Suggest improvements when appropriate
- Ask clarifying questions if requirements are unclear
- Explain iOS-specific concepts when relevant

---

**Remember:** The goal is to maintain a clean, maintainable, and scalable iOS codebase that follows industry best practices and is well-documented for future development.
