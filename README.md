# LandSnap

LandSnap is a Flutter-based mobile application developed as a Final Year Project (FYP) for visualizing and managing land parcel information using interactive maps.

The system allows administrators to manage land polygons while users can explore land plots through an interactive map interface.

---

## Features

• Firebase Authentication (Login / Signup)  
• Role-based access control (Admin / User)  
• Interactive map visualization using Flutter Map  
• Land parcel polygon rendering  
• Real-time data from Firestore  
• Admin land management system  
• Polygon editing and viewing tools  

---

## Technologies Used

Flutter (Dart)

Firebase
- Firebase Authentication
- Cloud Firestore
- Firebase Core

Maps
- flutter_map
- OpenStreetMap tiles

Other Packages
- latlong2
- flutter_map_animations
- http

---

## Project Architecture

lib/
│
├── auth/
│   ├── auth_gate.dart
│   ├── auth_service.dart
│   ├── login_screen.dart
│   └── signup_screen.dart
│
├── admin/
│   ├── admin_dashboard.dart
│   ├── add_land_screen.dart
│   ├── view_land_screen.dart
│   └── edit_polygon_screen.dart
│
├── user/
│   ├── map_view.dart
│   ├── about_screen.dart
│   └── font_size_preview.dart
│
├── models/
│   └── map_polygon_feature.dart
│
├── services/
│   ├── land_repository.dart
│   ├── map_data_service.dart
│   └── geojson_migrator.dart
│
└── main.dart

---

## Setup Instructions

1 Install Flutter

https://flutter.dev/docs/get-started/install

2 Clone the repository

git clone https://github.com/YOUR_USERNAME/land_snap.git

3 Navigate into project

cd land_snap

4 Install dependencies

flutter pub get

5 Run the application

flutter run

---

## Firebase Configuration

The project uses Firebase for authentication and database services.

You must configure:

google-services.json for Android  
GoogleService-Info.plist for iOS

These files are not included in the repository for security reasons.

---

## Project Purpose

This application was developed as part of a Final Year Project to demonstrate the integration of mobile GIS mapping with cloud-based data storage using Flutter and Firebase.

---

## Author

Muhammad Ghani  
BS Software Engineering