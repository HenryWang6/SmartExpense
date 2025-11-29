# Contributing to SmartExpense

Thank you for your interest in contributing to SmartExpense! This document provides guidelines and instructions for contributing.

## 🎯 Getting Started

1. Read the [README.md](README.md) for project overview
2. Review the [.cursorrules](.cursorrules) for development guidelines
3. Check existing issues and pull requests before starting

## 📝 Development Workflow

### Branch Naming

- Feature: `feature/feature-name`
- Bug fix: `fix/bug-description`
- Documentation: `docs/topic`
- Refactor: `refactor/area`

### Making Changes

1. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow Swift style guidelines
   - Write or update tests
   - Update documentation

3. **Commit your changes**
   - Use descriptive commit messages
   - Follow conventional commit format
   - Reference issues when applicable

4. **Push and create a PR**
   - Push your branch
   - Create a pull request
   - Fill out the PR template

## ✅ Code Review Checklist

Before submitting your PR, ensure:

- [ ] Code follows Swift style guidelines
- [ ] All tests pass
- [ ] New code has test coverage
- [ ] Documentation is updated
- [ ] No compiler warnings
- [ ] Code is properly formatted
- [ ] Accessibility labels are added (if UI changes)
- [ ] Localization strings are added (if needed)

## 🧪 Testing Guidelines

### Writing Tests

- Write unit tests for business logic
- Write UI tests for critical user flows
- Test error cases, not just happy paths
- Keep tests fast and independent

### Running Tests

```bash
# All tests
xcodebuild test -scheme SmartExpense

# Specific test target
xcodebuild test -scheme SmartExpense -only-testing:TargetName/TestClassName
```

## 📚 Documentation Standards

### Code Documentation

- Add Swift doc comments for public APIs
- Explain complex logic with inline comments
- Use meaningful variable and function names

### Updating Documentation

When making changes, update:
- README.md (if setup or dependencies change)
- CHANGELOG.md (for user-facing changes)
- Architecture docs (if structure changes)
- API docs (if interfaces change)

## 🐛 Reporting Bugs

When reporting bugs, include:

1. **Description**: Clear description of the bug
2. **Steps to Reproduce**: Step-by-step instructions
3. **Expected Behavior**: What should happen
4. **Actual Behavior**: What actually happens
5. **Environment**: iOS version, device, app version
6. **Screenshots**: If applicable
7. **Logs**: Error messages or console output

## 💡 Suggesting Features

When suggesting features:

1. Check if the feature was already requested
2. Describe the use case
3. Explain the expected behavior
4. Consider implementation complexity

## 🔒 Security

- Never commit API keys or secrets
- Use environment variables or secure storage
- Report security vulnerabilities privately

## 📋 Code Style

### Swift Style

- Follow [Apple's Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for consistent formatting
- Maximum line length: 120 characters
- Prefer `let` over `var`
- Use guard statements for early returns

### Naming Conventions

- Classes: PascalCase (`ExpenseTracker`)
- Functions/Variables: camelCase (`trackExpense`)
- Constants: camelCase (`maxExpenseAmount`)
- Enums: PascalCase, cases: camelCase

## 🚫 What Not to Do

- Don't commit directly to main/master
- Don't force unwrap without good reason
- Don't ignore compiler warnings
- Don't skip tests
- Don't break existing functionality
- Don't add dependencies without justification

## ❓ Questions?

If you have questions:

1. Check existing documentation
2. Search existing issues
3. Create a new issue with the `question` label

## 🙏 Thank You!

Your contributions make SmartExpense better for everyone. Thank you for taking the time to contribute!
