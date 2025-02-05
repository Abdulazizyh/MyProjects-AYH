import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'note_provider.dart';

void main() {
  runApp(NoteTakingApp());
}

class NoteTakingApp extends StatelessWidget {
  const NoteTakingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NoteProvider(),
      child: MaterialApp(
        title: 'Note Taking App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomePage(), // Set HomePage as the initial screen
      ),
    );
  }
}

class NoteListScreen extends StatelessWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
      ),
      body: Consumer<NoteProvider>(
        builder: (context, noteProvider, child) {
          return ListView.builder(
            itemCount: noteProvider.notes.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(noteProvider.notes[index]),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NoteDetailScreen(index: index),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class NoteDetailScreen extends StatelessWidget {
  final int? index;
  const NoteDetailScreen({super.key, this.index});

  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final TextEditingController controller = TextEditingController(
      text: index != null ? noteProvider.notes[index!] : '',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(index == null ? 'New Note' : 'Edit Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Note',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (index != null) {
                  noteProvider.updateNote(
                      index!, controller.text); // Removed removeEmojis function
                } else {
                  noteProvider.addNote(
                      controller.text); // Removed removeEmojis function
                }
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(Icons.file_copy, 'Files', context),
                _buildQuickAction(Icons.add, 'Add Event', context),
                _buildQuickAction(Icons.bar_chart, 'Statistics', context),
                _buildQuickAction(Icons.timer, 'Reminder', context),
              ],
            ),
            SizedBox(height: 32),
            Text('Today\'s Events', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            _buildEventCard(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.schedule), label: 'Study Schedule'),
          BottomNavigationBarItem(
              icon: Icon(Icons.school), label: 'Study and Focus'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, BuildContext context) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: () {
            if (label == 'Files') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      NoteListScreen(), // Navigate to NoteListScreen
                ),
              );
            }
            // Add other cases for the quick actions here as needed
          },
          mini: true,
          child: Icon(icon),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildEventCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.calendar_today),
        title: Text('No events today'),
      ),
    );
  }
}

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Files'),
      ),
      body: Center(
        child: Text('This is the Files page.'),
      ),
    );
  }
}
