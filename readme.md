# 🎮 joy4ge — Joystick for Google Earth

`joy4ge` is a framework and a set of tools that allow you to control **Google Earth Pro** (on macOS) with any USB HID-compatible controller, joystick, gamepad, or custom device.

Originally developed for use with the internal 3DconnexionClient framework, it now also includes a lightweight tool `HIDToKey`, which translates raw HID input into keyboard events. This lets you control Google Earth even in the **web browser** version.

---

## 📚 Contents

- [Overview](#overview)
- [Installation & Building](#installation--building)
- [Usage with Google Earth Pro](#usage-with-google-earth-pro)
- [Live Key Mapping: HIDToKey](#live-key-mapping-hidtokey)
- [Console Output](#console-output)
- [Configuration File](#configuration-file)
- [Development Notes](#development-notes)
- [Known Issues](#known-issues)
- [Changelog](#changelog)
- [Authors](#authors)
- [License](#license)

---

## 🧭 Overview

`joy4ge` consists of:

- A **framework** that can be injected into `Google Earth Pro` using the 3DconnexionClient interface to emulate a 3D mouse,
- A **fallback tool** `HIDToKey`, which sends simulated keyboard events based on gamepad input for compatibility with Google Earth **in the browser** or when the framework injection fails.

It supports deadzone calibration, axis-to-key mapping, button translation (with modifiers), and multiple device types.

---

## 🛠️ Installation & Building

### Framework (Original `joy4ge`)

1. Open the Xcode project (`3DconnexionClient.xcodeproj`).
2. Build it (last verified with Xcode 16.2 / Google Earth 7.3.6).
3. The compiled framework will be placed in:

   ```
   ~/Library/Frameworks/3DconnexionClient.framework/
   ```

   or install to `/Library/Frameworks/` if needed for system-wide access or you have Google Earth 7.3 and later.

### HIDToKey

A standalone tool located under `/HIDToKey/`:

```bash
cd HIDToKey/
./build.sh
```

This will compile the command-line tool. You can run it directly:

```bash
./HIDToKey
```

It will listen for input from connected USB HID devices and simulate keyboard input accordingly.

---

## 🌍 Usage with Google Earth Pro

1. Ensure your custom version of `3DconnexionClient.framework` is placed in:
   ```
   ~/Library/Frameworks/
   ```
   or, if needed:
   ```
   /Library/Frameworks/
   ```

>  With Version 7.3 and later it works only from `/Library/Frameworks/`, not `~/Library/Frameworks/`
>  Tip: If you have a real 3Dconnexion device, you don’t need joy4ge.

### Version 6.0 for macOS

Works out of the box with `joy4ge` (named `3DconnexionClient.framework` after compiling).

### Version 7.1 and later

Google Earth ships with a **built-in 3DconnexionClient.framework** inside the app bundle, which overrides the user-installed version. You must:

1. Open the `Google Earth.app` bundle:
   ```
   /Applications/Google Earth Pro.app/Contents/Frameworks/
   ```
2. Rename or remove `3DconnexionClient.framework` inside that folder.

> Version 7.3 and later did not have a built-in 3DconnexionClient.framework.

---

## ⌨️ Live Key Mapping: HIDToKey

`HIDToKey` allows live mapping of controller buttons and analog axes to macOS keyboard events. This makes it possible to control **Google Earth in Safari, Chrome, Firefox**, or any other app using only standard keys (like arrow keys, page up/down, shift-modified inputs, etc.).

### Features

- Up to 16 buttons and 4 analog axes supported
- Per-button key and modifier assignment
- Per-axis calibration with deadzone and direction mapping
- Detects button **edges** (press/release), not just state
- Modifier-aware (Shift, Command, etc.)
- Diagonal movement and multi-key combos supported
- Plain C and Objective-C — no dependencies

---

## 🖥️ Console Output

When the joy4ge framework is active (means you installed it correct an than start Google Earth) and you have pluged in an USB HID device to your computer you should see in the Apple Console Log entries like this:
```
12.08.15 08:44:13,224 Google Earth[2885]: InstallConnexionHandlers()
12.08.15 08:44:13,225 Google Earth[2885]: RegisterConnexionClient(signature = 45727468, name = (null), mode = 0001, mask = 00003F00)
12.08.15 08:44:14,281 Google Earth[2885]: HID device plugged: PS3/PC Adaptor
12.08.15 08:44:14,282 Google Earth[2885]: Number of detected axis: 4
12.08.15 08:44:14,282 Google Earth[2885]: Number of detected buttons: 12
```

When you execute HIDToKey in a terminal, you'll see something like:

```
🎮 Starte HIDToKey (alle Buttons → Tastatur)
✅ Lausche auf Eingaben...
➡️ down
➡️ up
🇷2️⃣ down
🇷2️⃣ up
X ⇦ down
X ⇦ up
```

Useful for debugging mappings or identifying unknown buttons/axes.

---

## 🧩 Configuration File (for framework version)

For the original `3DconnexionClient.framework`, a configuration file is created at:

```
~/Library/Application Support/3DconnexionClient/controller.config.plist
```

It includes for each controller it was connected to:

- Button and axis mappings
- Deadzone calibration
- Sensitivity scaling

The first generated configuration will be based on the developer's default controller. You can edit this file manually to suit your device.

> ⚠️ Documentation on the structure of this config is still minimal. Check the source code for guidance.

---

## 🧪 Development Notes

- Goal was to support a wide range of HID devices (PS3-style, wheel pedals, flight sticks, etc.)
- Currently designed for **macOS**
- `HIDToKey` requires no system extensions or root privileges
- A future GUI for mapping and calibration is **welcome** — join the project!

---

## ⚠️  Known Issues

### Google Earth Pro crashes on launch with connected Bluetooth HID (macOS)

#### Description:

On macOS 14.x (Sonoma), Google Earth Pro 7.3.6.x crashes at startup when a Bluetooth HID device (e.g. Gamepad Controller) is already connected before launching the application.
This happens on Apple Silicon (Rosetta) installations.
Crash does not occur when:
- a HID gamepad controller is connected via USB, or
- the Bluetooth HID controller is connected after GE has started.

⚠️ This is a bug in Google Earth Pro 7.3.6.x and and happens completely without `joy4ge` installed!
     It is just listed here since you will very likely see it when using  `joy4ge` with a Bluetooth HID controller.

#### Reproduction Steps:

1) Pair a Bluetooth HID controller
2) Launch Google Earth Pro.
3) App crashes within 1–2 seconds.

#### System Info:
- macOS 14.7
- GE Pro 7.3.6.10201
- Apple M1 via Rosetta (64-bit Intel)

#### Hypothesis:
Google Earth seems to register for HID devices directly during initialization, possibly without checking if the HID stack is fully ready (especially for Bluetooth devices which may initialize asynchronously). This might trigger a crash due to incomplete or invalid device state.

#### Workaround:
Turning off Bluetooth before launching Google Earth avoids the crash.

## 📝 Changelog

### 2025
- Added: `HIDToKey` as browser-compatible fallback tool
- Axis deadzone handling and shift modifiers fully working
- Project converted to GitHub with MIT License
- `build.sh` script added

### 2021
- Compatible with Google Earth Pro 7.3.4.8248
- Added: Support for `SetConnexionHandlers()`
- Works only from `/Library/Frameworks/`, not `~/Library/Frameworks/`

### 2020
- Google Earth 7.3.3.7786 compatibility
- Framework must now be installed in `/Library/Frameworks/`
- Google Software Update interferes — workaround: block with Little Snitch

### 2017
- Added: Example configuration
- Updated: Project for Xcode 7.3.1
- Updated: 3Dconnexion API v10-4-4 (r2541)
- Google Earth Pro 7.3.0.3832 support

---

## 👨‍💻 Authors

- **Stino** — original author of `joy4ge` and `HIDToKey.m`
- **Keysworth** *(ChatGPT/OpenAI)* — co-author and helper for `HIDToKey.m`

---

## 📄 License

MIT License — see `LICENSE` file for full text.

> Use at your own risk. The authors are not responsible for damage caused by this software.  
> Compatible with all USB HID devices on macOS that follow standard descriptors.
