# MAJID-App 🕌

**Al-Waraq Tlogomas Mosque Management Mobile Application**

A multiplatform mobile application developed using Flutter to automate publication processes and management of Al-Waraq Tlogomas Mosque, Malang City, East Java, Indonesia.

## 📱 About the Project

MAJID-App is a digital solution designed to address traditional mosque management challenges, focusing on:
- Transparency in inventory and donation management
- Efficient communication between mosque administrators and congregation
- Digitalization of item borrowing processes
- Management of activity schedules and religious studies

## 👥 Development Team

| Name | Role |
|------|------|
| Mochammad Rasya Dimas Chamdani | Developer |
| M. Bintang Nur | Researcher |
| Ahmad Nabih Baril Hilmy | PM & SQA |
| Erick Prakoso | UI/UX Designer |
| Dhiyaurrahman Fathu Abrari | UI/UX Designer |

## 🏗️ Technology Stack

- **Framework**: Flutter
- **Language**: Dart
- **Platform**: Android & iOS (Multiplatform)
- **Design Tool**: Figma
- **Methodology**: Design Thinking (Empathize → Define → Ideate → Prototype → Test)

## 🌟 Key Features

### 👨‍💼 For Mosque Administrators (Admin & Super Admin)

#### 📊 Dashboard
- Mosque statistics overview
- Latest notifications
- Activity monitoring

#### 📦 Inventory Management
- Add, edit, and delete inventory items
- Digital labeling system
- Monitor item condition and status
- Visual inventory history
- Usage monitoring dashboard

#### 🤝 Borrowing Management
- Review and approve borrowing requests
- Real-time borrowing status tracking
- Automatic return reminders
- Item condition documentation (before/after)
- Digital approval system

#### 📅 Study Schedule & Imam Management
- Manage religious study schedules
- Set imam/preacher assignments
- Automatic schedule publication
- Schedule change notifications

#### 💰 Donation Management
- Digital donation recording
- Financial transparency reports
- Payment method tracking
- Automated financial reports

#### 👤 User Management
- Manage admin and staff accounts
- Role-based access system
- Add new administrators

### 🕌 For Congregation Members (Guest Users)

#### 📱 Congregation Dashboard
- Latest mosque information
- Important announcements
- Activity updates

#### 📋 Item Borrowing
- Online borrowing forms
- ID card document upload
- Request status tracking
- Borrowing history

#### 📖 Activity Schedule
- View current study schedules
- Information about assigned imams
- Special activity notifications
- Prayer reminders

#### 💡 Additional Features
- Community discussion forum
- Anonymous complaint system
- Congregation suggestions
- Transparent information access

## 🎯 Problems Solved

1. **Ineffective Information Distribution**
   - ❌ Delayed information via WhatsApp/verbal announcements
   - ✅ Real-time push notifications in the app

2. **Manual Inventory Management**
   - ❌ Lost/misplaced items, manual recording
   - ✅ Digital system with labeling and tracking

3. **Lack of Donation Transparency**
   - ❌ Manual cash recording, error-prone
   - ✅ Transparent digital system with reports

4. **Financial Reporting Difficulties**
   - ❌ Time-consuming manual processes
   - ✅ Automated centralized reports

## 🚀 Installation

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or Emulator

### Installation Steps

1. **Clone Repository**
   ```bash
   git clone https://sourceforge.net/projects/majid-app/
   cd majid-app
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Configuration**
   ```bash
   # Create .env file for database and API configuration
   cp .env.example .env
   ```

4. **Run Application**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

## 📂 Project Structure

```
majid-app/
├── lib/
│   ├── models/          # Data models
│   ├── screens/         # UI screens
│   ├── widgets/         # Reusable widgets
│   ├── services/        # API services
│   ├── utils/           # Utilities
│   └── main.dart        # Entry point
├── assets/
│   ├── images/          # Image assets
│   └── fonts/           # Font assets
├── test/                # Unit tests
└── pubspec.yaml         # Dependencies
```

## 🔐 User Roles & Permissions

### Super Admin
- Full access to all features
- Admin and user management
- System configuration

### Admin
- Inventory management
- Borrowing approval
- Schedule and donation management

### Congregation (Guest)
- View public information
- Submit borrowing requests
- Access activity schedules

## 📱 Screenshots & Demo

### Figma Prototype
[Figma Prototype Link](https://www.figma.com/proto/pDAhldtyQH6RlAL2YkuUiz/UI-UX-Majid-FIX?node-id=0-1&p=f&viewport=-1447%2C-1843%2C0.05&t=zVfXMLtrUiYbMJMF-0&scaling=scale-down&content-scaling=fixed&starting-point-node-id=4058%3A3181&show-proto-sidebar=1)

### Presentation Video
[Demo Video](https://drive.google.com/drive/folders/1yHA-Q0U9TeEZKMw7hWJ4pSx3WsmmQ8-z?usp=sharing)

## 🧪 Testing

The application has undergone usability testing with 8 testing scenarios:

✅ Admin & Super Admin Login  
✅ Inventory Management  
✅ Study Schedule Management  
✅ Item Borrowing System  
✅ Donation Management  
✅ Congregation User Experience  
✅ Application Navigation  
✅ Admin Management  

**Testing Results**: All features run smoothly with high user satisfaction levels, particularly the item borrowing feature which was rated as highly convenient.

## 🔧 Development Process

This project was developed using **Design Thinking Methodology**:

1. **Empathize** - Interviews with mosque administrators and congregation
2. **Define** - Problem identification using "How Might We" method
3. **Ideate** - Creating user flows, information architecture, wireframes
4. **Prototype** - Develop interactive prototype in Figma
5. **Test** - Usability testing with real users

## 🎯 Future Development Features

- [ ] Automatic prayer time schedule
- [ ] Payment gateway integration for donations
- [ ] Advanced push notifications
- [ ] Real-time chat feature
- [ ] Detailed analytics and reporting
- [ ] Cloud data backup and sync

## 🏢 Associated Institutions

- **Development Location**: Faculty of Computer Science, Universitas Brawijaya
- **Client**: Al-Waraq Mosque, Tlogomas, Malang City, East Java
- **City**: Malang, East Java, Indonesia

## 📞 Contact & Support

For questions, bug reports, or development suggestions:
- **Repository & Product**: [SourceForge](https://sourceforge.net/projects/majid-app/)
- **Location**: Malang, East Java, Indonesia

## 📄 License

This project was developed for academic purposes and community service. Please contact the development team for more information regarding usage and distribution.

---

**MAJID-App** - Advancing Indonesian Mosque Digitalization 🇮🇩

*Developed with ❤️ by Students of Faculty of Computer Science, Universitas Brawijaya*
