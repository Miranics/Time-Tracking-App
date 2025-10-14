# Time Tracker

A lightweight Flutter app for logging time against projects and tasks. Entries are persisted locally so you can track work sessions even when offline.

## Features

- 📋 Manage projects and their tasks from the in-app settings screen.
- ⏱️ Log time entries with project, task, duration, date, and optional notes.
- 📊 View entries grouped by project with total time summaries.
- 🗑️ Swipe to delete incorrect entries.
- 💾 Local storage via the `localstorage` package keeps your data across sessions.

## Getting started

1. Ensure you have the Flutter SDK installed (3.0 or newer).
2. Fetch dependencies:

```powershell
flutter pub get
```

3. Run the application on an emulator or device:

```powershell
flutter run
```

The home screen shows each project with its recent time entries. Use the **+** button to add a new entry. If no projects exist yet, you'll be prompted to create one first.

## Test suite

Run the lightweight provider tests:

```powershell
flutter test
```

These tests cover project/task CRUD operations and ensure time entries are grouped and cleaned up correctly when projects are removed.

## Project structure

- `lib/models/` – Immutable data models for projects, tasks, and time entries.
- `lib/providers/` – `TimeEntryProvider` with persistence and helper utilities.
- `lib/screens/` – UI screens for the home dashboard, entry form, and management tools.
- `test/` – Unit tests for provider behavior.

## Limitations & next steps

- The app currently stores data in a JSON file via the `localstorage` package. Consider switching to `shared_preferences` or `hive` for richer persistence and encryption.
- Editing existing entries or projects isn't implemented yet. Adding edit flows would enhance usability.
- No dedicated theming beyond the base Material color scheme; customizing the UI for dark mode would be a good enhancement.