# Time Tracker

A lightweight Flutter app for logging time against projects and tasks. Entries are persisted locally so you can track work sessions even when offline.

## Features

- 📋 Manage projects and their tasks from the management screen or hamburger menu.
- ⏱️ Log time entries with project, task, duration, date, and optional notes.
- 📊 View entries grouped by project with total time summaries and task breakdowns.
- 🗑️ Swipe to delete incorrect entries with confirmation prompts.
- 💾 Inspect and clear persisted data through an in-app storage viewer backed by the `localstorage` package.

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

The home screen shows each project with its recent time entries. Use the **+** button or the hamburger menu to add a new entry. If no projects exist yet, you'll be prompted to create one first.

## Navigation cheat-sheet (for screenshots)

- **Hamburger menu** – Open from the home screen to reach Add Entry, Project/Task management, and the Local Storage Viewer screens.
- **Empty state** – Launch after clearing storage from the viewer to capture the empty home screen.
- **Add Time Entry form** – Accessible via the FAB or menu; choose a project, optional task, duration, date, and notes before saving.
- **Project management** – Lists projects with a floating **+** button; dialogs allow creating and deleting projects and tasks.
- **Local Storage Viewer** – Presents JSON snapshots of saved projects/time entries plus a "Clear all" button for quick resets.

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