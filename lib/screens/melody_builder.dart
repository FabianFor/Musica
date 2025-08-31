import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/audio_service.dart';

class MelodyBuilder extends StatefulWidget {
  @override
  _MelodyBuilderState createState() => _MelodyBuilderState();
}

class _MelodyBuilderState extends State<MelodyBuilder> {
  List<Map<String, dynamic>> melody = [];
  bool isRecording = false;
  bool isPlaying = false;
  int currentPlayingNote = -1;
  Set<int> pressedKeys = {};

  // Todas las notas de una octava completa con sostenidos
  final List<Map<String, dynamic>> whiteKeys = [
    {'name': 'C', 'fullName': 'Do', 'frequency': 261.63, 'keyType': 'white'},
    {'name': 'D', 'fullName': 'Re', 'frequency': 293.66, 'keyType': 'white'},
    {'name': 'E', 'fullName': 'Mi', 'frequency': 329.63, 'keyType': 'white'},
    {'name': 'F', 'fullName': 'Fa', 'frequency': 349.23, 'keyType': 'white'},
    {'name': 'G', 'fullName': 'Sol', 'frequency': 392.00, 'keyType': 'white'},
    {'name': 'A', 'fullName': 'La', 'frequency': 440.00, 'keyType': 'white'},
    {'name': 'B', 'fullName': 'Si', 'frequency': 493.88, 'keyType': 'white'},
    {'name': 'C+', 'fullName': 'Do+', 'frequency': 523.25, 'keyType': 'white'},
  ];

