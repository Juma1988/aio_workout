# Flutter Run Device

## Purpose
Default Flutter run device for this project. When asked to run the app, always use the MuMu+ Player emulator.

## Device Configuration
- **Emulator:** MuMu+ Player
- **Device ID:** `emulator-5554`
- **MuMu Path:** `C:\Program Files\MuMuPlayer`
- **ADB Path:** `C:\Program Files\MuMuPlayer\nx_device\15.0\shell\adb.exe`

## Before Running Flutter
Always ensure the emulator is connected:

```powershell
& "C:\Program Files\MuMuPlayer\nx_device\15.0\shell\adb.exe" connect 127.0.0.1:7555
```

## If Device Not Found (Recovery Commands)
```cmd
cd /d "C:\Program Files\MuMuPlayer\nx_main\runtime"
adb.exe kill-server
adb.exe start-server
adb.exe connect emulator-5554
```

## Flutter Run Command
```bash
flutter run -d emulator-5554
```

## Usage
When user says:
- "run app"
- "flutter run"
- "start the app"
- "launch app"

Always:
1. First check if emulator is connected
2. If not, run recovery commands
3. Then run `flutter run -d emulator-5554`
