# 🚗 AutoCare Pro (Garage App)

AutoCare Pro is a comprehensive Garage Management System built with **Flutter** and **Firebase**. It streamlines operations for vehicle repair workshops, managing everything from job cards and customers to inventory and billing.

## ✨ Features

### 👥 **User Roles & Permissions**
- **Admin:** Full access to all features (Staff management, Reports, Settings, etc.).
- **Mechanic:** View job cards, update service status, check inventory.
- **Customer:** View vehicle history, service status, invoices, and profile.

### 🛠️ **Core Modules**
- **Dashboard:** Real-time overview of active jobs, revenue, and customer stats.
- **Job Cards:** Create, track, and manage service requests with detailed statuses.
- **Customer Management:** Add and manage customer profiles and their vehicles.
- **Vehicle Management:** Track vehicle details, service history, and ownership.
- **Inventory System:** Manage spare parts, stock levels, and pricing.
- **Billing & Invoicing:** Generate professional PDF invoices and track payments.
- **Reports:** Visual analytics for income, active jobs, and mechanic performance.

### 🔐 **Security & Authentication**
- Secure Email/Password Authentication via Firebase Auth.
- Role-based data access using Firestore Security Rules.
- Admin-controlled user registration (Public sign-up is disabled).

## 📱 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Backend:** [Firebase](https://firebase.google.com/)
  - Authentication
  - Cloud Firestore (NoSQL Database)
  - Firebase Storage
- **State Management:** [Flutter Riverpod](https://riverpod.dev/)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
- **Utilities:**
  - `pdf` & `printing` for Invoice generation.
  - `google_fonts` for typography.
  - `intl` for date/time formatting.
  - `flutter_svg` for vector assets.

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- Valid `firebase_options.dart` file configured for your Firebase project.

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Garage_App
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
lib/
├── core/            # Utils, formatting, permissions, routing
├── data/            # Models, Repositories, Firebase services
├── presentation/    # UI Layer
│   ├── screens/     # Application screens (grouped by feature)
│   ├── widgets/     # Reusable UI components
│   └── controllers/ # Riverpod providers/controllers
└── main.dart        # Application entry point
```

## 🎨 UI/UX

The app features a modern, responsive design with:
- **Clean Architecture:** Separation of data and UI layers.
- **Responsive Layouts:** Optimized for various screen sizes.
- **Dark/Light Mode:** System-aware theme support.

## 🛡️ License

This project is licensed under the MIT License - see the LICENSE file for details.
