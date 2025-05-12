// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, duplicate_ignore, deprecated_member_use, unused_element, use_rethrow_when_possible

import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart'; // Import the API service

// API Service global instance
final apiService =
    ApiService(baseUrl: 'http://10.0.2.2:5000'); // Use localhost for emulator

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Awesome Notifications
  await AwesomeNotifications().initialize(
    null, // Use default icon for notifications
    [
      NotificationChannel(
        channelKey: 'reminder_channel',
        channelName: 'Reminder Notifications',
        channelDescription: 'Channel for reminder notifications',
        importance: NotificationImportance.High,
        defaultColor: Colors.blue,
        ledColor: Colors.blue,
      ),
    ],
  );

  // Request permission to send notifications
  await AwesomeNotifications().requestPermissionToSendNotifications();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// Replace the current ThemeProvider and MyApp classes with this code:

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  // Define app color scheme
  static const Color primaryBlue = Color(0xFF1E88E5); // Material Blue 600
  static const Color primaryDarkBlue = Color(0xFF1565C0); // Material Blue 800
  static const Color accentOrange = Color(0xFFFF9800); // Material Orange 500
  static const Color lightOrange = Color(0xFFFFB74D); // Material Orange 300
  static const Color darkOrange = Color(0xFFEF6C00); // Material Orange 800
  static const Color backgroundLight =
      Color(0xFFF5F5F5); // Light gray background
  static const Color cardLight = Colors.white;
  static const Color backgroundDark = Color(0xFF303030);
  static const Color cardDark = Color(0xFF424242);

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class StatisticsProvider with ChangeNotifier {
  int _notesCount = 0;
  int _remindersCount = 0;
  int _signInCount = 0;
  int _appUsageCount = 0;

  int get notesCount => _notesCount;
  int get remindersCount => _remindersCount;
  int get signInCount => _signInCount;
  int get appUsageCount => _appUsageCount;

  StatisticsProvider() {
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    try {
      final token = await apiService.getToken();
      if (token != null) {
        final stats = await apiService.getStatistics();
        _notesCount = stats['NotesCount'] ?? 0;
        _remindersCount = stats['RemindersCount'] ?? 0;
        _signInCount = stats['SignInCount'] ?? 0;
        _appUsageCount = stats['AppUsageCount'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      print('Failed to load statistics: $e');
    }
  }

  Future<void> incrementNotesCount() async {
    _notesCount++;
    notifyListeners();
  }

  Future<void> incrementRemindersCount() async {
    _remindersCount++;
    notifyListeners();
  }

  Future<void> incrementSignInCount() async {
    try {
      await apiService.login(
          'your@email.com', 'password'); // Update with actual login
      _signInCount++;
      notifyListeners();
    } catch (e) {
      print('Failed to increment sign-in count: $e');
    }
  }

  Future<void> incrementAppUsageCount() async {
    try {
      await apiService.updateAppUsage();
      _appUsageCount++;
      notifyListeners();
    } catch (e) {
      print('Failed to increment app usage count: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final statisticsProvider = Provider.of<StatisticsProvider>(
      context,
      listen: false,
    );

    // Increment app usage counter when the app is launched
    statisticsProvider.incrementAppUsageCount();

    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true, // Enable Material 3 design
        // Primary color scheme
        primaryColor: ThemeProvider.primaryBlue,
        colorScheme: ColorScheme.light(
          primary: ThemeProvider.primaryBlue,
          secondary: ThemeProvider.accentOrange,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          surface: ThemeProvider.cardLight,
          background: ThemeProvider.backgroundLight,
        ),
        scaffoldBackgroundColor: ThemeProvider.backgroundLight,
        cardColor: ThemeProvider.cardLight,
        // AppBar theme
        appBarTheme: AppBarTheme(
          backgroundColor: ThemeProvider.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        // Button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeProvider.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ThemeProvider.primaryBlue,
            side: BorderSide(color: ThemeProvider.primaryBlue, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: ThemeProvider.primaryBlue,
          ),
        ),
        // Floating action button theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: ThemeProvider.accentOrange,
          foregroundColor: Colors.white,
        ),
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ThemeProvider.primaryBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIconColor: ThemeProvider.primaryBlue,
          suffixIconColor: Colors.grey,
        ),
        // Divider theme
        dividerTheme: DividerThemeData(
          color: Colors.grey[300],
          thickness: 1,
          space: 30,
        ),
        // Switch theme
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return ThemeProvider.accentOrange;
            }
            return Colors.grey;
          }),
          trackColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return ThemeProvider.lightOrange.withOpacity(0.5);
            }
            return Colors.grey.withOpacity(0.3);
          }),
        ),
        // Card theme
        cardTheme: CardTheme(
          color: ThemeProvider.cardLight,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: ThemeProvider.primaryBlue,
        colorScheme: ColorScheme.dark(
          primary: ThemeProvider.primaryBlue,
          secondary: ThemeProvider.accentOrange,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          surface: ThemeProvider.cardDark,
          background: ThemeProvider.backgroundDark,
        ),
        scaffoldBackgroundColor: ThemeProvider.backgroundDark,
        cardColor: ThemeProvider.cardDark,
        appBarTheme: AppBarTheme(
          backgroundColor: ThemeProvider.primaryDarkBlue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeProvider.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ThemeProvider.primaryBlue,
            side: BorderSide(color: ThemeProvider.primaryBlue, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: ThemeProvider.primaryBlue,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: ThemeProvider.accentOrange,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ThemeProvider.primaryBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIconColor: ThemeProvider.primaryBlue,
          suffixIconColor: Colors.grey,
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey[700],
          thickness: 1,
          space: 30,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return ThemeProvider.accentOrange;
            }
            return Colors.grey;
          }),
          trackColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return ThemeProvider.lightOrange.withOpacity(0.5);
            }
            return Colors.grey.withOpacity(0.3);
          }),
        ),
        cardTheme: CardTheme(
          color: ThemeProvider.cardDark,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/notes': (context) => const NotesScreen(),
        '/settings': (context) => const SettingsPage(),
        '/statistics': (context) => const StatisticsPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
    );
  }
}

