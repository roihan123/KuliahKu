# KuliahKu

**KuliahKu** is a Flutter-based mobile application designed to help students organize and manage their academic activities. It provides features to keep track of course schedules, assignments, notes, and view them in an integrated calendar.

## Features

* **Authentication**: Secure login and registration system for users.
* **Dashboard (Halaman Utama)**:
    * Displays a welcome message with user details (name, semester, program studi).
    * Shows today's schedule at a glance.
    * Highlights urgent tasks.
    * Provides quick access to the latest notes.
* **Jadwal Kuliah (Course Schedule)**:
    * View, add, edit, and delete course schedules.
    * Displays a weekly view of the schedule.
    * Allows presetting the day when adding a new schedule.
* **Tugas (Assignments/Tasks)**:
    * Manage academic tasks and assignments.
    * Add, edit, and delete tasks.
    * Mark tasks as complete or incomplete.
    * Filter tasks by status: All, Urgent, This Week, Completed.
    * Due date badges indicate urgency (e.g., "Mendesak", "Hari Ini", "Besok").
* **Catatan (Notes)**:
    * Create, view, edit, and delete notes.
    * Organize notes by associating them with a specific course (optional).
    * Search notes by title or content.
    * Filter notes by course category.
    * Notes are displayed in a staggered grid view.
* **Kalender (Calendar)**:
    * Integrated calendar view displaying tasks (deadlines) and class schedules.
    * Navigate through months.
    * Tap on a date to see events for that day.
    * Visual indicators on dates with events.
* **Profil (User Profile)**:
    * View and edit academic information (NIM, Program Studi).
    * View current semester (Ganti Semester feature is planned).
    * Logout functionality.
    * Placeholder settings for notifications and app language.
* **Local Data Persistence**:
    * User accounts, schedules, tasks, and notes are stored locally on the device using JSON files.
* **Cross-Platform**:
    * Built with Flutter, with project configurations for Android, iOS, Web, Windows, macOS, and Linux.

## Getting Started

This project is a starting point for a Flutter application.

To get a local copy up and running, follow these simple steps:

1.  **Prerequisites**:
    * Ensure you have Flutter SDK installed. For installation instructions, visit the [Flutter official website](https://flutter.dev/docs/get-started/install).
    * An editor like Android Studio (with Flutter plugin) or VS Code (with Flutter extension).

2.  **Clone the repository**:
    ```sh
    git clone [https://github.com/your-username/KuliahKu.git](https://github.com/your-username/KuliahKu.git)
    cd KuliahKu
    ```

3.  **Install dependencies**:
    ```sh
    flutter pub get
    ```

4.  **Run the application**:
    ```sh
    flutter run
    ```
    You can also choose a specific device/emulator to run on.

## Project Structure

The project follows a standard Flutter project structure. Key directories include:

* `lib/`: Contains the Dart code for the application.
    * `main.dart`: The main entry point of the application, handles authentication and navigation to the main page.
    * `halamanutama.dart`: Implements the main dashboard screen.
    * `jadwal.dart`: Contains logic and UI for the course schedule feature.
    * `tugas.dart`: Manages tasks and assignments.
    * `catatan.dart`: Handles the notes feature.
    * `kalender.dart`: Implements the calendar view.
    * `profile.dart`: Manages the user profile screen.
* `android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`: Platform-specific configuration files.
* `assets/`: Contains static assets like images.
* `pubspec.yaml`: Defines project dependencies and metadata.

## Key Dependencies

* `flutter_localizations`: For internationalization and localization (Indonesian locale 'id_ID' is initialized).
* `intl`: For date formatting and internationalization utilities.
* `path_provider`: To find the correct local path for storing data.
* `flutter_staggered_grid_view`: Used for displaying notes in a staggered grid.
* `http`: (Included, but current data persistence is local).

## Android Specifics

* **Application ID**: `com.example.main`
* **Plugins**: Uses `com.android.application`, `kotlin-android`, and `dev.flutter.flutter-gradle-plugin`.
* **Signing**: Release builds are currently signed with debug keys for `flutter run --release` to work.
* **Permissions**: `android.permission.INTERNET` is used for development purposes (hot reload, etc.).

## Linux Build Configuration

* **Binary Name**: `main`
* **Application ID (GTK)**: `com.example.main`
* **Build System**: CMake
* **Standard Settings**: Uses C++14, with options like `-Wall`, `-Werror`.
* **Dependencies**: GTK+-3.0, GLib-2.0, Gio-2.0.

## Windows Build Configuration

* **Binary Name**: `main`
* **Build System**: CMake
* **Standard Settings**: Uses C++17, with options like `/W4`, `/WX`.
* **Target Platforms**: Runner configuration files suggest setup for Android, iOS, Linux, macOS, Web, and Windows.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
