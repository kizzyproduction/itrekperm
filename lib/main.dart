import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clipboard/clipboard.dart'; // Import the package

Future<bool> checkGrammar(String sentence) async {
  final response = await http.post(
    Uri.parse('https://grammarbot-neural.p.rapidapi.com/v1/check'),
    body: {'sentence': sentence},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final bool isCorrect = data['is_correct'];
    return isCorrect;
  } else {
    throw Exception('Failed to check grammar: ${response.statusCode}');
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Word Permutation Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WordPermutationPage(),
    );
  }
}

class WordPermutationPage extends StatefulWidget {
  @override
  _WordPermutationPageState createState() => _WordPermutationPageState();
}

class _WordPermutationPageState extends State<WordPermutationPage> {
  final TextEditingController _wordsController = TextEditingController();
  final TextEditingController _maxSentenceLengthController = TextEditingController();
  List<String> _generatedSentences = [];
  bool _loading = false;

  void _generateSentences() async {
    setState(() {
      _loading = true;
      _generatedSentences.clear();
    });

    String wordsString = _wordsController.text.trim();
    List<String> words = wordsString.split(',');
    int maxSentenceLength = int.tryParse(_maxSentenceLengthController.text.trim()) ?? 0;

    if (words.isEmpty || maxSentenceLength <= 0) {
      setState(() {
        _loading = false;
      });
      _showErrorDialog("Invalid input. Please enter valid words and a positive integer for maximum sentence length.");
      return;
    }

    List<String> sentence = [];
    await _generatePermutations(words, maxSentenceLength, sentence);

    setState(() {
      _loading = false;
    });
  }

  Future<void> _generatePermutations(List<String> words, int maxLength, List<String> sentence) async {
    if (sentence.length == maxLength) {
      String generatedSentence = sentence.join(' ');
      final bool isCorrect = await checkGrammar(generatedSentence);
      if (isCorrect) {
        setState(() {
          _generatedSentences.add(generatedSentence);
        });
      }
      return;
    }

    for (int i = 0; i < words.length; i++) {
      if (!sentence.contains(words[i])) {
        List<String> newSentence = List.from(sentence);
        newSentence.add(words[i]);
        await _generatePermutations(words, maxLength, newSentence);
      }
    }
  }


  void _clearFields() {
    _wordsController.clear();
    _maxSentenceLengthController.clear();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)); // Copy text to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied to Clipboard"),
      ),
    );
  }

  void _copyToClipboardAll() {
    String allSentences = _generatedSentences.join('\n'); // Concatenate all sentences with newline separator
    Clipboard.setData(ClipboardData(text: allSentences)); // Copy text to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("All Sentences Copied to Clipboard"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Word Permutation Generator'),
        backgroundColor: Colors.teal,
      ),
      backgroundColor: Colors.white70,
      body: _loading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _wordsController,
              decoration: InputDecoration(
                labelText: 'Enter words separated by commas',
              ),
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: _maxSentenceLengthController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter maximum sentence length',
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _generateSentences,
              child: Text('Generate Sentences'),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton( // Button to copy all sentences to clipboard
              onPressed: _generatedSentences.isEmpty ? null : _copyToClipboardAll,
              child: Text('Copy All Sentences to Clipboard'),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
              ),
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: ListView.builder(
                itemCount: _generatedSentences.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_generatedSentences[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.content_copy),
                      onPressed: () {
                        _copyToClipboard(_generatedSentences[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
