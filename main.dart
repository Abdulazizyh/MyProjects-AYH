import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

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

  void incrementNotesCount() {
    _notesCount++;
    notifyListeners();
    _updateStatisticsOnServer();
  }

  void incrementRemindersCount() {
    _remindersCount++;
    notifyListeners();
    _updateStatisticsOnServer();
  }

  void incrementSignInCount() {
    _signInCount++;
    notifyListeners();
    _updateStatisticsOnServer();
  }

  void incrementAppUsageCount() {
    _appUsageCount++;
    notifyListeners();
    _updateStatisticsOnServer();
  }

  Future<void> _updateStatisticsOnServer() async {
    final url = Uri.parse(
        'http://192.168.1.15:5000/register'); // Replace with your server URL
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'notes_count': _notesCount,
        'reminders_count': _remindersCount,
        'sign_in_count': _signInCount,
        'app_usage_count': _appUsageCount,
      }),
    );

    if (response.statusCode != 200) {
      print('Failed to update statistics: ${response.body}');
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
      theme: themeProvider.isDarkMode
          ? ThemeData.dark()
          : ThemeData.light().copyWith(
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => HomePage(),
        '/notes': (context) => const NotesScreen(),
        '/settings': (context) => const SettingsPage(),
        '/statistics': (context) => const StatisticsPage(),
      },
    );
  }
}

class Note {
  final String title;
  final String body;

  Note({required this.title, required this.body});
}

class Reminder {
  final String title;
  final String description;
  final DateTime dateTime;

  Reminder({
    required this.title,
    required this.description,
    required this.dateTime,
  });
}

class ReminderProvider with ChangeNotifier {
  final List<Reminder> _reminders = [];

  List<Reminder> get reminders => _reminders;

  void addReminder(Reminder reminder) {
    _reminders.add(reminder);
    notifyListeners();
  }

  void deleteReminder(int index) {
    _reminders.removeAt(index);
    notifyListeners();
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

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Display loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logging in...')),
        );

        // Get your server IP dynamically or use a configuration file
        // For testing purposes, you can use your computer's IP address
        // Make sure your computer and device are on the same network
        final serverUrl =
            'http://192.168.1.15:5000'; // Update with your actual IP

