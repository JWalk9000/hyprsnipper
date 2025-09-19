
# 🧑‍� HyprSnipper: AI Agent Coding Guide

This project is a Bash-based snipping tool for Hyprland/Wayland on Linux, modeled after the Windows Snipping Tool. Use this guide to quickly onboard, extend, or debug the codebase as an AI coding agent.

---

## 🏗️ Architecture & Key Components

- **Main Script:** `bin/snip.sh` orchestrates all logic (mode selection, capture, post-processing).
- **UI Layer:** Uses `zenity` for dialogs (icon buttons, tooltips, checkboxes). Fallback: `yad`.
- **Screenshot Tools:**
  - `grim` (capture)
  - `slurp` (region selection)
  - `hyprctl` (window geometry)
- **Post-Actions:**
  - `wl-copy` (clipboard)
  - `swappy` (edit/annotate)
  - `notify-send` (notifications)
- **Config:** `config/settings.yaml` (default save dir, editor, clipboard behavior)
- **Icons:** `icons/` (PNG assets for UI buttons)

---

## � Developer Workflows

- **Run:** Execute `bin/snip.sh` directly. No build step required.
- **Test UI:** Run with `zenity` installed. Use `bash -x bin/snip.sh` for debug output.
- **Config:** Edit `config/settings.yaml` to change defaults. CLI flags override config.
- **Keybinding:** Add to `hyprland.conf`:
  ```ini
  bind = SUPER SHIFT, S, exec, ~/.local/bin/snip.sh
  ```
- **Dependencies:** Ensure `grim`, `slurp`, `zenity`, `wl-copy`, `swappy`, `notify-send` are installed.

---

## 🧩 Project Patterns & Conventions

- **UI:** Always prefer `zenity` for dialogs. Use `--icon` and `--tooltip` for clarity.
- **Modularity:** Keep Bash functions small and focused (e.g., `take_region_screenshot`, `notify_user`).
- **Error Handling:** Notify user via `notify-send` for all failures (missing deps, bad geometry, etc).
- **Post-Actions:** Support any combination of Save, Copy, Edit. Pipe screenshot data as needed.
- **Icons:** Reference icons from `icons/` by filename in UI dialogs.
- **Comments:** Add comments for any logic that may be ported to Python/GTK in the future.

---

## � Example: Adding a New Capture Mode

1. Add a new icon to `icons/`.
2. Update the mode selection dialog in `bin/snip.sh` to include the new mode (with tooltip).
3. Implement a new Bash function for the capture logic.
4. Add post-action handling (Save/Copy/Edit) as needed.
5. Update notifications for user feedback.

---

## � Key Files & Directories

- `bin/snip.sh` — main entrypoint and logic
- `config/settings.yaml` — user-configurable defaults
- `icons/` — UI button icons
- `docs/snipping-tool-instructions.md` — this guide

---

## 🤖 AI Agent Reminders

- Always prefer explicit, modular Bash functions.
- Use `zenity` for all user-facing dialogs.
- Reference config and icons by relative path.
- Document any non-obvious logic or workarounds inline.

---

For further details, see comments in `bin/snip.sh` and the project plan below.
