I will resolve the layout shift and overlap issue by implementing a **custom sidebar section header** that completely replaces the system's default collapsible header behavior.

**The Problem:**
The system's sidebar section header dynamically shows/hides the collapse chevron on hover. This appearance/disappearance changes the available width for the header content, causing the "Toggle" switch and other buttons to jump or overlap, even with added padding.

**The Solution:**
1.  **Disable System Header**: I will remove the `header:` parameter from the `Section` views. This prevents the system from rendering its own header and dynamic chevron.
2.  **Create Custom Header**: I will create a reusable `SidebarSectionHeader` view.
    *   It will include a **Custom Chevron** that is always visible (or at least always occupies fixed space), preventing layout shifts.
    *   It will handle the expansion/collapse animation manually using `withAnimation`.
    *   It will allow embedding custom controls (like the Toggle or Add Button) that remain clickable and stable.
3.  **Refactor Sections**: I will update `foldersSection`, `albumsSection`, and `filtersSection` to use this new header pattern.

**Implementation Details:**
*   **File**: `Culler/Views/SidebarView.swift`
*   **New Component**: `SidebarSectionHeader` struct.
*   **Logic**: 
    *   The header will be the first item in the `Section` content.
    *   The section content (e.g., `OutlineGroup`, `ForEach`) will be wrapped in `if isExpanded { ... }`.
    *   This gives us full control over the layout and eliminates the "hover jump."

This approach ensures the "Subfolders" toggle stays in a fixed position and the chevron is always accounted for in the layout.