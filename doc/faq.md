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

## Privacy & Security

### Is my data sent over the internet?

No. All communication happens locally over your Wi-Fi network. Your notifications never leave your home network.

### Is the connection encrypted?

Yes. The WebSocket connection between phone and TV is secured using a pairing token that is exchanged during the initial pairing process.

## Technical

### What Android versions are supported?

- **Phone app**: Android 8.0 (API 26) and above.
- **TV app**: Android 8.0 (API 26) and above (Android TV / Google TV).

### Is this app open source?

Yes. The source code is available at:
https://github.com/dyno-nexsoft/TV-Notification-Mirror
