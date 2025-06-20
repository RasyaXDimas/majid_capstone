import 'package:capstone/pages/admin_dashboard.dart';
import 'package:capstone/pages/sign_in.dart';
import 'package:capstone/pages/splash_screen.dart';
// Remove: import 'package:firebase_auth/firebase_auth.dart'; // We're replacing its direct usage for admins
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:capstone/supabase_service.dart';

// Import the new admin auth service
import 'package:capstone/auth/admin_auth_service.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';
  await SupabaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Navigasi Flutter',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // SplashScreen will handle the initial navigation logic
    );
  }
}

// AuthWrapper now uses AdminAuthService
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AdminAuthService _adminAuthService = AdminAuthService(); // Instance singleton

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('[AuthWrapper] initState: Creating AuthWrapper. AdminAuthService instance: $_adminAuthService');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('[AuthWrapper] build: Building AuthWrapper UI.');
    }
    return StreamBuilder<AdminUser?>(
      stream: _adminAuthService.adminAuthStateChanges,
      builder: (context, snapshot) {
        if (kDebugMode) {
          print('[AuthWrapper] StreamBuilder: ConnectionState: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, Data: ${snapshot.data}, HasError: ${snapshot.hasError}, Error: ${snapshot.error}');
        }

        // Fase 1: Menunggu koneksi stream atau data pertama
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (kDebugMode) {
            print('[AuthWrapper] StreamBuilder: Waiting for initial auth state from stream...');
          }
          // Penting: Tampilkan loading indicator SELAMA proses _checkInitialAuthState berjalan.
          // Jika _checkInitialAuthState cepat, state ini mungkin hanya terlihat sesaat atau tidak sama sekali.
          return const Scaffold(
            key: ValueKey("AuthWrapperLoading"), // Key untuk identifikasi widget jika perlu
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Fase 2: Stream aktif dan memiliki data (atau tidak ada data/null)
        if (snapshot.hasData && snapshot.data != null) {
          // AdminUser object diterima, artinya admin sudah login.
          if (kDebugMode) {
            print('[AuthWrapper] StreamBuilder: User is logged in (${snapshot.data}). Navigating to AdminDashboard.');
          }
          return const AdminDashboard(); // Pastikan AdminDashboard tidak melakukan navigasi yang konflik
        } else {
          // snapshot.data adalah null (bisa karena belum login, baru logout, atau error saat load state)
          // atau snapshot.hasError bernilai true.
          if (kDebugMode) {
            if (snapshot.hasError) {
               print('[AuthWrapper] StreamBuilder: Error in stream: ${snapshot.error}. Navigating to SignInPage.');
            } else {
               print('[AuthWrapper] StreamBuilder: User is not logged in (data is null). Navigating to SignInPage.');
            }
          }
          return const SignInPage(); // Pastikan SignInPage tidak melakukan navigasi yang konflik
        }
      },
    );
  }
}