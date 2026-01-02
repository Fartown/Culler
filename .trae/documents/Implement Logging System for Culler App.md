# Create Logging System for Culler

## 1. Logger Service Implementation
Create `Culler/Culler/Services/Logger.swift` to handle log writing and management.

### Features
*   **Singleton Access**: `Logger.shared` for easy access anywhere.
*   **File Storage**: Store logs in `ApplicationSupport/Logs` directory.
*   **Log Format**: `[Date] [Level] [Category] Message`.
*   **Rotation Policy**:
    *   Check total size of logs directory on initialization and after writing.
    *   If total size > 20MB, delete oldest log files until size < 20MB.
    *   Create a new log file per day (e.g., `log_2023-10-27.txt`).
*   **Thread Safety**: Use a serial `DispatchQueue` for file operations.

## 2. Log Viewer UI
Create a new directory `Culler/Culler/Views/LogViewer` and implement the viewer interface.

### Components
*   **`LogViewer.swift`**: The main container using `NavigationSplitView`.
    *   **Sidebar**: List of log files sorted by date (newest first).
    *   **Detail View**: A scrollable text view showing the content of the selected log file.
    *   **Actions**:
        *   "Refresh": Reload file list.
        *   "Delete": Delete selected log file.
        *   "Reveal in Finder": Open the logs folder.
        *   "Clear All": Delete all logs.

## 3. App Integration
Integrate the logger into the main application flow.

### `CullerApp.swift`
*   Initialize `Logger` on app launch.
*   Add a new `WindowGroup` with id `"logViewer"` to host the `LogViewer`.
*   Add a `CommandMenu("Help")` with a "View Logs" button to open the log window.

### Logging Points
Add critical logs to:
*   **App Lifecycle**: `CullerApp.init()` / `body`.
*   **ThumbnailService**: Log errors when thumbnail generation fails; log performance (time taken) for large images.
*   **User Actions**: Log import start/finish, rating changes (in `PhotoCommands`).

## 4. Verification
*   **Functional Test**: Launch app, perform actions, open Log Viewer, verify logs appear.
*   **Rotation Test**: Manually create dummy large files in the log directory and trigger the logger to verify old files are deleted.
