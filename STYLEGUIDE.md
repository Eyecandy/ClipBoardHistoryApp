# ClipboardHistoryApp – Style Guide

This style guide is for myself (and any future contributors) to ensure code quality, consistency, and maintainability in the ClipboardHistoryApp project.

---

## 1. Naming Conventions
- **Types (struct, class, enum, protocol):** UpperCamelCase (e.g., `ClipboardItem`, `ClipboardManager`)
- **Variables & Properties:** lowerCamelCase (e.g., `clipboardItems`, `maxHistorySize`)
- **Constants:** lowerCamelCase, use `let` (e.g., `defaultShortcut`)
- **Functions & Methods:** lowerCamelCase, verb-based (e.g., `addItem()`, `clearHistory()`)
- **Files:** Match the main type or feature (e.g., `ClipboardManager.swift`)

---

## 2. File Organization
- **One type per file** (unless types are tightly coupled, e.g., a view and its style).
- **Group files by feature** (e.g., all clipboard logic in `ClipboardHistoryCore/`, all entry points in `ClipboardHistoryApp/`).
- **Tests** go in `Tests/ClipboardHistoryCoreTests/` and mirror the source structure.

---

## 3. Code Formatting
- **Indentation:** 4 spaces (no tabs)
- **Line Length:** 120 characters max
- **Braces:** K&R style (opening brace on same line)
- **Spacing:**
  - One blank line between functions
  - No trailing whitespace
  - Use whitespace for readability, but avoid excessive blank lines
- **Access Control:**
  - Use `private`/`fileprivate` for implementation details
  - Use `public` only when necessary (e.g., for library API)

---

## 4. SwiftUI & UI
- **Views:**
  - Use `struct` for all views
  - Keep views small and composable
  - Use custom `ButtonStyle` for consistent button appearance
- **Modifiers:**
  - Chain modifiers for clarity
  - Extract repeated modifier chains into custom view extensions or styles

---

## 5. Documentation
- **Public types and functions:** Use Swift doc comments (`///`)
- **Complex logic:** Add inline comments explaining the why, not just the what
- **README and STYLEGUIDE:** Keep up to date with any major changes

---

## 6. Commit Messages
- Use present tense, imperative mood (e.g., `Add`, `Fix`, `Refactor`)
- Be specific and concise
- Reference issues or features if relevant

---

## 7. Code Review (for myself)
- Review all changes before committing
- Run all tests before merging
- Refactor code for clarity and simplicity before adding new features
- Avoid large, monolithic commits—prefer small, focused changes

---

## 8. Testing
- Write tests for all new features and bugfixes
- Use descriptive test names (e.g., `testClipboardItemIsAddedToHistory`)
- Keep tests isolated and independent

---

## 9. Dependencies
- Add dependencies only when necessary
- Prefer SwiftPM-compatible libraries
- Document any new dependency in the README

---

## 10. Miscellaneous
- Prefer value types (`struct`) over reference types (`class`) unless necessary
- Avoid force-unwrapping optionals (`!`), use safe unwrapping (`if let`, `guard let`)
- Use `MARK:` comments to organize code sections in large files 