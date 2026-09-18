# 📱 DinePulse APK Installation Guide

This guide explains where the compiled APK file is located on your computer and how to install it directly onto your physical Android phone.

---

## 📍 Where the APK is Located

Both **Release** and **Debug** APK files are located in your project's build directory:

### 1. Production Release APK *(Recommended for physical phones)*
* **File Path:**  
  `/Users/shehan/Desktop/Nikii/HCI/build/app/outputs/flutter-apk/app-release.apk`
* **File Size:** ~54 MB
* **Performance:** Fast, optimized, smaller file size, battery-efficient.

### 2. Debug APK
* **File Path:**  
  `/Users/shehan/Desktop/Nikii/HCI/build/app/outputs/flutter-apk/app-debug.apk`
* **File Size:** ~160 MB
* **Performance:** Includes hot-reload symbols and developer inspection tools.

> 💡 **Recommendation:** Always use **`app-release.apk`** to install on your personal phone.

---

## 🚀 How to Install on Your Android Phone

Choose whichever method is most convenient for you:

### Method 1: USB Cable Install via Terminal (Fastest if ADB is set up)

1. Connect your Android phone to your Mac using a USB-C cable.
2. On your phone:
   * Go to **Settings** → **About phone** → tap **Build number** 7 times to enable Developer options.
   * Go to **Settings** → **System** → **Developer options** → turn on **USB Debugging**.
   * Allow the "Allow USB debugging?" prompt on your phone screen.
3. Open Terminal on your Mac and run:
   ```bash
   ~/Library/Android/sdk/platform-tools/adb install -r /Users/shehan/Desktop/Nikii/HCI/build/app/outputs/flutter-apk/app-release.apk
   ```
4. The app will install directly onto your phone and appear in your app drawer as **DinePulse**.

---

### Method 2: Direct File Transfer via USB Cable (No commands needed)

1. Connect your phone to your Mac using a USB cable.
2. On your phone, swipe down the notification shade and tap **Charging this device via USB** → select **File Transfer / Android Auto (MTP)**.
3. On your Mac:
   * Open **Android File Transfer** (or **Finder** / **OpenMTP**).
   * Navigate to your phone's **Downloads** folder.
   * Drag and drop `app-release.apk` from `/Users/shehan/Desktop/Nikii/HCI/build/app/outputs/flutter-apk/` into your phone's **Downloads** folder.
4. On your phone:
   * Open the **Files** (or **My Files** / **File Manager**) app.
   * Go to **Downloads** and tap **app-release.apk**.
   * Follow the on-screen prompts to install (see [Allow Unknown Apps](#-allowing-install-from-unknown-apps) below).

---

### Method 3: Wireless Transfer (Google Drive / WhatsApp / Telegram)

1. **Google Drive:**
   * On your Mac browser, open [drive.google.com](https://drive.google.com).
   * Upload `app-release.apk`.
   * On your Android phone, open the Google Drive app, find `app-release.apk`, tap it to download, and tap **Install**.
2. **WhatsApp / Telegram Web:**
   * Send `app-release.apk` as a document to yourself or a saved messages chat.
   * Download and tap the file on your phone to install.

---

## 🔒 Allowing "Install from Unknown Apps" (First-time setup)

Because this APK is installed directly rather than from the Google Play Store, Android will show a standard security prompt:

1. When you tap the APK in your file manager or browser, Android will say:  
   *"For your security, your phone is not allowed to install unknown apps from this source."*
2. Tap **Settings**.
3. Toggle ON **Allow from this source**.
4. Press the **Back** button and tap **Install**.

---

## ⚠️ Google Play Protect Prompt

If Google Play Protect displays a message saying:
> *"Unrecognized app details: DinePulse"* or *"Blocked by Play Protect"*

1. Tap **More details** (or the down arrow).
2. Tap **Install anyway**.

---

## 🛠️ How to Rebuild a Fresh APK Later

If you make further changes to the app code and want to generate a new APK:

* **To build a new Release APK:**
  ```bash
  cd /Users/shehan/Desktop/Nikii/HCI
  flutter build apk --release
  ```

* **To build a new Debug APK:**
  ```bash
  cd /Users/shehan/Desktop/Nikii/HCI
  flutter build apk --debug
  ```