class Note {
  final int? id;
  final String title;
  final String body;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Color textColor;
  final String fontFamily;
  final double fontSize;
  final NoteFormatting formatting;

  Note({
    this.id,
    required this.title,
    required this.body,
    this.createdAt,
    this.updatedAt,
    this.textColor = Colors.black,
    this.fontFamily = 'Default',
    this.fontSize = 16.0,
    NoteFormatting? formatting,
  }) : formatting = formatting ?? const NoteFormatting();

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['NoteID'],
      title: json['Title'],
      body: json['Body'],
      createdAt:
          json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt']) : null,
      updatedAt:
          json['UpdatedAt'] != null ? DateTime.parse(json['UpdatedAt']) : null,
      textColor:
          json['TextColor'] != null ? Color(json['TextColor']) : Colors.black,
      fontFamily: json['FontFamily'] ?? 'Default',
      fontSize: json['FontSize']?.toDouble() ?? 16.0,
      formatting: json['formatting'] != null
          ? NoteFormatting.fromJson(json['formatting'])
          : null,
    );
  }

  // Inside the Note class
  Map<String, dynamic> toJson() {
    return {
      'NoteID': id,
      'Title': title,
      'Body': body,
      'CreatedAt': createdAt?.toIso8601String(),
      'UpdatedAt': updatedAt?.toIso8601String(),
      'TextColor': textColor.value, // Save color as integer
      'FontFamily': fontFamily,
      'FontSize': fontSize,
      'formatting': formatting.toJson(),
    };
  }
}

class Reminder {
  final int? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final DateTime? createdAt;

  Reminder({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['ReminderID'],
      title: json['Title'],
      description: json['Description'],
      dateTime: DateTime.parse(json['DateTime']),
      createdAt:
          json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
    };
  }
}

class ReminderProvider with ChangeNotifier {
  List<Reminder> _reminders = [];
  bool _isLoading = false;

  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;

  ReminderProvider() {
    loadReminders();
  }

