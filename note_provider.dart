import 'package:flutter/foundation.dart';

class NoteProvider extends ChangeNotifier {
  final List<String> _notes = [];

  List<String> get notes => _notes;

  void addNote(String note) {
    _notes.add(note);
    notifyListeners();
  }

  void updateNote(int index, String note) {
    _notes[index] = note;
    notifyListeners();
  }

  void deleteNote(int index) {
    _notes.removeAt(index);
    notifyListeners();
  }
}
