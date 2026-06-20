# 📚 Documentation Index

Complete navigation for all automation bot documentation.

**Last Updated**: 2026-03-03 (v3)

## 🚀 Quick Start

| Document | Purpose | Read Time |
|----------|---------|-----------|
| [SETUP.md](SETUP.md) | Initial project setup | 5 min |
| [QUICK-REFERENCE.md](QUICK-REFERENCE.md) | Common commands and workflows | 3 min |
| [STATUS.md](STATUS.md) | Current project status | 2 min |

## 📖 Core Guides

### Essential Documentation

| Guide | What It Covers | When to Read |
|-------|----------------|--------------|
| [DDT-HYBRID-LOGIN-SERVER.md](DDT-HYBRID-LOGIN-SERVER.md) | Login A11y + mitm rewrite (S10/S12) + setup emulador | Automatizar entrada no servidor DDT |
| [MITM-EMULATOR-RUNBOOK.md](MITM-EMULATOR-RUNBOOK.md) | Cert system + mitm no Mac (copiar/colar) | Arrancar mitm/DDT sem remount failed |
| [SCREENSHOT-GUIDE.md](SCREENSHOT-GUIDE.md) | MediaProjection screenshot system | Understanding capture |
| [VISION-API.md](VISION-API.md) | Template matching and detection | Using Vision API |
| [LOGGING-GUIDE.md](LOGGING-GUIDE.md) | Unified logging system | Debugging and monitoring |
| [UI-GUIDE.md](UI-GUIDE.md) | Floating window and click effects | UI customization |

### Technical Details

| Document | Content | Audience |
|----------|---------|----------|
| [DOCUMENTATION.md](DOCUMENTATION.md) | Architecture and MVVM structure | Developers |
| [CODE-STANDARDS.md](CODE-STANDARDS.md) | Coding conventions and patterns | Contributors |
| [DEVELOPMENT.md](DEVELOPMENT.md) | Development workflow | Team members |
| [ANDROID-PERMISSIONS-EXPLAINED.md](ANDROID-PERMISSIONS-EXPLAINED.md) | Permission system details | Android devs |
| [ACCESSIBILITY-GUIDE.md](ACCESSIBILITY-GUIDE.md) | Click system via Accessibility | Integration devs |

## 🎯 By Topic

### Screenshots & Capture
- **[SCREENSHOT-GUIDE.md](SCREENSHOT-GUIDE.md)** - Complete MediaProjection guide
  - How it works
  - Setup and configuration
  - Troubleshooting
  - Performance metrics

### Vision & Detection
- **[VISION-API.md](VISION-API.md)** - Template matching system
  - Endpoints (`/lens`, `/match`, `/ocr`)
  - Template creation best practices
  - Dual-method validation
  - Debug techniques

### Logging & Monitoring
- **[LOGGING-GUIDE.md](LOGGING-GUIDE.md)** - Unified logging
  - AutoLogger usage
  - Floating log window
  - Log files and cleanup
  - Best practices

### User Interface
- **[UI-GUIDE.md](UI-GUIDE.md)** - UI components
  - FloatingLogWindow
  - ClickEffectOverlay
  - MainActivity
  - Customization

### Automation
- **[ACCESSIBILITY-GUIDE.md](ACCESSIBILITY-GUIDE.md)** - Click system
  - Accessibility Service setup
  - Click execution
  - Permissions

### Development
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Developer workflow
  - Build and deploy
  - Testing
  - Common tasks

- **[CODE-STANDARDS.md](CODE-STANDARDS.md)** - Code quality
  - Naming conventions
  - Architecture patterns
  - Best practices

### Architecture
- **[DOCUMENTATION.md](DOCUMENTATION.md)** - System design
  - MVVM pattern
  - Clean architecture
  - Component responsibilities

### Setup & Configuration
- **[SETUP.md](SETUP.md)** - Initial setup
  - Requirements
  - Installation
  - First run

- **[ANDROID-PERMISSIONS-EXPLAINED.md](ANDROID-PERMISSIONS-EXPLAINED.md)** - Permissions
  - Why each permission
  - How to grant
  - Troubleshooting

## 🔍 By Task

### "I want to..."

**...understand the system:**
1. Start: [STATUS.md](STATUS.md)
2. Overview: [DOCUMENTATION.md](DOCUMENTATION.md)
3. Deep dive: Core guides above

