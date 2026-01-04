I will fix the overlap issue by increasing the trailing padding of the sidebar section headers. This will ensure there is enough space for the system's collapse/expand chevron (arrow) without overlapping your custom controls (Toggle/Buttons).

**Planned Changes:**

1. **Modify** **`Culler/Views/SidebarView.swift`**:

   * Locate the `header` blocks for `foldersSection`, `albumsSection`, and `filtersSection`.

   * Increase the trailing padding from `.padding(.trailing, 12)` to `.padding(.trailing, 28)`.

   * This adjustment creates a safe zone on the right side where the system chevron appears on hover, preventing it from covering the Toggle switch or header buttons.

**Verification:**

* After applying the changes, the sidebar headers should display the "Subfolders" toggle and other buttons clearly to the left of the collapse arrow, with no overlap when hovering.