  final List<Map<String, dynamic>> blackKeys = [
    {'name': 'C#', 'fullName': 'Do#', 'frequency': 277.18, 'position': 0.5},
    {'name': 'D#', 'fullName': 'Re#', 'frequency': 311.13, 'position': 1.5},
    {'name': 'F#', 'fullName': 'Fa#', 'frequency': 369.99, 'position': 3.5},
    {'name': 'G#', 'fullName': 'Sol#', 'frequency': 415.30, 'position': 4.5},
    {'name': 'A#', 'fullName': 'La#', 'frequency': 466.16, 'position': 5.5},
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    AudioService.initialize();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void playNote(double frequency, int noteId) {
    AudioService.playFrequency(frequency, duration: 0.5);
  }

  void handleKeyPress(int noteIndex, bool isBlackKey) {
    double frequency;
    int noteId;
    
    if (isBlackKey) {
      frequency = blackKeys[noteIndex]['frequency'];
      noteId = 100 + noteIndex; // IDs únicos para teclas negras
    } else {
      frequency = whiteKeys[noteIndex]['frequency'];
      noteId = noteIndex;
    }
    
    playNote(frequency, noteId);
    HapticFeedback.selectionClick();
    
    setState(() {
      pressedKeys.add(noteId);
    });
    
    Timer(Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          pressedKeys.remove(noteId);
        });
      }
    });
    
    if (isRecording) {
      setState(() {
        melody.add({
          'frequency': frequency,
          'noteId': noteId,
          'isBlackKey': isBlackKey,
          'noteIndex': noteIndex,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      });
    }
  }

  void playMelody() async {
    if (melody.isEmpty) return;
    
    setState(() {
      isPlaying = true;
    });
    
    int startTime = melody[0]['timestamp'];
    
    for (int i = 0; i < melody.length; i++) {
      int delay = ((melody[i]['timestamp'] - startTime) * 0.4).round();
      
      Timer(Duration(milliseconds: delay), () {
        if (mounted && isPlaying) {
          double frequency = melody[i]['frequency'];
          int noteId = melody[i]['noteId'];
          
          AudioService.playFrequency(frequency, duration: 0.3);
          
          setState(() {
            pressedKeys.add(noteId);
          });
          
          Timer(Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                pressedKeys.remove(noteId);
              });
            }
          });
          
          if (i == melody.length - 1) {
            Timer(Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  isPlaying = false;
                });
              }
            });
          }
        }
      });
    }
  }

  void stopPlayback() {
    setState(() {
      isPlaying = false;
      pressedKeys.clear();
    });
    AudioService.stop();
  }

  void toggleRecording() {
    setState(() {
      isRecording = !isRecording;
    });
    HapticFeedback.mediumImpact();
  }

  void clearMelody() {
    setState(() {
      melody.clear();
      isRecording = false;
      isPlaying = false;
      pressedKeys.clear();
    });
    AudioService.stop();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 800;
    
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "MELODY MAKER",
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
            fontSize: isLargeScreen ? 20 : 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF4285F4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Controles superiores
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Record button
                GestureDetector(
                  onTap: toggleRecording,
                  child: Container(
                    width: isLargeScreen ? 60 : 50,
                    height: isLargeScreen ? 60 : 50,
                    decoration: BoxDecoration(
                      color: isRecording ? Color(0xFFEA4335) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Color(0xFFEA4335),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fiber_manual_record,
                      color: isRecording ? Colors.white : Color(0xFFEA4335),
                      size: isLargeScreen ? 28 : 24,
                    ),
                  ),
                ),
                
                SizedBox(width: 20),
                
                // Play button
                GestureDetector(
                  onTap: melody.isEmpty ? null : (isPlaying ? stopPlayback : playMelody),
                  child: Container(
                    width: isLargeScreen ? 60 : 50,
                    height: isLargeScreen ? 60 : 50,
                    decoration: BoxDecoration(
                      color: melody.isEmpty 
                        ? Colors.grey[300] 
                        : (isPlaying ? Color(0xFFEA4335) : Color(0xFF4285F4)),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: melody.isEmpty ? [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                      size: isLargeScreen ? 28 : 24,
                    ),
                  ),
                ),
                
                SizedBox(width: 20),
                
                // Clear button
                IconButton(
                  onPressed: clearMelody,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red[400],
                    size: isLargeScreen ? 28 : 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Piano realista
          Expanded(
            child: Container(
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Stack(
                  children: [
                    // Teclas blancas
                    Row(
                      children: whiteKeys.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> note = entry.value;
                        bool isPressed = pressedKeys.contains(index);
                        
                        return Expanded(
                          child: GestureDetector(
                            onTapDown: (_) => handleKeyPress(index, false),
                            child: Container(
                              height: double.infinity,
                              margin: EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isPressed ? Colors.grey[300] : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[400]!,
                                  width: 1,
                                ),
                                boxShadow: isPressed ? [] : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      children: [
                                        Text(
                                          note['name'],
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: isLargeScreen ? 16 : 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          note['fullName'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: isLargeScreen ? 12 : 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    // Teclas negras (sostenidos)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: (MediaQuery.of(context).size.height - 200) * 0.6,
                      child: Row(
                        children: [
                          ...blackKeys.map((blackKey) {
                            int blackIndex = blackKeys.indexOf(blackKey);
                            bool isPressed = pressedKeys.contains(100 + blackIndex);
                            double position = blackKey['position'];
                            
                            return Positioned(
                              left: position * (screenSize.width - 40) / 8 - 15,
                              child: GestureDetector(
                                onTapDown: (_) => handleKeyPress(blackIndex, true),
                                child: Container(
                                  width: 30,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isPressed ? Colors.grey[700] : Colors.black,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: isPressed ? [] : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      blackKey['name'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isLargeScreen ? 12 : 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).expand((widget) => [
                            SizedBox(width: (screenSize.width - 80) / 8),
                            widget,
                          ]).skip(1).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Barra inferior con información
          Container(
            height: 60,
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Estado de grabación
                if (isRecording)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFEA4335),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'REC ${melody.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Estado de reproducción
                if (isPlaying && !isRecording)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF34A853),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'PLAYING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Spacer(),
                
                // Contador de notas
                if (melody.isNotEmpty)
                  Text(
                    '${melody.length} notes',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom widget para teclas negras con posicionamiento correcto
class BlackKeyWidget extends StatelessWidget {
  final Map<String, dynamic> keyData;
  final bool isPressed;
  final VoidCallback onPressed;
  final bool isLargeScreen;

  const BlackKeyWidget({
    Key? key,
    required this.keyData,
    required this.isPressed,
    required this.onPressed,
    required this.isLargeScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressed(),
      child: Container(
        width: isLargeScreen ? 35 : 30,
        decoration: BoxDecoration(
          color: isPressed ? Colors.grey[700] : Colors.black,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isPressed ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            keyData['name'],
            style: TextStyle(
              color: Colors.white,
              fontSize: isLargeScreen ? 12 : 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}