import 'package:capstone/pages/admin_dashboard.dart';
import 'package:capstone/pages/guest_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:capstone/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import AdminService untuk login Firestore
import 'package:capstone/admin_service.dart';
import 'package:capstone/data/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone/auth/admin_auth_service.dart'; // TAMBAHKAN INI

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          height: 2 * 800,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start, // tetap start
            children: [
              const SizedBox(height: 20),
              Center(
                // Center khusus buat logo biar tetap di tengah
                child: SvgPicture.asset(
                  'assets/majid.svg',
                  width: 1000,
                ),
              ),
              const Spacer(flex: 3),

              // Mulai dibungkus Padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.black54,
                    ),
                    const SizedBox(height: 2),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GuestDashboard()),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5.0, vertical: 10.0),
                        child: Text(
                          'Masuk sebagai Tamu',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final AdminAuthService _adminAuthService = AdminAuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Username dan password tidak boleh kosong"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("Mencoba login dengan email: $email"); // Debug log
      // Pertama coba login dengan Firestore admin collection
      Admin? admin = await AdminService.verifyAdminLogin(email, password);
      bool loginSukses = await _adminAuthService.signInAdmin(email, password);

      print("Hasil admin dari Firestore: $admin");
      print(
          "Hasil login admin dari AdminAuthService: $loginSukses"); // Debug log

      if (loginSukses) {
        print("Admin login berhasil melalui AdminAuthService.");
        if (admin != null) {
          print("Admin ditemukan di Firestore: ${admin.name}"); // Debug log

          // PERBAIKAN: Simpan status login ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isAdminLoggedIn', true);
          await prefs.setString('adminEmail', admin.email);
          await prefs.setString('adminName', admin.name);
        }
        // Jika admin ditemukan di Firestore, arahkan ke AdminDashboard
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Login berhasil sebagai ${admin?.name}"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Delay sedikit untuk memastikan SnackBar tampil
          await Future.delayed(Duration(milliseconds: 500));

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
            (route) => false,
          );
        }
        return;
      }

      print(
          "Admin tidak ditemukan di Firestore, mencoba Firebase Auth"); // Debug log

      // Jika tidak ditemukan di Firestore, coba dengan Firebase Auth
      try {
        await AuthService().signInWithEmailAndPassword(email, password);

        print("Login Firebase Auth berhasil"); // Debug log

        // PERBAIKAN: Untuk Firebase Auth, tidak perlu set SharedPreferences karena
        // AdminDashboard sudah handle Firebase Auth state

        // Jika login Firebase Auth sukses, arahkan ke AdminDashboard
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login berhasil dengan Firebase Auth"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Delay sedikit untuk memastikan SnackBar tampil
          await Future.delayed(Duration(milliseconds: 500));

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        print("Firebase Auth error: ${e.message}"); // Debug log
        // Jika Firebase Auth juga gagal, tampilkan pesan error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Login gagal: Email atau password salah"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print("Error dalam login: $e"); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login gagal: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff8ABEC5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 2,
                child: SvgPicture.asset(
                  'assets/majid.svg',
                  height: 150,
                ),
              ),
              const Text(
                "Login",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 34, 34, 34)),
              ),
              // const Spacer(flex: 3),
              const SizedBox(height: 17),
              Container(
                // padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0x50FFFDFD),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(31, 64, 64, 64),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0x50FFFDFD),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(31, 64, 64, 64),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "lupa password?",
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (mounted) {
                            setState(() => _isLoading = true);
                          }
                          try {
                            await _login();
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  // _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
