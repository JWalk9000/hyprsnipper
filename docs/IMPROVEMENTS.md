# HyprSnipper - Planned Improvements & Upgrades

This document tracks potential enhancements and feature requests for future versions of HyprSnipper. These improvements are based on initial development insights and anticipated user feedback.

## Icon System Enhancements

### Smart Icon Color Detection
- **Current State**: All SVG icons are recolored with the theme's `icon_color`, regardless of original design
- **Improvement**: Implement intelligent detection to distinguish between:
  - **Monochrome icons**: Simple single/few-color designs intended for theming
  - **Colorful icons**: Complex multi-color designs that should preserve original colors
- **Implementation**: Analyze SVG color diversity and complexity to determine recoloring behavior
- **Benefit**: Allows users to mix themed monochrome icons with preserved colorful artwork

### Icon Format Flexibility
- **Current State**: SVG and PNG support with basic color replacement
- **Improvements**:
  - Support for animated SVG icons
  - Better PNG icon theming through image processing
  - Icon scaling optimization for different display densities
  - Theme-aware icon variants (light/dark mode specific icons)

## User Interface Improvements

### Enhanced Window Selection
- **Current State**: Window selector recreates layout based on Hyprland window positions
- **Improvements**:
  - More accurate window stacking representation
  - Preview thumbnails in window selector
  - Support for minimized/hidden windows
  - Multi-monitor window selection improvements

### Advanced Region Selection
- **Current State**: Uses slurp for interactive area selection
- **Improvements**:
  - Built-in region selector with better visual feedback
  - Preset region sizes (common aspect ratios)
  - Region selection history/favorites
  - Magnetic snap to window edges during region selection

### UI Responsiveness
- **Current State**: Fixed animation delay, basic hover effects, nearly transparent main window background
- **Improvements**:
  - **Window transparency control**: Configurable background opacity (current: nearly transparent, future: user-adjustable 0-100%)
  - Adaptive animation timing based on system performance
  - More sophisticated UI transitions and feedback
  - Keyboard navigation support
  - Accessibility improvements (screen reader support, high contrast modes)

## Configuration & Theming

### Advanced Theme System
- **Current State**: 8-color palette with pywal integration, fixed nearly-transparent background
- **Improvements**:
  - **Transparency/Opacity Controls**: User-configurable window background opacity (0-100%)
  - Theme presets library (community themes)
  - Live theme preview without restart
  - Per-mode color customization (different colors for region vs window mode)
  - Gradient and texture support for backgrounds

### Configuration Management
- **Current State**: YAML settings file with basic validation
- **Improvements**:
  - GUI settings manager (preferences dialog)
  - Configuration profiles for different workflows
  - Import/export settings functionality
  - Real-time settings validation and error reporting

## Capture & Output Features

### Enhanced Capture Options
- **Current State**: Basic screenshot capture with grim
- **Improvements**:
  - Delayed capture functionality
  - Burst mode (multiple screenshots)
  - Video recording integration
  - OCR text extraction from screenshots

### Advanced Output Handling
- **Current State**: Save, clipboard, external editor
- **Improvements**:
  - Cloud upload integration (imgur, dropbox, etc.)
  - Automatic annotation features
  - Screenshot history/gallery
  - Batch processing capabilities
  - Custom output format options (WebP, AVIF support)

## Platform & Integration

### Wayland Compositor Support
- **Current State**: Optimized for Hyprland
- **Improvements**:
  - Better support for other Wayland compositors (Sway, GNOME, KDE)
  - X11 fallback compatibility mode
  - Compositor-specific optimizations

### System Integration
- **Current State**: Basic desktop entry and PATH integration
- **Improvements**:
  - Systray/notification area integration
  - Global hotkey registration
  - Integration with file managers (context menu actions)
  - Better clipboard format handling

## Performance & Technical

### Code Architecture
- **Current State**: Modular Qt-based design
- **Improvements**:
  - Plugin system for custom capture modes
  - Better error handling and recovery
  - Performance profiling and optimization
  - Code documentation and API stabilization

### Memory & Resource Usage
- **Current State**: Basic resource management
- **Improvements**:
  - Memory usage optimization for large screenshots
  - Background service mode (persistent daemon)
  - Resource cleanup improvements
  - Startup time optimization

## Community & Distribution

### Package Management
- **Current State**: Manual installation script with basic Arch/Debian support
- **Improvements**:
  - **Enhanced cross-distro support**: Fedora/RHEL (dnf), openSUSE (zypper), Alpine (apk)
  - **Better package name handling**: Distro-specific package name mappings for PySide6, Python modules
  - **Fallback pip installation**: Automatic pip installation when distro packages unavailable
  - **Package verification**: Better detection of already-installed packages across different package managers
  - AUR package for Arch Linux
  - Flatpak distribution
  - AppImage portable version
  - Distribution-specific packages (deb, rpm)

### Documentation & Support
- **Current State**: Basic README and inline comments
- **Improvements**:
  - Comprehensive user manual
  - Video tutorials and usage examples
  - Community wiki and FAQ
  - Developer API documentation

## Experimental Features

### AI Integration
- **Future Concept**: Smart screenshot categorization and tagging
- **Future Concept**: Automatic privacy blurring (faces, sensitive text)
- **Future Concept**: Content-aware crop suggestions

### Advanced Workflows
- **Future Concept**: Screenshot scripting/automation
- **Future Concept**: Integration with productivity tools
- **Future Concept**: Team collaboration features

---

## Implementation Priority

**High Priority** (v1.1-1.2):
- Smart icon color detection
- GUI preferences dialog
- Enhanced error handling

**Medium Priority** (v1.3-1.5):
- Built-in region selector
- Theme system improvements
- Package distribution

**Low Priority** (v2.0+):
- Video recording
- AI features
- Advanced automation

---

*This document is living and will be updated based on user feedback, bug reports, and community suggestions. Feel free to contribute ideas via GitHub issues or discussions.*