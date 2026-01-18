# � AutoCare Pro - Master Project Manual

**Version 1.0.0** | **Last Updated:** January 18, 2026

Welcome to the **AutoCare Pro (Garage App)** documentation hub. This manual is the "Single Source of Truth" for the entire project, covering everything from initial setup and architecture to daily operations and troubleshooting.

---

## 📑 Table of Contents

1.  **[Project Overview](#1-project-overview)**
    *   Core Features
    *   User Roles
2.  **[Technical Architecture](#2-technical-architecture)**
    *   Tech Stack
    *   Folder Structure
    *   Data Schema (Firestore)
    *   Security Model
3.  **[Installation & Setup](#3-installation--setup)**
    *   Prerequisites
    *   Step-by-Step Installation
    *   Firebase Configuration
4.  **[User Manual (Operations)](#4-user-manual-operations)**
    *   Staff Management (Admin)
    *   Job Card Workflow
    *   Billing & Invoicing
    *   Inventory Control
5.  **[Troubleshooting Guide](#5-troubleshooting-guide)**
    *   Firestore Connection Issues
    *   Common Error Codes
6.  **[Code Quality & Maintenance](#6-code-quality--maintenance)**
    *   Recent Optimizations
    *   Linting & Testing

---

## 1. 🎯 Project Overview

**AutoCare Pro** is a comprehensive, production-grade Garage Management System designed to digitize automotive workshops. It replaces paper job cards with a real-time, cloud-based solution.

### 🌟 Core Features
*   **📱 Multi-Platform:** Runs on Android, iOS, and Web.
*   **🛠️ Service Tracking:** End-to-end lifecycle management of vehicle repairs (`Received` → `Inspection` → `In Progress` → `Completed` → `Delivered`).
*   **💰 Financials:** Automated invoicing, tax calculation, and daily income reports.
*   **📦 Inventory Smart-Link:** Automatically deducts spare parts from stock when added to job cards.
*   **🔔 Real-time Alerts:** Low stock warnings and job status updates.

### 👥 User Roles & Permissions

| Role | Access Level | Responsibilities |
| :--- | :--- | :--- |
| **🛡️ ADMIN** | **Full Access** | Manage staff, view financial reports, configure settings, delete records. |
| **🔧 MECHANIC** | **Operational** | View assigned jobs, update service status, request parts from inventory. |
| **👤 CUSTOMER** | **Read-Only** | View vehicle service history, download invoices, check current status. |

---

## 2. 🏗️ Technical Architecture

### 🛠️ Technology Stack
*   **Framework:** [Flutter](https://flutter.dev/) (Dart 3.x)
*   **State Management:** [Riverpod 2.x](https://riverpod.dev/) (Providers, Consumers, AsyncValue)
*   **Navigation:** [GoRouter](https://pub.dev/packages/go_router) (Declarative routing with auth guards)
*   **Backend:** [Firebase Authentication](https://firebase.google.com/docs/auth) & [Cloud Firestore](https://firebase.google.com/docs/firestore)
*   **UI Components:** Material 3 Design System, Google Fonts, Flutter SVG

### 📂 Folder Structure (Clean Architecture)
```bash
lib/
├── core/                   # Global utilities
│   ├── permissions/        # Role-based access logic (PermissionService)
│   ├── router/             # GoRouter configuration
│   └── theme/              # AppTheme & color palette
├── data/                   # Data Layer
│   ├── models/             # Dart Data Classes (fromJson/toJson)
│   └── repositories/       # Firestore interactions (Repository Pattern)
└── presentation/           # UI Layer
    ├── controllers/        # Logical controllers (Riverpod Notifiers)
    ├── screens/            # Full-page widgets (Dashboard, JobCardList, etc.)
    └── widgets/            # Reusable UI components (buttons, cards, dialogs)
```

### 🗺️ Data Schema (Firestore)

#### **1. Users Collection (`users`)**
| Field | Type | Description |
| :--- | :--- | :--- |
| `uid` | String | Unique ID (from Auth) |
| `role` | String | `admin`, `mechanic`, or `customer` |
| `email` | String | Login email |
| `status` | String | `Active` or `Inactive` |

#### **2. Job Cards (`job_cards`)**
| Field | Type | Description |
| :--- | :--- | :--- |
| `vehicleId` | String | Link to vehicle |
| `status` | String | Current workflow stage |
| `mechanicIds` | List | IDs of assigned mechanics |
| `services` | List | Array of service objects |
| `parts` | List | Array of parts used (auto-deducted) |

#### **3. Inventory (`inventory`)**
| Field | Type | Description |
| :--- | :--- | :--- |
| `sku` | String | Stock Keeping Unit |
| `quantity` | Number | Current stock level |
| `minLevel` | Number | Low stock alert threshold |
| `buyPrice` | Number | Cost price |
| `sellPrice` | Number | Retail price (auto-filled in jobs) |

---

## 3. � Installation & Setup

### Prerequisites
1.  **Flutter SDK:** [Install Here](https://docs.flutter.dev/get-started/install)
2.  **Git:** [Install Here](https://git-scm.com/)
3.  **VS Code:** with Flutter & Dart extensions

### Step-by-Step Installation

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/your-repo/garage-app.git
    cd Garage_App
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration**
    *   This project relies on `firebase_options.dart`.
    *   Ensure you have access to the Firebase project or run `flutterfire configure` to connect your own.

4.  **Run the App**
    ```bash
    # For Android
    flutter run -d android

    # For Web (Development only)
    flutter run -d chrome
    ```

---

## 4. 📖 User Manual (Operations)

### � Staff Management (Admins Only)
1.  Navigate to **Settings** > **Staff & Mechanics**.
2.  Click **+ Add Staff**.
3.  **Vital:** Select the correct Role.
    *   *Note: Mechanics need "Skills" and "Experience" fields filled out.*
4.  Use the **Auto-Generate Password** button (`🔄`) to create a secure password.
5.  **Copy** the password and share it securely with the employee.

### 🛠️ Job Card Workflow
1.  **Creation:** Click **+ New Job Card** on Dashboard.
2.  **Vehicle:** Select existing vehicle or add new one instantly.
3.  **Inspection:** Mechanic takes photos and notes initial complaints.
4.  **Service:** Add "General Service" or specific repairs from the catalog.
5.  **Parts:** Add oil, filters, etc. *Stock is reserved immediately.*
6.  **Close:** When finished, mark as `Completed`. This triggers the Billing stage.

### 🧾 Billing & Invoicing
1.  Detailed invoices are auto-generated from Job Cards.
2.  Go to **Billing** tab to view pending payments.
3.  Click **Generate PDF** to create a professional invoice with tax breakdown.
4.  Record payments (Cash/Card/Online) to mark invoice as `PAID`.

---

## 5. 🆘 Troubleshooting Guide

### 🔴 Firestore Connection Error
**Symptoms:** Infinite loading spinner or `UNAVAILABLE` error.
**Fixes:**
1.  **Check Internet:** Ensure the device has active WiFi/Data.
2.  **Emulator DNS:** on Android Emulator, run `flutter clean` then restart with `emulator -dns-server 8.8.8.8`.
3.  **Security Rules:** Check Firebase Console Rules tab. Standard rule:
    ```javascript
    allow read, write: if request.auth != null;
    ```

### 🔨 Build Errors & Fixes
*   **"Version Mismatch"**: Run `flutter pub upgrade`.
*   **"CocoaPods Error" (iOS)**: `cd ios && pod install && cd ..`
*   **"Async Gap Warning"**: Ensure `if (mounted)` checks are present before using `context` after an `await`.

---

## 6. 📊 Code Quality & Maintenance

### Recent Optimizations (Jan 18, 2026)
We conducted a massive code cleanup sprint:
*   ✅ **Fixed 52 Deprecations:** Migrated `withOpacity` to `withValues`.
*   ✅ **Secured Logging:** Replaced 31 `print()` calls with `debugPrint()`.
*   ✅ **UI Polish:** Modernized Radio buttons in Settings.
*   ✅ **Bug Fixes:** Resolved 7 async context gaps.

### Running Tests
To ensure system stability, run the test suite before every deployment:
```bash
flutter test
```
*Current Status: All tests passing.*

---

## 7. 📁 Project Reports & Resources

Useful technical reports and scripts generated during development:

*   **[Command Cheat Sheet](./COMMANDS.md)** (Essential CLI commands)
*   **[Analysis Report](./ANALYSIS_REPORT.md)** (Initial codebase health check)
*   **[Fix Summary](./FINAL_FIX_SUMMARY.md)** (Details of 74+ issues resolved)
*   **[Opacity Fix Script](./fix_with_opacity.py)** (Python automation script)
*   **[Architecture Docs](./ARCHITECTURE_DOCUMENTATION.md)** (Deep technical dive)

---

**End of Documentation**  
*For further assistance, please contact the development team lead.*