**...set up the project:**
1. [SETUP.md](SETUP.md)
2. [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
3. Test with [../../utils/scripts/bot/check-health.sh](../../utils/scripts/bot/check-health.sh)

**...add a new screen detection:**
1. [VISION-API.md](VISION-API.md) - Template creation
2. [SCREENSHOT-GUIDE.md](SCREENSHOT-GUIDE.md) - Capture mechanics
3. [DEVELOPMENT.md](DEVELOPMENT.md) - Add to `GameScreen.kt`

**...debug detection issues:**
1. [VISION-API.md](VISION-API.md) - Debug techniques
2. `./run/view-debug.sh` - Visual debug
3. [LOGGING-GUIDE.md](LOGGING-GUIDE.md) - Check logs

**...customize the UI:**
1. [UI-GUIDE.md](UI-GUIDE.md) - UI components
2. [LOGGING-GUIDE.md](LOGGING-GUIDE.md) - Log display

**...troubleshoot errors:**
1. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Common issues
2. Specific guide for component (see topics above)
3. [../../utils/scripts/bot/check-health.sh](../../utils/scripts/bot/check-health.sh) - System check

**...contribute code:**
1. [CODE-STANDARDS.md](CODE-STANDARDS.md) - Standards
2. [DEVELOPMENT.md](DEVELOPMENT.md) - Workflow
3. [DOCUMENTATION.md](DOCUMENTATION.md) - Architecture

## 📊 Documentation Stats

### Active Documentation (13 files)

```
Core Guides:        4 files (SCREENSHOT, VISION, LOGGING, UI)
Technical Docs:     5 files (DOCUMENTATION, CODE, DEVELOPMENT, PERMISSIONS, ACCESSIBILITY)
Quick Reference:    4 files (INDEX, STATUS, QUICK-REF, SETUP)

Total:             13 files (~90KB)
```

### Archived Documentation (30 files)

Historical docs preserved in `archive/` folder:
- Bug fixes and specific solutions
- Implementation details (already applied)
- Alternative approaches (not used)
- Refactoring documentation

## 🎓 Reading Paths

### For New Developers

```
1. STATUS.md           (What is this?)
2. SETUP.md            (How do I set it up?)
3. QUICK-REFERENCE.md  (What can I do?)
4. DOCUMENTATION.md    (How does it work?)
5. Specific guides     (Deep dives)
```

### For Contributors

```
1. CODE-STANDARDS.md   (How should I code?)
2. DEVELOPMENT.md      (What's the workflow?)
3. DOCUMENTATION.md    (What's the architecture?)
4. Relevant guides     (Component-specific)
```

### For Troubleshooting

```
1. QUICK-REFERENCE.md  (Common issues)
2. Specific guide      (Component-related)
3. ../../utils/scripts/bot/check-health.sh (System diagnostic)
4. Logs                (What happened?)
```

## 🔄 Documentation Updates

### When to Update

- ✅ New features added
- ✅ Architecture changes
- ✅ Bug fixes (if significant)
- ✅ API changes
- ✅ Configuration updates

### How to Update

1. Edit relevant guide(s)
2. Update INDEX.md if structure changed
3. Update STATUS.md for feature changes
4. Add to QUICK-REFERENCE.md if common task

## 🗺️ Navigation Tips

### Find by Component

- **MediaProjection** → SCREENSHOT-GUIDE.md
- **Vision API** → VISION-API.md
- **AutoLogger** → LOGGING-GUIDE.md
- **FloatingLogWindow** → UI-GUIDE.md
- **Accessibility Service** → ACCESSIBILITY-GUIDE.md
- **Use Cases** → DOCUMENTATION.md
- **Scripts** → [utils/scripts/bot/](../../utils/scripts/bot/)

### Find by Error

Search in relevant guide:
- Screenshot errors → SCREENSHOT-GUIDE.md
- Detection errors → VISION-API.md
- Permission errors → ANDROID-PERMISSIONS-EXPLAINED.md
- Click errors → ACCESSIBILITY-GUIDE.md

### Find by Task

Use "I want to..." section above or QUICK-REFERENCE.md

## 📞 Quick Links

### Most Used

- [Quick Reference](QUICK-REFERENCE.md) - Common commands
- [Status](STATUS.md) - What's working
- [Scripts](../../utils/scripts/bot/) - Bot shell scripts
- [Templates](../app/src/main/assets/templates/ddt/login/README.md) - Template guide

### External Resources

- [Android MediaProjection](https://developer.android.com/reference/android/media/projection/MediaProjection)
- [Accessibility Service](https://developer.android.com/guide/topics/ui/accessibility/service)
- [OpenCV Template Matching](https://docs.opencv.org/4.x/d4/dc6/tutorial_py_template_matching.html)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

---

**Navigate with confidence! All docs are up-to-date as of v3.** 📚✨

Need help? Start with [QUICK-REFERENCE.md](QUICK-REFERENCE.md) or [STATUS.md](STATUS.md)
