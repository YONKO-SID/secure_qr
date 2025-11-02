# Secure QR Gateway

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Status](https://img.shields.io/badge/status-in_development-orange.svg)](https://github.com/YONKO-SID/secure_qr)

A privacy-first QR code scanner built with Flutter that acts as a security checkpoint to protect you from malicious links and other QR-based threats.

<!-- Add a GIF of the app in action here -->

## Core Concept

Native camera apps typically open QR code links instantly, giving you no chance to see where you're going. This exposes you to phishing, malware, and other attacks. 

**Secure QR Gateway** solves this by intercepting the QR code's content. It sends any found URLs to a secure backend for analysis *before* anything is opened, showing you a clear safety verdict and the full, final destination URL. You are always in control.

## ✨ Key Features

-   **Real-time QR Scanning:** High-performance scanning using the device's camera.
-   **Backend-Powered Analysis:** Leverages serverless functions for URL expansion and threat checking.
-   **Clear Security Verdicts:** Presents a simple, color-coded result (SAFE, DANGEROUS, WARNING) before redirecting.
-   **Full URL Transparency:** Always shows you the complete, un-shortened destination URL, so there are no surprises.

## 🛠️ Technology Stack

-   **Frontend:** Flutter
-   **Backend:** Firebase (Cloud Functions & Firestore for caching)
-   **Languages:** Dart (Frontend), Python (Backend)
-   **Threat Intelligence:** Google Web Risk API (with plans to add more)

## 🚦 Project Status

This project is currently under active development. The core Flutter UI for scanning and displaying results is functional. The immediate next step is to integrate the Firebase backend to replace the placeholder logic.

## 🚀 Getting Started

### Prerequisites

-   [Flutter SDK](https://flutter.dev/docs/get-started/install)
-   [Node.js](https://nodejs.org/en/) (to run the Firebase CLI)
-   [Firebase CLI](https://firebase.google.com/docs/cli#install_the_firebase_cli)
-   A Google Account for Firebase

### Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/YONKO-SID/secure_qr.git
    cd secure_qr
    ```

2.  **Set up the Firebase Project:**
    -   Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
    -   Add a new **Flutter** application to your project.
    -   In your terminal, run `flutterfire configure` and select your new project. This will automatically generate the `lib/firebase_options.dart` file required to connect your app to Firebase.

3.  **Set up the Backend:**
    -   In the terminal, log into Firebase with `firebase login`.
    -   Initialize Firebase services by running `firebase init`. Select **Firestore** and **Functions**. Choose **Python** as the language for Cloud Functions.
    -   You will need to obtain a **Google Web Risk API Key** from the Google Cloud Console and add it to the backend configuration when prompted.

4.  **Install Dependencies & Run:**
    ```bash
    flutter pub get
    flutter run
    ```

## 🗺️ Roadmap

The vision for this project is to create a multi-layered defense against QR-based threats.

-   [x] **Phase 1: Core Prototype**
    -   [x] Flutter UI for scanning and results.
    -   [x] Basic navigation flow.

-   [ ] **Phase 2: Firebase Integration (In Progress)**
    -   [ ] Implement Python Cloud Function for URL analysis using Google Web Risk API.
    -   [ ] Connect Flutter app to the Firebase Cloud Function.
    -   [ ] Implement Firestore for caching analysis results.

-   [ ] **Phase 3: Enhanced Intelligence**
    -   [ ] Integrate additional threat APIs (e.g., PhishTank, VirusTotal).
    -   [ ] Aggregate results from multiple APIs for a more robust verdict.

-   [ ] **Phase 4: Proactive Defense (Future)**
    -   [ ] Research and develop a custom threat database using web scraping and ML.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome. Feel free to check the [issues page](https://github.com/YONKO-SID/secure_qr/issues) if you want to contribute.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.