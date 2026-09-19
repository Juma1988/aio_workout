# Project Memory

## Default Flutter Run Device

**Always** use MuMu+ Player emulator when running the app.

### Device Info
- **Emulator:** MuMu+ Player
- **Device ID:** `emulator-5554`
- **ADB Path:** `C:\Program Files\MuMuPlayer\nx_device\15.0\shell\adb.exe`
- **Samsung Device:** SM-G9980 (Galaxy S21 Ultra) - Android 15

### Before Running Flutter
1. Check if device is connected:
   ```powershell
   & "C:\Program Files\MuMuPlayer\nx_device\15.0\shell\adb.exe" devices
   ```

2. If not connected, connect it:
   ```powershell
   & "C:\Program Files\MuMuPlayer\nx_device\15.0\shell\adb.exe" connect 127.0.0.1:7555
   ```

3. If still not working, run recovery:
   ```cmd
   cd /d "C:\Program Files\MuMuPlayer\nx_main\runtime"
   adb.exe kill-server
   adb.exe start-server
   adb.exe connect emulator-5554
   ```

### Flutter Run Command
```bash
flutter run -d emulator-5554
```