        final url = Uri.parse('$serverUrl/login');
        print('Attempting to connect to: $url');

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': _emailController.text,
                'password': _passwordController.text,
              }),
            )
            .timeout(const Duration(seconds: 10)); // Add timeout

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        final responseData = jsonDecode(response.body);
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Login failed')),
          );
        }
      } catch (e) {
        print('Error during login: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statisticsProvider = Provider.of<StatisticsProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(
                      Icons.email,
                      color: Theme.of(context).primaryColor,
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
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(
                      Icons.lock,
                      color: Theme.of(context).primaryColor,
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
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loginUser,
                    child: const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    'Create New Account',
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
  bool _obscurePassword = true;

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Display loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Creating account...')),
        );

        // Get your server IP dynamically or use a configuration file
        final serverUrl =
            'http://192.168.1.15:5000'; // Update with your actual IP

        final url = Uri.parse('$serverUrl/register');
        print('Attempting to connect to: $url');

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': _emailController.text,
                'password': _passwordController.text,
                'name':
                    _nameController.text, // Make sure this is passed if needed
              }),
            )
            .timeout(const Duration(seconds: 10)); // Add timeout

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        final responseData = jsonDecode(response.body);
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(responseData['message'] ?? 'Registration failed')),
          );
        }
      } catch (e) {
        print('Error during registration: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(
                      Icons.person,
                      color: Theme.of(context).primaryColor,
                    ),
                    hintText: 'Enter your full name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(
                      Icons.email,
                      color: Theme.of(context).primaryColor,
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
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(
                      Icons.lock,
                      color: Theme.of(context).primaryColor,
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
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _registerUser,
                    child: const Text(
                      'Register',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text(
                    'Already have an account? Login',
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
}

// Rest of the code remains the same...

class HomePage extends StatelessWidget {
  HomePage({super.key});

  // Define the calculator overlay instance
  final CalculatorOverlay _calculatorOverlay = CalculatorOverlay();

  @override
  Widget build(BuildContext context) {
    final reminderProvider = Provider.of<ReminderProvider>(context);
    final statisticsProvider = Provider.of<StatisticsProvider>(context);
    final todayReminders = reminderProvider.reminders.where((reminder) {
      final now = DateTime.now();
      return reminder.dateTime.year == now.year &&
          reminder.dateTime.month == now.month &&
          reminder.dateTime.day == now.day;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(
                  Icons.file_copy,
                  'Notes',
                  onTap: () {
                    Navigator.pushNamed(context, '/notes');
                  },
                ),
                _buildQuickAction(
                  Icons.calculate,
                  'Calculator',
                  onTap: () => _calculatorOverlay.toggle(context),
                ),
                _buildQuickAction(
                  Icons.bar_chart,
                  'Statistics',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsPage(),
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  Icons.timer,
                  'Reminder',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateReminder(
                          onReminderCreated: (reminder) {
                            reminderProvider.addReminder(reminder);
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  Icons.settings,
                  'Settings',
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text("Today's Events", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            _buildEventCard(todayReminders, reminderProvider, context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          FloatingActionButton(onPressed: onTap, mini: true, child: Icon(icon)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 16)),
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
      return const Card(
        child: ListTile(
          leading: Icon(Icons.calendar_today),
          title: Text('No events today'),
        ),
      );
    }

    return Column(
      children: todayReminders.map((reminder) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.timer),
            title: Text(reminder.title),
            subtitle: Text(DateFormat('HH:mm').format(reminder.dateTime)),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                final index = reminderProvider.reminders.indexOf(reminder);
                reminderProvider.deleteReminder(index);
              },
            ),
          ),
        );
      }).toList(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        elevation: 0,
        centerTitle: true,
      ),
      body: notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create a note',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notes.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) => NoteCard(
                note: notes[index],
                index: index,
                onNoteDeleted: onNoteDeleted,
                onNoteUpdated: onNoteUpdated,
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateNote(
              onNewNoteCreated: (note) {
                onNewNoteCreated(note);
              },
            ),
          ),
        ),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  void onNewNoteCreated(Note note) => setState(() => notes.add(note));
  void onNoteDeleted(int index) => setState(() => notes.removeAt(index));
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
  double _selectedFontSize = 16.0;
  String _selectedTool = 'Pen';

  final List<Color> _colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.teal,
  ];

  final List<double> _fontSizes = [12, 14, 16, 18, 20, 24, 28, 32];

  final List<String> _tools = ['Pen', 'Pencil'];

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
        decoration: BoxDecoration(color: Colors.grey.shade50),
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

            // Formatting tools in a card
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
                  // Label
                  Text(
                    'Formatting',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tool Selection (Pen or Pencil)
                  Row(
                    children: _tools.map((tool) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTool = tool;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedTool == tool
                                ? Colors.blue.shade500
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tool,
                            style: TextStyle(
                              color: _selectedTool == tool
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: _selectedTool == tool
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Color Selection Label
                  Text(
                    'Text Color',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Color Selection
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _colors.map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColor == color
                                    ? Colors.blue
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
                  ),
                  const SizedBox(height: 16),

                  // Font Size Label
                  Text(
                    'Font Size',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Font Size Selection
                  SizedBox(
                    height: 50,
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
                                  ? Colors.blue.shade500
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
                    fontSize: _selectedFontSize,
                    color: _selectedColor,
                    height: 1.5,
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
        onPressed: () {
          if (titleController.text.isEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Please add a title')));
            return;
          }

          if (bodyController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please add some content')),
            );
            return;
          }

          // Save the note
          widget.onNewNoteCreated(
            Note(title: titleController.text, body: bodyController.text),
          );

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
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        title: Text(
          note.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            note.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade600),
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
        title: const Text("Note"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
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
        color: Colors.grey.shade50,
        child: Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Divider(height: 30),
                Text(
                  note.body,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
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
      appBar: AppBar(title: const Text('Create Reminder')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            InkWell(
              onTap: () async {
                // First select date, then time
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );

                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });

                  // After date is selected, show time picker
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );

                  if (pickedTime != null) {
                    setState(() {
                      _selectedTime = pickedTime;
                    });
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade700],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      "$dateFormatted at $timeFormatted",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reminder set for: ${scheduledDateTime.toLocal().toString().substring(0, 16)}',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_titleController.text.isEmpty ||
              _descriptionController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please fill in all fields')),
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
            final statisticsProvider = Provider.of<StatisticsProvider>(
              context,
              listen: false,
            );
            statisticsProvider.incrementRemindersCount();
          }

          scheduleNotification(reminder);
          Navigator.pop(context);
        },
        icon: const Icon(Icons.save),
        label: const Text('Save Reminder'),
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
      ),
      schedule: NotificationCalendar(
        year: reminder.dateTime.year,
        month: reminder.dateTime.month,
        day: reminder.dateTime.day,
        hour: reminder.dateTime.hour,
        minute: reminder.dateTime.minute,
        second: 0,
        millisecond: 0,
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
  bool showInfo = false;
  bool showSupport = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
              const SizedBox(height: 20),

              // Info and Support buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showInfo = !showInfo;
                        if (showSupport) showSupport = false;
                      });
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('App Info'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showInfo
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      foregroundColor: showInfo ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showSupport = !showSupport;
                        if (showInfo) showInfo = false;
                      });
                    },
                    icon: const Icon(Icons.contact_support_outlined),
                    label: const Text('Contact Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showSupport
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      foregroundColor: showSupport ? Colors.white : null,
                    ),
                  ),
                ],
              ),

              // Info section
              if (showInfo)
                const Card(
                  margin: EdgeInsets.symmetric(vertical: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This application helps you manage your daily tasks efficiently. We are committed to providing a seamless experience while ensuring your data remains private and secure.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          title: Text('Version'),
                          subtitle: Text('1.0.0'),
                        ),
                        ListTile(
                          title: Text('Developer'),
                          subtitle: Text('CisStudents ProjectTeam'),
                        ),
                        ListTile(
                          title: Text('© 2025'),
                          subtitle: Text('All rights reserved'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Support section
              if (showSupport)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Support',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Discord'),
                          subtitle: const Text('https://discord.gg/gTQsdJeF'),
                          onTap: () {
                            // Launch email app with the address
                            // You may need url_launcher package
                            // launchUrl(Uri.parse('mailto:Abdulaziz.m.o@outlook.sa'));
                          },
                        ),
                        const Divider(),
                        const ListTile(
                          leading: Icon(Icons.support_agent),
                          title: Text('Support Hours'),
                          subtitle: Text('24/7 Email Support'),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Have a problem?'),
                          subtitle: const Text('We\'re here to help'),
                          onTap: () {
                            // Navigate to help page or show dialog
                          },
                        ),
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
}

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final statisticsProvider = Provider.of<StatisticsProvider>(context);

    // Calculate percentages for visualization
    final int totalItems = statisticsProvider.notesCount +
        statisticsProvider.remindersCount +
        statisticsProvider.signInCount; // Use signInCount instead of otherCount

    final double notesPercentage =
        totalItems > 0 ? statisticsProvider.notesCount / totalItems : 0.0;
    final double remindersPercentage =
        totalItems > 0 ? statisticsProvider.remindersCount / totalItems : 0.0;
    final double signInPercentage = totalItems > 0
        ? statisticsProvider.signInCount / totalItems
        : 0.0; // Use signInCount

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Usage Statistics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Circular Statistics Design
            SizedBox(
              width: 300, // Enlarged circle
              height: 300, // Enlarged circle
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Circle
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                  ),

                  // Notes Circle
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: CircularProgressIndicator(
                      value: notesPercentage,
                      strokeWidth: 30, // Thicker stroke
                      backgroundColor: Colors.transparent,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),

                  // Reminders Circle
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: Transform.rotate(
                      angle: 2 * pi * notesPercentage,
                      child: CircularProgressIndicator(
                        value: remindersPercentage,
                        strokeWidth: 30, // Thicker stroke
                        backgroundColor: Colors.transparent,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  ),

                  // Sign-In Circle
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: Transform.rotate(
                      angle: 2 * pi * (notesPercentage + remindersPercentage),
                      child: CircularProgressIndicator(
                        value: signInPercentage,
                        strokeWidth: 30, // Thicker stroke
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                      ),
                    ),
                  ),

                  // Center Text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 24, // Larger font
                          color: Colors.black, // Set text color to black
                        ),
                      ),
                      Text(
                        totalItems.toString(),
                        style: const TextStyle(
                          fontSize: 36, // Larger font
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Set text color to black
                        ),
                      ),
                    ],
                  ),

                  // Percentage Labels
                  Positioned(
                    top: 50, // Adjust position for Notes percentage
                    child: Text(
                      '${(notesPercentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50, // Adjust position for Reminders percentage
                    left: 50,
                    child: Text(
                      '${(remindersPercentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50, // Adjust position for Sign-In percentage
                    right: 50,
                    child: Text(
                      '${(signInPercentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(Colors.blue, 'Notes'),
                const SizedBox(width: 20),
                _buildLegend(Colors.green, 'Reminders'),
                const SizedBox(width: 20),
                _buildLegend(Colors.orange, 'Sign-Ins'), // Updated label
              ],
            ),

            const SizedBox(height: 20),

            // App Usage Statistic
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'App Usage This Month',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${statisticsProvider.appUsageCount} times',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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

  // Helper method to build legend items
  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

// First, let's create a Calculator widget
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
          Parser p = Parser();
          Expression exp = p.parse(_input);
          ContextModel cm = ContextModel();
          double result = exp.evaluate(EvaluationType.REAL, cm);

          // Format result to avoid excessive decimals
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
      child: Container(
        width: 300,
        height: 450, // Fixed height to prevent overflow
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Calculator header with close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calculator',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Display area
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomRight,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
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
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _isError
                          ? Colors.red
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),

            // Calculator buttons
            Expanded(
              child: SingleChildScrollView(
                // Add a scrollable area for the buttons
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  childAspectRatio: 1.3,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
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
    );
  }

  Widget _buildButton(String text,
      {bool isOperator = false,
      bool isFunction = false,
      bool isEqual = false}) {
    Color buttonColor;
    Color textColor;

    if (isEqual) {
      buttonColor = Theme.of(context).primaryColor;
      textColor = Colors.white;
    } else if (isOperator) {
      buttonColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
    } else if (isFunction) {
      buttonColor = Colors.grey.shade200;
      textColor = Colors.black;
    } else {
      buttonColor = Theme.of(context).cardColor;
      textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    }

    return InkWell(
      onTap: () => _onButtonPressed(text),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 1,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 24,
              fontWeight:
                  isOperator || isEqual ? FontWeight.bold : FontWeight.normal,
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
            setState(() {
              _offset = Offset(
                _offset.dx + details.delta.dx,
                _offset.dy + details.delta.dy,
              );
            });
          },
          child: Material(
            child: Calculator(
              onClose: () => hide(),
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

  void setState(VoidCallback fn) {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
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
