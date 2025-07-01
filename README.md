
-----

# Bank Sampah App

## Project Overview

The Bank Sampah App is a Flutter-based mobile application designed to streamline waste management and recycling processes for **Customers (Nasabah)** and **Collectors (Pengepul)**. This application aims to foster environmental sustainability by simplifying waste collection and providing a transparent system for valuing recyclable materials, effectively turning trash into cash.

-----

## Key Features

### For Customers (Nasabah)

  - **Registration & Authentication:** Secure sign-up using NIK (Nomor Induk Kependudukan) and robust login functionality.
  - **Waste Deposit:** Easily initiate waste deposits, specifying waste types and estimated weights.
  - **Savings Account (Buku Tabungan):** Track your current balance and view a detailed history of all deposits and withdrawals.
  - **Performance Analytics:** Visualize your contributions with insightful charts, showing the percentage of different waste types in your total deposits.
  - **Withdrawal Requests:** Conveniently request cash withdrawals from your accumulated savings balance.
  - **Profile Management:** Update personal information and change your password as needed.
  - **Print Reports:** Generate and print PDF reports of your savings account activity and historical performance.

### For Collectors (Pengepul)

  - **Registration & Authentication:** Secure sign-up with NIK and login capabilities.
  - **Waste Pricing Management:** Set and adjust prices per kilogram (kg) for various waste categories (Organic, Inorganic – including Plastic, Paper, Metal, Glass, etc.).
  - **Deposit Validation:** Receive and validate customer waste deposit requests, updating their savings balance based on actual weight and current prices.
  - **Operational Analytics:** Access charts and reports detailing collected waste volume, distribution by waste type, and overall operational performance.
  - **Profile Management:** Update personal information and change your password.
  - **Print Reports:** Generate and print PDF reports of your collection history and operational performance.

-----

## Technology Stack

  - **Frontend:** Flutter (Dart)
  - **Backend:** Firebase (Authentication, Cloud Firestore)
  - **State Management:** Provider
  - **Charting:** `fl_chart`
  - **PDF Generation:** `pdf`, `path_provider`, `open_filex`

-----

## Installation Guide

Follow these steps to get the Bank Sampah App up and running on your local machine.

### Prerequisites

  - [**Flutter SDK**](https://flutter.dev/docs/get-started/install) (Stable channel recommended)
  - [**Firebase CLI**](https://firebase.google.com/docs/cli)
  - **Node.js** (required for Firebase CLI)
  - A **Google account** to access the Firebase Console.

### Step 1: Clone the Repository

```bash
git clone https://github.com/Dika1485/bank_sampah_app.git
cd bank_sampah_app
```

### Step 2: Firebase Project Setup

1.  **Create a Firebase Project:**
      - Go to the [**Firebase Console**](https://console.firebase.google.com/).
      - Click "Add project" and follow the instructions to create a new project.
2.  **Add Android and iOS Apps:**
      - In your Firebase project, add an **Android app**. Provide your Android package name (you'll find this as `applicationId` in `android/app/build.gradle`).
      - **Crucially, provide your SHA-1 debug signing certificate.** You can get this by running:
          - **macOS/Linux:** `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
          - **Windows:** `keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android`
      - **Download `google-services.json`** and place it in your Flutter project's `android/app/` directory.
      - Add an **iOS app**. Provide your iOS bundle ID (you'll find this in Xcode or `ios/Runner.xcodeproj/project.pbxproj`).
      - **Download `GoogleService-Info.plist`** and place it in `ios/Runner/` (ensure it's added to the Runner target in Xcode).
3.  **Enable Firebase Services:**
      - In the Firebase Console, navigate to:
          - **Authentication:** Go to "Build" \> "Authentication" \> "Sign-in method" and enable "Email/Password."
          - **Firestore Database:** Go to "Build" \> "Firestore Database" and create a database (start in test mode for development).
          - **Storage:** Go to "Build" \> "Storage" and create a storage bucket (Anda mungkin melihat pesan tentang *upgrade*, namun untuk versi ini tanpa unggah KTP, itu tidak terlalu kritis kecuali Anda membutuhkan penyimpanan gambar/file lain).
4.  **Configure Firebase in Flutter:**
      - Open your terminal in the root of your Flutter project.
      - Run: `flutterfire configure`
      - Follow the prompts to select your Firebase project and desired platforms. This command automatically generates the `lib/firebase_options.dart` file, containing your Firebase configuration.
5.  **Set up Firebase Security Rules:**
      - In the Firebase Console, go to **Firestore Database \> "Rules"** and **Firebase Storage \> "Rules"**.
      - Implement security rules as outlined in your project's security documentation (atau seperti yang dibahas sebelumnya) untuk melindungi data Anda. **Ingatlah untuk menyesuaikan aturan "mode uji" untuk lingkungan produksi.**

### Step 3: Install Dependencies

From your project's root directory in the terminal, run:

```bash
flutter pub get
```

### Step 4: Configure Application Icons

1.  **Prepare your icon image:** Place your preferred app icon (e.g., `app_icon.png`, ideally 1024x1024px with a transparent background) in the `assets/icon/` directory within your project.
2.  **Update `pubspec.yaml`:** Make sure the `flutter_launcher_icons` package is configured and your assets path is correctly declared:
    ```yaml
    # ... (other dev_dependencies)
    flutter_launcher_icons: "^0.13.1" # Ensure this version or compatible is present

    flutter_launcher_icons:
      android: "launcher_icon"
      ios: true
      image_path: "assets/icon/app_icon.png" # Adjust if your file name/path differs
      min_sdk_android: 21

    flutter:
      uses-material-design: true
      assets:
        - assets/
        - assets/icon/ # Ensures all files in this directory are accessible
    ```
3.  **Generate icons:**
    ```bash
    flutter pub run flutter_launcher_icons
    ```

### Step 5: Run the Application

```bash
flutter run
```

This command will launch the application on your connected device or emulator.

-----

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

-----