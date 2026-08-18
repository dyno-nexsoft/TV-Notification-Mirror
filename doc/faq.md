# TV Notification Mirror — Frequently Asked Questions

## Getting Started

### How do I connect my phone to the TV?

1. Open the **TV Mirror** app on your Android TV.
2. Go to **Pair Device** from the navigation rail.
3. On your phone, open the TV Mirror app and tap **Scan QR to Pair** or **Connect with IP Address**.
4. Scan the QR code displayed on the TV, or enter the IP address and PIN shown on the TV screen.

### Do both devices need to be on the same Wi-Fi network?

Yes. The phone and TV must be on the same local network for WebSocket communication and mDNS discovery to work.

### Can I test with emulators on my computer?

Yes. Run the phone on `emulator-5554` and the TV on `emulator-5556`. Then run:

```
adb -s emulator-5556 forward tcp:8080 tcp:8080
```

On the phone app, connect using IP `10.0.2.2:8080`.

## Fire TV Stick

### Which Fire TV devices are supported?

The TV app runs on Fire TV Stick / Fire TV (Fire OS 6/7/8, i.e. Android 7.1.2+) — all models from the 2016 2nd-gen Stick onwards, including 4K and 4K Max. The 2014 1st-gen Stick (Android 5.1) is too old for the app's minimum SDK.

### How do I install the app on a Fire TV Stick?

Amazon Fire TV has no Google Play Store, so the TV app APK is **sideloaded**:

1. Download `noti-mirror-tv-<version>.apk` from the project's GitHub Releases.
2. On the Fire TV, enable **ADB debugging**: *Settings → My Fire TV → Developer options → ADB debugging → ON* (and *Install unknown apps* for the Downloader app if you copy the APK via Downloader).
3. Install over ADB from a computer on the same Wi-Fi network:
   ```
   adb connect <FIRE_TV_IP>:5555
   adb install noti-mirror-tv-<version>.apk
   ```

### The overlay permission can't be granted — no "Display over other apps" screen

Fire TV lacks a "Display over other apps" settings page for third-party apps, so the in-app **Grant Overlay Permission** button can't open one. The app detects this and shows an ADB guide automatically. Manually, the grant is:

```
adb connect <FIRE_TV_IP>:5555
adb shell appops set com.dyno.tv_notification_mirror.tv SYSTEM_ALERT_WINDOW allow
```

Then relaunch the app — the Home screen banner clears once the permission is detected.

### The battery-optimization whitelist can't be opened either

Fire TV also has no battery-optimization settings screen. Since the Stick is mains-powered this rarely matters, but to whitelist the background service anyway:

```
adb shell dumpsys deviceidle whitelist +com.dyno.tv_notification_mirror.tv
```

## Notifications

### Which notifications get mirrored?

By default, all notifications are mirrored. You can filter by:

- **Individual app** — enable/disable specific apps from the App Filters screen in Settings.
- **Category** — toggle Call Notifications, Text Messages, or Image Previews in Settings.
- **Quiet Hours** — silence notifications during a set time window.
- **Blocked Keywords** — suppress notifications containing certain words.

### Can I reply to notifications from the TV?

No. The TV app currently only displays notifications. Replying or taking actions on notifications is not supported.

### How do I stop receiving notifications temporarily?

On the TV, toggle **Do Not Disturb** from the Home screen. You can set a timed DND (1 Hour, 6 Hours, Until Tomorrow) or turn it on indefinitely.

## Troubleshooting

### The TV app won't discover my phone.

- Make sure both devices are on the same Wi-Fi network.
- Check that mDNS (Bonjour) is not blocked by your router or firewall.
- Try connecting manually by entering the TV's IP address in the phone app.

### Notifications aren't appearing on the TV.

- Verify that **Notification Listener Service** is enabled for the phone app in Android Settings.
- Check that **Mirror Phone Notifications** is toggled on in the phone app's Settings.
- Ensure the TV's **Notification Receiving** switch is on.

### The overlay doesn't show up on TV.

- Make sure the TV app has **Display Over Other Apps** permission enabled.
- Grant **Notification** permission when prompted.
- Restart the background service from the TV app's Settings.
- On **Fire TV Stick** there is no settings toggle — grant it via ADB instead (see the Fire TV Stick section above).

## Privacy & Security

### Is my data sent over the internet?

No. All communication happens locally over your Wi-Fi network. Your notifications never leave your home network.

### Is the connection encrypted?

Yes. The WebSocket connection between phone and TV is secured using a pairing token that is exchanged during the initial pairing process.

## Technical

### What Android versions are supported?

- **Phone app**: Android 8.0 (API 26) and above.
- **TV app**: Android 8.0 (API 26) and above — Android TV, Google TV, and **Fire TV Stick** (Fire OS 6/7/8, sideloaded).

### Is this app open source?

Yes. The source code is available at:
https://github.com/dyno-nexsoft/TV-Notification-Mirror
