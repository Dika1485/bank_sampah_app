# SIMARU: Mawar Biru Waste Bank Information System

## Project Overview

**SIMARU** (*Sistem Informasi Bank Sampah Mawar Biru*) is a **Flutter** mobile application designed to automate and streamline waste management and recycling processes for **Customers (Nasabah)** and **Waste Bank Officers/Treasurers (Petugas/Bendahara)**. The application promotes environmental sustainability by providing a **transparent, structured, and efficient** digital system for managing waste savings and turning trash into economic value.

-----

## Key Features

### For Nasabah (Customers)

  * **Registration & Authentication:** Secure sign-up using the **NIK (National Identity Number)** and robust login functionality.
  * **Digital Waste Savings:** Track your current Rupiah balance and view a detailed history of all deposits and withdrawals.
  * **Deposit Request:** Easily initiate waste deposit requests, specifying waste types and estimated weights.
  * **Contribution Analytics:** Visualize your contributions with insightful charts (using `fl_chart`), showing the percentage distribution of different waste types.
  * **Withdrawal Requests:** Conveniently request cash withdrawals from your accumulated savings balance.
  * **PDF Reports:** Generate and print PDF reports of your savings account activity and historical performance.

### For Petugas / Bendahara (Officers/Treasurers)

  * **Deposit Validation:** Receive and validate customer waste deposit requests, updating their savings balance based on actual weight and current prices.
  * **Waste Pricing Management:** Set and adjust prices per kilogram (kg) for various waste categories (Plastic, Paper, Metal, Glass, etc.).
  * **Operational Analytics:** Access charts and reports detailing collected waste volume, distribution by waste type, and overall operational performance.
  * **Product & Event Management:** Manage the catalog of recycled products (for display/education only) and community event schedules, including image uploads to Cloudinary.
  * **Reporting:** Generate and print PDF reports of collection history and operational performance.

-----

## Technology Stack

  * **Frontend:** Flutter (Dart)
  * **Backend & DB:** Firebase (Authentication, Cloud Firestore)
  * **Image Storage:** **Cloudinary** (For storing Product and Event images)
  * **State Management:** Provider
  * **Charting:** `fl_chart`
  * **PDF Generation:** `pdf`, `path_provider`, `open_filex`

-----

## Installation Guide

Follow these steps to get the SIMARU application up and running on your local machine.

### Prerequisites

  * [**Flutter SDK**](https://flutter.dev/docs/get-started/install) (Stable channel recommended)
  * [**Firebase CLI**](https://firebase.google.com/docs/cli)
  * **Node.js** (required for Firebase CLI)
  * A **Google account** for Firebase Console access.
  * A **Cloudinary account** (for image storage).

### Step 1: Clone the Repository

```bash
git clone https://github.com/Dika1485/bank_sampah_app.git
cd bank_sampah_app
```

### Step 2: Firebase & Cloudinary Setup

#### A. Firebase Configuration

1.  **Create a Firebase Project:** Create a new project in the [**Firebase Console**](https://console.firebase.google.com/).
2.  **Add Apps:** Add both **Android** and **iOS** apps. Ensure you provide the **Android package name** and the **SHA-1 debug signing certificate** (crucial for Authentication).
3.  **Download Config Files:**
      * Download **`google-services.json`** and place it in the `android/app/` directory.
      * Download **`GoogleService-Info.plist`** and place it in `ios/Runner/`.
4.  **Enable Services:**
      * **Authentication:** Enable **Email/Password**.
      * **Cloud Firestore:** Create a database (start in test mode for development).
5.  **Configure FlutterFire:**
    ```bash
    flutterfire configure
    ```
    (This command generates `lib/firebase_options.dart`.)
6.  **Security Rules:** Review and implement strict security rules in **Firestore Database \> "Rules"** to protect sensitive data like NIK and balances.

#### B. Cloudinary Configuration

1.  **Get Credentials:** Log into your Cloudinary account and note your **Cloud Name**, **API Key**, and **API Secret**.
2.  **Integration:** Input these credentials into the appropriate configuration file or environment variables within your Flutter project to authorize image uploads.

### Step 3: Install Dependencies

From your project's root directory in the terminal, run:

```bash
flutter pub get
```

### Step 4: Configure Application Icons (Optional)

1.  **Prepare Icon:** Place your app icon (e.g., `app_icon.png`) in `assets/icon/`.
2.  **Generate Icons:**
    ```bash
    flutter pub run flutter_launcher_icons
    ```

### Step 5: Run the Application

```bash
flutter run
```

The application will launch on your connected device or emulator.

-----

## License

This project is licensed under the MIT License. See the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.