  Future<void> loadReminders() async {
    if (_isLoading) return; // Prevent concurrent loads

    _isLoading = true;
    notifyListeners();

    try {
      final token = await apiService.getToken();
      if (token != null) {
        final List<Map<String, dynamic>> reminderData =
            await apiService.getReminders();

        // Clear and repopulate the reminders list
        _reminders =
            reminderData.map((data) => Reminder.fromJson(data)).toList();

        // Sort reminders by date/time for consistency
        _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));

        print('Loaded ${_reminders.length} reminders from API');
        for (var reminder in _reminders) {
          print('Reminder: ${reminder.title} at ${reminder.dateTime}');
        }
      } else {
        print('Token is null, cannot load reminders');
      }
    } catch (e) {
      print('Failed to load reminders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    try {
      print('Adding reminder: ${reminder.title} at ${reminder.dateTime}');

      final result = await apiService.createReminder(
        reminder.title,
        reminder.description,
        reminder.dateTime,
      );

      final newReminder = Reminder.fromJson(result);
      print('Added reminder with ID: ${newReminder.id}');

      // Add to local list and sort
      _reminders.add(newReminder);
      _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      notifyListeners();
    } catch (e) {
      print('Failed to add reminder: $e');
      throw e; // Re-throw to allow UI to handle error
    }
  }

  Future<void> deleteReminder(int index) async {
    if (index < 0 || index >= _reminders.length) {
      print('Invalid reminder index: $index');
      return;
    }

    try {
      final reminder = _reminders[index];
      if (reminder.id != null) {
        print('Deleting reminder with ID: ${reminder.id}');
        await apiService.deleteReminder(reminder.id!);
      } else {
        print('Cannot delete reminder without ID');
      }

      _reminders.removeAt(index);
      notifyListeners();
    } catch (e) {
      print('Failed to delete reminder: $e');
      throw e; // Re-throw to allow UI to handle error
    }
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    checkExistingToken();
  }

  Future<void> checkExistingToken() async {
    final token = await apiService.getToken();
    if (token != null) {
      // If token exists, navigate to home page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statisticsProvider = Provider.of<StatisticsProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ThemeProvider.primaryBlue.withOpacity(0.8),
                ThemeProvider.primaryDarkBlue,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // App Logo and Title
                const SizedBox(height: 60),
                const Icon(
                  Icons.event_note,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'NotiTech',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

                const SizedBox(height: 40),

                // Login Form
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(
                                Icons.email,
                                color: ThemeProvider.primaryBlue,
                              ),
                              hintText: 'Enter your email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(
                                Icons.lock,
                                color: ThemeProvider.primaryBlue,
                              ),
                              hintText: 'Enter your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),

                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, '/forgot-password');
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: ThemeProvider.accentOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Error message
                          if (_errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 30),

                          // Sign in button
                          SizedBox(
                            width: double.infinity,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          ThemeProvider.primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() {
                                          _isLoading = true;
                                          _errorMessage = '';
                                        });

                                        try {
                                          // Attempt to login
                                          await apiService.login(
                                            _emailController.text,
                                            _passwordController.text,
                                          );

                                          // Increment sign-in count
                                          statisticsProvider
                                              .incrementSignInCount();

                                          // Navigate to home page
                                          Navigator.pushReplacementNamed(
                                              context, '/home');
                                        } catch (e) {
                                          setState(() {
                                            _errorMessage = e.toString();
                                          });
                                        } finally {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 20),

                          // Create new account button
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Create Account',
                                      style: TextStyle(
                                        color: ThemeProvider.accentOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Skip Login button
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.person_outline),
                              label: const Text('Continue as Guest'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ThemeProvider.primaryBlue,
                                side: BorderSide(
                                    color: ThemeProvider.primaryBlue,
                                    width: 1.5),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  // Store a guest token in SharedPreferences
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString(
                                      'auth_token', 'guest_token');

                                  // Navigate to home page
                                  Navigator.pushReplacementNamed(
                                      context, '/home');

                                  // Show a message that the user is in guest mode
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.info_outline,
                                              color: Colors.white),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'You are using the app as a guest. Some features may be limited. Also your information will not be saved.',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor:
                                          ThemeProvider.accentOrange,
                                      duration: const Duration(seconds: 5),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  setState(() {
                                    _errorMessage =
                                        'Failed to enter guest mode: $e';
                                  });
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentStep = 0;
  String? _resetCode;
  bool _useSecurityQuestion = false;
  String? _securityQuestion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentStep == 0) ...[
                  const Text(
                    'Choose how to reset your password',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_useSecurityQuestion
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            foregroundColor: !_useSecurityQuestion
                                ? Colors.white
                                : Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _useSecurityQuestion = false;
                            });
                          },
                          child: const Text('Email Verification'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _useSecurityQuestion
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            foregroundColor: _useSecurityQuestion
                                ? Colors.white
                                : Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _useSecurityQuestion = true;
                            });
                          },
                          child: const Text('Security Question'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (_useSecurityQuestion && value.isNotEmpty) {
                        // Clear previous question when email changes
                        setState(() {
                          _securityQuestion = null;
                        });
                      }
                    },
                  ),
                  if (_useSecurityQuestion) ...[
                    const SizedBox(height: 16),
                    FutureBuilder<String?>(
                      future: _getSecurityQuestion(),
                      builder: (context, snapshot) {
                        if (_emailController.text.isEmpty) {
                          return const Text(
                            'Enter your email to reset your password',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red));
                        }
                        if (snapshot.data == null) {
                          return const Text(
                              'No security question found for this email',
                              style: TextStyle(color: Colors.red));
                        }
                        _securityQuestion = snapshot.data;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security Question:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                _securityQuestion!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _securityAnswerController,
                              decoration: const InputDecoration(
                                labelText: 'Your Answer',
                                prefixIcon: Icon(Icons.question_answer),
                                hintText:
                                    'Enter your answer (case insensitive)',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your answer';
                                }
                                return null;
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _useSecurityQuestion
                                ? _verifySecurityAnswer
                                : _requestResetCode,
                            child: Text(_useSecurityQuestion
                                ? 'Verify Answer'
                                : 'Send Verification Code'),
                          ),
                  ),
                ] else if (_currentStep == 1) ...[
                  const Text(
                    'Enter the 4-digit code sent to your email',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the verification code';
                      }
                      if (value.length != 4 ||
                          !RegExp(r'^\d{4}$').hasMatch(value)) {
                        return 'Please enter a valid 4-digit code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _currentStep = 0;
                              _errorMessage = '';
                            });
                          },
                          child: const Text('Back'),
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _verifyCode,
                                child: const Text('Verify Code'),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _requestResetCode,
                      child: const Text('Resend Code'),
                    ),
                  ),
                ] else if (_currentStep == 2) ...[
                  const Text(
                    'Create a new password',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'Must contain at least one uppercase letter';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Must contain at least one number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _currentStep = _useSecurityQuestion ? 0 : 1;
                              _errorMessage = '';
                            });
                          },
                          child: const Text('Back'),
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _resetPassword,
                                child: const Text('Reset Password'),
                              ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _getSecurityQuestion() async {
    if (_emailController.text.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(_emailController.text)) {
      return null;
    }

    try {
      return await apiService.getSecurityQuestion(_emailController.text);
    } catch (e) {
      // Rather than throwing an exception, just return null and handle in UI
      return null;
    }
  }

  Future<void> _verifySecurityAnswer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final verified = await apiService.verifySecurityAnswer(
          _emailController.text,
          _securityAnswerController.text,
        );

        if (verified) {
          setState(() {
            _currentStep = 2;
          });
        } else {
          setState(() {
            _errorMessage = 'Incorrect security answer';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestResetCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final codeFromServer =
            await apiService.requestResetCode(_emailController.text);
        setState(() {
          _currentStep = 1;
          _resetCode = codeFromServer;
        });

        // For demonstration purposes only - in a real app, the code would be sent by email
        // and not shown to the user here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to your email ($_resetCode)'),
            duration: const Duration(seconds: 10),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // For demo purposes, if we already have the code locally, we can verify it
        // Without making an API call
        if (_resetCode != null && _codeController.text == _resetCode) {
          setState(() {
            _currentStep = 2;
          });
          return;
        }

        // Otherwise verify with the server
        final verified = await apiService.verifyResetCode(
            _emailController.text, _codeController.text);

        if (verified) {
          setState(() {
            _currentStep = 2;
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid verification code';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        if (_useSecurityQuestion) {
          await apiService.resetPasswordWithSecurityAnswer(
            _emailController.text,
            _securityAnswerController.text,
            _newPasswordController.text,
          );
        } else {
          await apiService.resetPasswordWithCode(
            _emailController.text,
            _codeController.text,
            _newPasswordController.text,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushReplacementNamed('/login');
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  final List<String> _securityQuestions = [
    'What was your first pet\'s name?',
    'In which city were you born?',
    'What was the name of your first school?',
    'What is your favourite food name?',
    'What was your childhood nickname?'
  ];

  String _selectedSecurityQuestion = 'What was your first pet\'s name?';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person,
                        color: Theme.of(context).primaryColor),
                    hintText: 'Enter your full name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email,
                        color: Theme.of(context).primaryColor),
                    hintText: 'Enter your email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon:
                        Icon(Icons.lock, color: Theme.of(context).primaryColor),
                    hintText: 'Enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'Password must contain at least one uppercase letter';
                    }
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return 'Password must contain at least one lowercase letter';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Password must contain at least one number';
                    }
                    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                      return 'Password must contain at least one special character';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon:
                        Icon(Icons.lock, color: Theme.of(context).primaryColor),
                    hintText: 'Confirm your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Question',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This will help us verify your identity if you need to reset your password',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedSecurityQuestion,
                        decoration: InputDecoration(
                          labelText: 'Choose a Security Question',
                          prefixIcon: Icon(Icons.security,
                              color: Theme.of(context).primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        items: _securityQuestions.map((String question) {
                          return DropdownMenuItem<String>(
                            value: question,
                            child: Text(
                              question,
                              style: const TextStyle(fontSize: 12.7),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSecurityQuestion = newValue!;
                          });
                        },
                        validator: (value) => value == null
                            ? 'Please select a security question'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _securityAnswerController,
                        decoration: InputDecoration(
                          labelText: 'Your Answer',
                          prefixIcon: Icon(Icons.question_answer,
                              color: Theme.of(context).primaryColor),
                          hintText: 'Enter your answer',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your security answer';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _registerUser,
                          child: const Text('Sign Up',
                              style: TextStyle(fontSize: 16)),
                        ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    'Already have an account? Sign in',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Make sure passwords match
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = 'Passwords do not match';
            _isLoading = false;
          });
          return;
        }

        // Call API service to register user
        await apiService.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
          _selectedSecurityQuestion,
          _securityAnswerController.text,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! You are now logged in.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to home page after a brief delay
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/home');
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Define the calculator overlay instance
  final CalculatorOverlay _calculatorOverlay = CalculatorOverlay();
  List<Reminder> _todayReminders = [];

  @override
  void initState() {
    super.initState();
    // Initial load will happen in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will be called when the widget is first inserted into the tree
    // and when any InheritedWidget it depends on (like Provider) changes
    _updateTodayReminders();
  }

  void _updateTodayReminders() {
    final reminderProvider =
        Provider.of<ReminderProvider>(context, listen: false);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _todayReminders = reminderProvider.reminders.where((reminder) {
        final reminderDate = DateTime(
          reminder.dateTime.year,
          reminder.dateTime.month,
          reminder.dateTime.day,
        );
        // Use isAtSameMomentAs or compare year/month/day individually
        return reminderDate.year == today.year &&
            reminderDate.month == today.month &&
            reminderDate.day == today.day;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the reminder provider
    final reminderProvider = Provider.of<ReminderProvider>(context);
    Provider.of<StatisticsProvider>(context);

    // This ensures we update today's reminders whenever the reminders list changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTodayReminders();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                // 1. Clear token from SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');

                // 2. Reset any auth state in your API service
                await apiService.logout();

                // 3. Use a more forceful navigation approach
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', (Route<dynamic> route) => false);

                // 4. Show feedback to the user
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')));
              } catch (e) {
                print('Error during logout: $e');
                // Show error to user
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')));
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withBlue(
                  Theme.of(context).scaffoldBackgroundColor.blue + 15),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: ThemeProvider.accentOrange,
                      width: 4,
                    ),
                  ),
                ),
                child: const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Quick Actions Row
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickAction(
                      Icons.file_copy,
                      'Notes',
                      color: ThemeProvider.primaryBlue,
                      onTap: () async {
                        await Navigator.pushNamed(context, '/notes');
                        // Force refresh when returning from other screens
                        _updateTodayReminders();
                      },
                    ),
                    _buildQuickAction(
                      Icons.calculate,
                      'Calculator',
                      color: ThemeProvider.primaryBlue,
                      onTap: () => _calculatorOverlay.toggle(context),
                    ),
                    _buildQuickAction(
                      Icons.bar_chart,
                      'Statistics',
                      color: ThemeProvider.primaryBlue,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatisticsPage(),
                          ),
                        );
                        // Force refresh when returning from other screens
                        _updateTodayReminders();
                      },
                    ),
                    _buildQuickAction(
                      Icons.timer,
                      'Reminder',
                      color: ThemeProvider.primaryBlue,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateReminder(
                              onReminderCreated: (reminder) {
                                reminderProvider.addReminder(reminder);
                                _updateTodayReminders(); // Update when a reminder is created
                              },
                            ),
                          ),
                        );
                        // Force refresh after returning from the screen as well
                        _updateTodayReminders();
                      },
                    ),
                    _buildQuickAction(
                      Icons.settings,
                      'Settings',
                      color: ThemeProvider.primaryBlue,
                      onTap: () async {
                        await Navigator.pushNamed(context, '/settings');
                        // Force refresh when returning from other screens
                        _updateTodayReminders();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Today's Events Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: ThemeProvider.accentOrange,
                      width: 4,
                    ),
                  ),
                ),
                child: const Text(
                  "Today's Events",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 34),
              Expanded(
                child:
                    _buildEventCard(_todayReminders, reminderProvider, context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label,
      {required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    List<Reminder> todayReminders,
    ReminderProvider reminderProvider,
    BuildContext context,
  ) {
    if (todayReminders.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.transparent,
        child: Container(
          width: double.infinity, // Make it full width
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Center(
            // Center the content
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No events for today',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: todayReminders.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80), // Add padding for FAB
      itemBuilder: (context, index) {
        final reminder = todayReminders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ThemeProvider.accentOrange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.alarm,
                color: ThemeProvider.accentOrange,
                size: 28,
              ),
            ),
            title: Text(
              reminder.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  reminder.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeProvider.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    DateFormat('HH:mm').format(reminder.dateTime),
                    style: TextStyle(
                      color: ThemeProvider.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete,
                color: Colors.red.shade400,
              ),
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Reminder?'),
                    content: Text(
                      'Are you sure you want to delete "${reminder.title}"?',
                    ),
                    actions: [
                      TextButton(
                        child: const Text('CANCEL'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text('DELETE',
                            style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          final index =
                              reminderProvider.reminders.indexOf(reminder);
                          reminderProvider.deleteReminder(index);
                          _updateTodayReminders();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes(); // Load notes when entering the page
  }

  @override
  void dispose() {
    // Save notes when leaving the screen
    _saveNotes();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final token = await apiService.getToken();
      if (token != null) {
        final List<Map<String, dynamic>> notesData =
            await apiService.getNotes();
        setState(() {
          notes = notesData.map((data) => Note.fromJson(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to load notes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotes() async {
    try {
      // Save all notes to the API or local storage
      for (final note in notes) {
        if (note.id == null) {
          // This is a new note that hasn't been saved to the backend
          await apiService.createNote(note.title, note.body);
        }
      }
    } catch (e) {
      print('Failed to save notes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Search feature coming soon!'),
                  backgroundColor: ThemeProvider.primaryBlue,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withBlue(
                  Theme.of(context).scaffoldBackgroundColor.blue + 15),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : notes.isEmpty
                ? _buildEmptyState()
                : _buildNotesList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateNote(
              onNewNoteCreated: onNewNoteCreated,
            ),
          ),
        ),
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
        backgroundColor: ThemeProvider.accentOrange,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: ThemeProvider.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.note_alt_outlined,
              size: 70,
              color: ThemeProvider.primaryBlue.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ThemeProvider.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create your first note by tapping the + button below',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      itemCount: notes.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          note: note,
          index: index,
          onNoteDeleted: onNoteDeleted,
          onNoteUpdated: onNoteUpdated,
        );
      },
    );
  }

  void onNewNoteCreated(Note note) async {
    try {
      // Step 1: Add the new note to the local list immediately (frontend)
      setState(() {
        notes.add(note); // Add the new note to the list to display immediately
      });

      // Step 2: Now save the new note to the backend (database)
      await _saveNotes(); // Ensure you save the new note to the database

      // Step 3: Optionally reload notes to ensure they are synced with backend
      await _loadNotes(); // Re-fetch notes to ensure they are up to date with backend

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Note created successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Failed to create note: $e');
      // Error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Failed to create note: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void onNoteDeleted(int index) async {
    final note = notes[index];

    // Immediately remove from the UI (local state)
    setState(() {
      notes.removeAt(index); // Remove from UI
    });

    try {
      if (note.id != null) {
        await apiService.deleteNote(note.id!); // Delete from backend
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Note deleted successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Failed to delete note: $e');

      // If backend deletion fails, re-add the note to the UI
      setState(() {
        notes.insert(index, note); // Restore the note in case of failure
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Failed to delete note: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void onNoteUpdated(int index, Note updatedNote) {
    setState(() {
      notes[index] = updatedNote;
    });
  }
}

class CreateNote extends StatefulWidget {
  final Function(Note) onNewNoteCreated;
  final String? initialTitle;
  final String? initialBody;
  final bool isEditing;

  const CreateNote({
    super.key,
    required this.onNewNoteCreated,
    this.initialTitle,
    this.initialBody,
    this.isEditing = false,
  });

  @override
  State<CreateNote> createState() => _CreateNoteState();
}

class _CreateNoteState extends State<CreateNote> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  Color _selectedColor = Colors.black;
  String _selectedFont = 'Default';
  double _selectedFontSize = 16.0; // Added font size variable

  // Limited color palette with 5 main colors
  final List<Color> _colors = [
    Colors.black,
    ThemeProvider.primaryBlue, // Blue
    ThemeProvider.accentOrange, // Orange
    Colors.red,
    Colors.green,
  ];

  // Font options
  final List<String> _fonts = [
    'Default',
    'Serif',
    'Monospace',
    'Cursive',
  ];

  // Font size options - Added from second file
  final List<double> _fontSizes = [12, 14, 16, 18, 20, 24, 28, 32];

  // Font style mapping
  final Map<String, TextStyle> _fontStyles = {
    'Default': const TextStyle(),
    'Serif': const TextStyle(fontFamily: 'serif'),
    'Monospace': const TextStyle(fontFamily: 'monospace'),
    'Cursive': const TextStyle(fontFamily: 'cursive'),
  };

  @override
  void initState() {
    super.initState();
    titleController.text = widget.initialTitle ?? '';
    bodyController.text = widget.initialBody ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTitle != null ? 'Edit Note' : 'New Note'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withBlue(
                  Theme.of(context).scaffoldBackgroundColor.blue + 15),
            ],
          ),
        ),
        child: Column(
          children: [
            // Title Input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: TextFormField(
                controller: titleController,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: "Title",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.normal,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Simple formatting toolbar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color Selection Label
                  Text(
                    'Text Color',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ThemeProvider.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Color Selection - Row of buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _colors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color
                                  ? ThemeProvider.accentOrange
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Font Selection Label
                  Text(
                    'Font Style',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ThemeProvider.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Font Selection
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _fonts.map((font) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFont = font;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedFont == font
                                  ? ThemeProvider.primaryBlue
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              font,
                              style: TextStyle(
                                color: _selectedFont == font
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: _selectedFont == font
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontFamily: _fontStyles[font]?.fontFamily,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Font Size Label - Added from second file
                  Text(
                    'Font Size',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ThemeProvider.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Font Size Selection - Added from second file
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _fontSizes.map((size) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFontSize = size;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedFontSize == size
                                  ? ThemeProvider.primaryBlue
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              size.toString(),
                              style: TextStyle(
                                color: _selectedFontSize == size
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: _selectedFontSize == size
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Body Input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: bodyController,
                  style: TextStyle(
                    fontSize: _selectedFontSize, // Added font size
                    color: _selectedColor,
                    height: 1.5,
                    fontFamily: _fontStyles[_selectedFont]?.fontFamily,
                  ),
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: "Start writing...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (titleController.text.isEmpty || bodyController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please fill in all fields')),
            );
            return;
          }

          // Save the note with the selected formatting options
          final note = Note(
            title: titleController.text,
            body: bodyController.text,
            textColor: _selectedColor,
            fontFamily: _selectedFont,
            fontSize: _selectedFontSize,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // We might want to add color and font properties to the Note class
          // or save formatting preferences separately

          widget.onNewNoteCreated(note);

          // Increment the count only if it's a new note (not an edit)
          if (!widget.isEditing) {
            final statisticsProvider = Provider.of<StatisticsProvider>(
              context,
              listen: false,
            );
            statisticsProvider.incrementNotesCount();
          }

          Navigator.pop(context);
        },
        icon: const Icon(Icons.save),
        label: const Text('Save'),
        backgroundColor: ThemeProvider.accentOrange,
      ),
    );
  }
}

class NoteFormatting {
  final Color textColor;
  final String fontFamily;
  final double fontSize;

  const NoteFormatting({
    this.textColor = Colors.black,
    this.fontFamily = 'Roboto',
    this.fontSize = 16.0,
  });

  factory NoteFormatting.fromJson(Map<String, dynamic> json) {
    return NoteFormatting(
      textColor:
          json['textColor'] != null ? Color(json['textColor']) : Colors.black,
      fontFamily: json['fontFamily'] ?? 'Roboto',
      fontSize: json['fontSize']?.toDouble() ?? 16.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'textColor': textColor.value,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
      };
}

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.index,
    required this.onNoteDeleted,
    required this.onNoteUpdated,
  });

  final Note note;
  final int index;
  final Function(int) onNoteDeleted;
  final Function(int, Note) onNoteUpdated;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: ThemeProvider.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteView(
                  note: note,
                  index: index,
                  onNoteDeleted: onNoteDeleted,
                  onNoteUpdated: onNoteUpdated,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title bar with date and actions
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeProvider.primaryBlue.withOpacity(0.08),
                    border: Border(
                      bottom: BorderSide(
                        color: ThemeProvider.primaryBlue.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ThemeProvider.primaryBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Add other actions here (edit, delete)
                    ],
                  ),
                ),

                // Note content preview with correct formatting
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    note.body,
                    style: TextStyle(
                      fontSize: note.fontSize,
                      color: note.textColor,
                      fontFamily: note.fontFamily,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Bottom action bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (note.createdAt != null)
                        Text(
                          'Created: ${DateFormat('MMM d, y').format(note.createdAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: ThemeProvider.primaryBlue,
                              size: 20,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateNote(
                                  onNewNoteCreated: (updatedNote) {
                                    onNoteUpdated(index, updatedNote);
                                  },
                                  initialTitle: note.title,
                                  initialBody: note.body,
                                  isEditing: true,
                                ),
                              ),
                            ),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            tooltip: 'Edit',
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red.shade300,
                              size: 20,
                            ),
                            onPressed: () => _showDeleteConfirmation(context),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Note?"),
        content: Text(
          "Are you sure you want to delete '${note.title}'?",
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onNoteDeleted(index);
            },
            child: Text(
              "DELETE",
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class NoteView extends StatelessWidget {
  const NoteView({
    super.key,
    required this.note,
    required this.index,
    required this.onNoteDeleted,
    required this.onNoteUpdated,
  });

  final Note note;
  final int index;
  final Function(int) onNoteDeleted;
  final Function(int, Note) onNoteUpdated;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Note Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: ThemeProvider.accentOrange,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateNote(
                  onNewNoteCreated: (updatedNote) {
                    onNoteUpdated(index, updatedNote);
                    Navigator.pop(context);
                  },
                  initialTitle: note.title,
                  initialBody: note.body,
                  isEditing: true,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red.shade400),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Delete Note?"),
                content: Text(
                  "Are you sure you want to delete '${note.title}'?",
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCEL"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onNoteDeleted(index);
                      Navigator.pop(context);
                    },
                    child: Text(
                      "DELETE",
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withBlue(
                  Theme.of(context).scaffoldBackgroundColor.blue + 15),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Note title
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ThemeProvider.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ThemeProvider.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ThemeProvider.primaryBlue,
                      ),
                    ),
                    if (note.updatedAt != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeProvider.accentOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Updated: ${DateFormat('MMM d, y').format(note.updatedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ThemeProvider.accentOrange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Note content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  note.body,
                  style: TextStyle(
                    fontSize: note.fontSize,
                    color: note.textColor,
                    fontFamily: note.fontFamily,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Additional info
              if (note.createdAt != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created: ${DateFormat('MMMM d, y').format(note.createdAt!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (note.updatedAt != null &&
                          note.createdAt!.toIso8601String() !=
                              note.updatedAt!.toIso8601String()) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Last edited: ${DateFormat('MMMM d, y').format(note.updatedAt!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateNote(
              onNewNoteCreated: (updatedNote) {
                onNoteUpdated(index, updatedNote);
                Navigator.pop(context);
              },
              initialTitle: note.title,
              initialBody: note.body,
              isEditing: true,
            ),
          ),
        ),
        backgroundColor: ThemeProvider.accentOrange,
        child: const Icon(Icons.edit),
      ),
    );
  }
}

class CreateReminder extends StatefulWidget {
  final Function(Reminder) onReminderCreated;
  final bool isEditing;

  const CreateReminder({
    super.key,
    required this.onReminderCreated,
    this.isEditing = false,
  });

  @override
  State<CreateReminder> createState() => _CreateReminderState();
}

class _CreateReminderState extends State<CreateReminder> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Format date and time for display
    final dateFormatted =
        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
    final timeFormatted =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Reminder' : 'Create Reminder',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withBlue(
                  Theme.of(context).scaffoldBackgroundColor.blue + 15),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Field
                Card(
                  elevation: 0,
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.title,
                              color: ThemeProvider.primaryBlue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Title',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ThemeProvider.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'Enter reminder title',
                            filled: true,
                            fillColor:
                                ThemeProvider.primaryBlue.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Description Field
                Card(
                  elevation: 0,
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.description,
                              color: ThemeProvider.primaryBlue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ThemeProvider.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText: 'Enter reminder details',
                            filled: true,
                            fillColor:
                                ThemeProvider.primaryBlue.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          maxLines: 3,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Date & Time Selection
                Card(
                  elevation: 0,
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.calendar_today,
                              color: ThemeProvider.accentOrange,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Date & Time',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ThemeProvider.accentOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            // First select date, then time
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: ThemeProvider.primaryBlue,
                                      onPrimary: Colors.white,
                                      onSurface: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .color!,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _selectedDate = pickedDate;
                              });

                              // After date is selected, show time picker
                              final TimeOfDay? pickedTime =
                                  await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: ThemeProvider.primaryBlue,
                                        onPrimary: Colors.white,
                                        onSurface: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color!,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (pickedTime != null) {
                                setState(() {
                                  _selectedTime = pickedTime;
                                });
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 16),
                            decoration: BoxDecoration(
                              color:
                                  ThemeProvider.accentOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    ThemeProvider.accentOrange.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event,
                                  color: ThemeProvider.accentOrange,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "$dateFormatted at $timeFormatted",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ThemeProvider.accentOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Notification will be sent at this time',
                            style: TextStyle(
                              fontSize: 14,
                              color: ThemeProvider.accentOrange,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Scheduled time display
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: ThemeProvider.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        color: ThemeProvider.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reminder set for: ${scheduledDateTime.toLocal().toString().substring(0, 16)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ThemeProvider.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Save button
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.save,
                      size: 24,
                    ),
                    label: Text(
                      widget.isEditing ? 'Update Reminder' : 'Save Reminder',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeProvider.accentOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () {
                      if (_titleController.text.isEmpty ||
                          _descriptionController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.white),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text('Please fill in all fields'),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }

                      // Save the reminder
                      final reminder = Reminder(
                        title: _titleController.text,
                        description: _descriptionController.text,
                        dateTime: scheduledDateTime,
                      );
                      widget.onReminderCreated(reminder);

                      // Increment the count only if it's a new reminder (not an edit)
                      if (!widget.isEditing) {
                        final statisticsProvider =
                            Provider.of<StatisticsProvider>(
                          context,
                          listen: false,
                        );
                        statisticsProvider.incrementRemindersCount();
                      }

                      scheduleNotification(reminder);

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.isEditing
                                      ? 'Reminder updated successfully!'
                                      : 'Reminder saved successfully!',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );

                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> scheduleNotification(Reminder reminder) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: reminder.hashCode,
        channelKey: 'reminder_channel',
        title: reminder.title,
        body: reminder.description,
        color: ThemeProvider.accentOrange,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        year: reminder.dateTime.year,
        month: reminder.dateTime.month,
        day: reminder.dateTime.day,
        hour: reminder.dateTime.hour,
        minute: reminder.dateTime.minute,
        second: 0,
        millisecond: 0,
        repeats: false,
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withBlue(
                  Theme.of(context).scaffoldBackgroundColor.blue + 15),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          children: [
            // Theme Settings
            _buildSectionHeader('Appearance'),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Dark Mode Toggle
                  SwitchListTile(
                    title: const Text(
                      'Dark Mode',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      themeProvider.isDarkMode ? 'On' : 'Off',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: ThemeProvider.primaryBlue,
                    ),
                    value: themeProvider.isDarkMode,
                    activeColor: ThemeProvider.accentOrange,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                ],
              ),
            ),

            // Account Settings
            _buildSectionHeader('Account'),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading:
                        Icon(Icons.person, color: ThemeProvider.primaryBlue),
                    title: const Text('Profile'),
                    subtitle: const Text('Edit your profile information'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Profile settings coming soon'),
                          backgroundColor: ThemeProvider.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                ],
              ),
            ),

            // Data & Privacy
            _buildSectionHeader('Data & Privacy'),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading:
                        Icon(Icons.security, color: ThemeProvider.primaryBlue),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('All your information is secure'),
                          backgroundColor: ThemeProvider.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // About
            _buildSectionHeader('About'),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info, color: ThemeProvider.primaryBlue),
                    title: const Text('App Info'),
                    onTap: () => _showAboutDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        Icon(Icons.star, color: ThemeProvider.accentOrange),
                    title: const Text('Rate App'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Thanks for rating us!'),
                          backgroundColor: ThemeProvider.accentOrange,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.help_outline,
                        color: ThemeProvider.primaryBlue),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Contact CS1234@gmail.com for support'),
                          backgroundColor: ThemeProvider.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // App version at the bottom
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        color: ThemeProvider.primaryBlue.withOpacity(0.1),
                        child: Icon(
                          Icons.event_note,
                          size: 36,
                          color: ThemeProvider.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'NotiTech',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2025 CS Students Project Team',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: ThemeProvider.accentOrange,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Clear token from SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');

                // Reset any auth state in your API service
                await apiService.logout();

                // Navigate to login screen
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', (Route<dynamic> route) => false);

                // Show feedback to the user
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                  ),
                );
              } catch (e) {
                print('Error during logout: $e');
                // Show error to user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error logging out: $e'),
                  ),
                );
              }
            },
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear App Data'),
        content: const Text(
            'This will clear all your app data including notes and reminders. This action cannot be undone. Are you sure?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              // Implement clear data functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All app data has been cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About NotiTech'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: ThemeProvider.primaryBlue.withOpacity(0.1),
                  child: Icon(
                    Icons.event_note,
                    size: 64,
                    color: ThemeProvider.primaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'NotiTech is an application that helps you manage your daily tasks efficiently. We are committed to providing a seamless experience while ensuring your data remains private and secure.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildAboutRow('Version', '1.0.0'),
            _buildAboutRow('Developer', 'CS Students Project Team'),
            _buildAboutRow('Released', 'January 2025'),
            _buildAboutRow('© 2025', 'All rights reserved'),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final statisticsProvider = Provider.of<StatisticsProvider>(context);

    // Calculate percentages for visualization
    final int totalItems = statisticsProvider.notesCount +
        statisticsProvider.remindersCount +
        statisticsProvider.signInCount;

    final double notesPercentage =
        totalItems > 0 ? statisticsProvider.notesCount / totalItems : 0.0;
    final double remindersPercentage =
        totalItems > 0 ? statisticsProvider.remindersCount / totalItems : 0.0;
    final double signInPercentage =
        totalItems > 0 ? statisticsProvider.signInCount / totalItems : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withBlue(
                  Theme.of(context).scaffoldBackgroundColor.blue + 15),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ThemeProvider.primaryBlue,
                        ThemeProvider.primaryBlue.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeProvider.primaryBlue.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Usage Statistics',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'See how you use the app',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Circular Statistics Design
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background Circle
                            Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                              ),
                            ),

                            // Notes Circle - Use primary blue
                            SizedBox(
                              width: 260,
                              height: 260,
                              child: CircularProgressIndicator(
                                value: notesPercentage,
                                strokeWidth: 25,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    ThemeProvider.primaryBlue),
                              ),
                            ),

                            // Reminders Circle - Use accent orange
                            SizedBox(
                              width: 260,
                              height: 260,
                              child: Transform.rotate(
                                angle: 2 * pi * notesPercentage,
                                child: CircularProgressIndicator(
                                  value: remindersPercentage,
                                  strokeWidth: 25,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      ThemeProvider.accentOrange),
                                ),
                              ),
                            ),

                            // Sign-In Circle - Use a third complementary color
                            SizedBox(
                              width: 260,
                              height: 260,
                              child: Transform.rotate(
                                angle: 2 *
                                    pi *
                                    (notesPercentage + remindersPercentage),
                                child: CircularProgressIndicator(
                                  value: signInPercentage,
                                  strokeWidth: 25,
                                  backgroundColor: Colors.transparent,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Colors.teal,
                                  ),
                                ),
                              ),
                            ),

                            // Center Card with Total
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: ThemeProvider.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    totalItems.toString(),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: ThemeProvider.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(ThemeProvider.primaryBlue, 'Notes',
                              statisticsProvider.notesCount),
                          const SizedBox(width: 16),
                          _buildLegendItem(ThemeProvider.accentOrange,
                              'Reminders', statisticsProvider.remindersCount),
                          const SizedBox(width: 16),
                          _buildLegendItem(Colors.teal, 'Sign-Ins',
                              statisticsProvider.signInCount),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // App Usage Statistic
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 24,
                            color: Colors.teal,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'App Usage This Month',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Create progress bar for app usage
                      Container(
                        height: 120,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.bar_chart,
                                color: Colors.teal,
                                size: 40,
                              ),
                              const SizedBox(width: 20),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${statisticsProvider.appUsageCount}',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  Text(
                                    'times',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Statistical Breakdown Cards
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Notes Statistics
                      Expanded(
                        child: _buildStatCard(
                          context,
                          Icons.note_alt,
                          'Notes',
                          statisticsProvider.notesCount.toString(),
                          ThemeProvider.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Reminders Statistics
                      Expanded(
                        child: _buildStatCard(
                          context,
                          Icons.timer,
                          'Reminders',
                          statisticsProvider.remindersCount.toString(),
                          ThemeProvider.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Sign-in Statistics
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatCard(
                    context,
                    Icons.login,
                    'Sign-ins',
                    statisticsProvider.signInCount.toString(),
                    Colors.teal,
                    isWide: true,
                  ),
                ),

                const SizedBox(height: 30),

                // Action Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Statistics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeProvider.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Refresh statistics
                      statisticsProvider.loadStatistics();

                      // Show refresh feedback
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Statistics refreshed!'),
                          backgroundColor: ThemeProvider.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int count) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color, {
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              if (isWide) const SizedBox(width: 16),
              if (isWide)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (!isWide) ...[
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// First, let's update the Calculator widget
class Calculator extends StatefulWidget {
  final Function() onClose;

  const Calculator({super.key, required this.onClose});

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  String _input = '';
  String _output = '';
  bool _isError = false;

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        _input = '';
        _output = '';
        _isError = false;
      } else if (buttonText == '⌫') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (buttonText == '=') {
        try {
          // Replace non-standard symbols with standard symbols
          String expression = _input.replaceAll('×', '*').replaceAll('÷', '/');

          Parser p = Parser();
          Expression exp = p.parse(expression);
          ContextModel cm = ContextModel();
          double result = exp.evaluate(EvaluationType.REAL, cm);

          // Format the result to avoid excessive decimal places
          if (result == result.toInt()) {
            _output = result.toInt().toString();
          } else {
            _output = result
                .toStringAsFixed(6)
                .replaceAll(RegExp(r'0+$'), '')
                .replaceAll(RegExp(r'\.$'), '');
          }
          _isError = false;
        } catch (e) {
          _output = 'Error';
          _isError = true;
        }
      } else {
        _input += buttonText;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 300,
          height: 500,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Calculator header with close button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: ThemeProvider.primaryBlue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.calculate_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Calculator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: widget.onClose,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Display area
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomRight,
                height: 120,
                decoration: BoxDecoration(
                  color: ThemeProvider.primaryBlue.withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: ThemeProvider.primaryBlue.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Input
                    Text(
                      _input,
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 8),
                    // Output
                    Text(
                      _output,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color:
                            _isError ? Colors.red : ThemeProvider.primaryBlue,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),

              // Calculator buttons
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    childAspectRatio: 1.3,
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _buildButton('C', isFunction: true),
                      _buildButton('('),
                      _buildButton(')'),
                      _buildButton('⌫', isFunction: true),
                      _buildButton('7'),
                      _buildButton('8'),
                      _buildButton('9'),
                      _buildButton('÷', isOperator: true),
                      _buildButton('4'),
                      _buildButton('5'),
                      _buildButton('6'),
                      _buildButton('×', isOperator: true),
                      _buildButton('1'),
                      _buildButton('2'),
                      _buildButton('3'),
                      _buildButton('-', isOperator: true),
                      _buildButton('0'),
                      _buildButton('.'),
                      _buildButton('=', isEqual: true),
                      _buildButton('+', isOperator: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text,
      {bool isOperator = false,
      bool isFunction = false,
      bool isEqual = false}) {
    Color buttonColor;
    Color textColor;

    if (isEqual) {
      buttonColor = ThemeProvider.accentOrange;
      textColor = Colors.white;
    } else if (isOperator) {
      buttonColor = ThemeProvider.primaryBlue.withOpacity(0.15);
      textColor = ThemeProvider.primaryBlue;
    } else if (isFunction) {
      buttonColor = ThemeProvider.accentOrange.withOpacity(0.15);
      textColor = ThemeProvider.accentOrange;
    } else {
      buttonColor = Theme.of(context).cardColor;
      textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    }

    return InkWell(
      onTap: () => _onButtonPressed(text),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: isOperator || isEqual || isFunction
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

// Overlay controller to show and position the calculator
class CalculatorOverlay {
  OverlayEntry? _overlayEntry;
  bool _isVisible = false;
  Offset _offset = const Offset(20, 100); // Initial position

  void show(BuildContext context) {
    if (_isVisible) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: _offset.dx,
        top: _offset.dy,
        child: GestureDetector(
          onPanUpdate: (details) {
            // Update the position when dragged
            _offset = Offset(
              _offset.dx + details.delta.dx,
              _offset.dy + details.delta.dy,
            );
            _overlayEntry?.markNeedsBuild(); // Rebuild the overlay
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Calculator(
                onClose: () => hide(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;
  }

  void hide() {
    if (!_isVisible) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isVisible = false;
  }

  bool get isVisible => _isVisible;

  void toggle(BuildContext context) {
    if (_isVisible) {
      hide();
    } else {
      show(context);
    }
  }
}
