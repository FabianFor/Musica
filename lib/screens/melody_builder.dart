import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class MelodyBuilder extends StatefulWidget {
  @override
  _MelodyBuilderState createState() => _MelodyBuilderState();
}

class _MelodyBuilderState extends State<MelodyBuilder> {
  List<Map<String, dynamic>> melody = [];
  bool isRecording = false;
  bool isPlaying = false;
  int currentNote = -1;
  final AudioPlayer audioPlayer = AudioPlayer();

  // Notas del piano con diferentes sonidos
  final List<Map<String, dynamic>> notes = [
    {'name': 'Do', 'color': Color(0xFFef4444), 'soundType': 'note1'},
    {'name': 'Re', 'color': Color(0xFFf97316), 'soundType': 'note2'},
    {'name': 'Mi', 'color': Color(0xFFeab308), 'soundType': 'note3'},
    {'name': 'Fa', 'color': Color(0xFF22c55e), 'soundType': 'note4'},
    {'name': 'Sol', 'color': Color(0xFF06b6d4), 'soundType': 'note5'},
    {'name': 'La', 'color': Color(0xFF3b82f6), 'soundType': 'note6'},
    {'name': 'Si', 'color': Color(0xFF8b5cf6), 'soundType': 'note7'},
    {'name': 'Do+', 'color': Color(0xFFec4899), 'soundType': 'note8'},
  ];

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  // Reproducir nota usando diferentes tipos de vibración
  void playNote(int noteIndex) async {
    try {
      // Crear diferentes patrones de vibración para cada nota
      switch (noteIndex) {
        case 0: // Do
          HapticFeedback.lightImpact();
          break;
        case 1: // Re
          HapticFeedback.lightImpact();
          await Future.delayed(Duration(milliseconds: 100));
          HapticFeedback.lightImpact();
          break;
        case 2: // Mi
          HapticFeedback.mediumImpact();
          break;
        case 3: // Fa
          HapticFeedback.mediumImpact();
          await Future.delayed(Duration(milliseconds: 100));
          HapticFeedback.lightImpact();
          break;
        case 4: // Sol
          HapticFeedback.mediumImpact();
          await Future.delayed(Duration(milliseconds: 50));
          HapticFeedback.mediumImpact();
          break;
        case 5: // La
          HapticFeedback.heavyImpact();
          break;
        case 6: // Si
          HapticFeedback.heavyImpact();
          await Future.delayed(Duration(milliseconds: 100));
          HapticFeedback.lightImpact();
          break;
        case 7: // Do+
          HapticFeedback.heavyImpact();
          await Future.delayed(Duration(milliseconds: 50));
          HapticFeedback.heavyImpact();
          break;
        default:
          HapticFeedback.lightImpact();
      }
      
      // También agregar sonido del sistema
      SystemSound.play(SystemSoundType.click);
      
    } catch (e) {
      print('Sound error: $e');
    }
  }

  // Tocar tecla
  void handleKeyPress(int noteIndex) {
    playNote(noteIndex);
    
    if (isRecording) {
      setState(() {
        melody.add({
          'noteIndex': noteIndex,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'id': DateTime.now().millisecondsSinceEpoch + noteIndex,
        });
      });
    }
  }

  // Reproducir melodía
  void playMelody() async {
    if (melody.isEmpty) return;
    
    setState(() {
      isPlaying = true;
      currentNote = 0;
    });
    
    int startTime = melody[0]['timestamp'];
    
    for (int i = 0; i < melody.length; i++) {
      int delay = ((melody[i]['timestamp'] - startTime) * 0.3).round();
      
      Timer(Duration(milliseconds: delay), () {
        playNote(melody[i]['noteIndex']);
        setState(() {
          currentNote = i;
        });
        
        if (i == melody.length - 1) {
          Timer(Duration(milliseconds: 500), () {
            setState(() {
              isPlaying = false;
              currentNote = -1;
            });
          });
        }
      });
    }
  }

  void stopPlayback() {
    setState(() {
      isPlaying = false;
      currentNote = -1;
    });
  }

  void toggleRecording() {
    setState(() {
      isRecording = !isRecording;
      if (!isRecording && melody.isEmpty) {
        // Si no hay melodía, no hacer nada especial
      }
    });
  }

  void clearMelody() {
    setState(() {
      melody.clear();
      isRecording = false;
      isPlaying = false;
      currentNote = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Text(
                'MELODY MAKER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Controles principales
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Record button
                  GestureDetector(
                    onTap: toggleRecording,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isRecording ? Colors.red[500] : Colors.grey[500],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: (isRecording ? Colors.red : Colors.grey).withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 20),
                  
                  // Play button
                  GestureDetector(
                    onTap: melody.isEmpty ? null : (isPlaying ? stopPlayback : playMelody),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: melody.isEmpty ? Colors.grey[400] : Colors.blue[500],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: (melody.isEmpty ? Colors.grey : Colors.blue).withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 20),
                  
                  // Clear button
                  GestureDetector(
                    onTap: clearMelody,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.orange[500],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 30),
              
              // Piano virtual
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Piano Virtual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    
                    SizedBox(height: 15),
                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: notes.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> note = entry.value;
                          
                          bool isCurrentlyPlaying = currentNote != -1 && 
                            melody.isNotEmpty && 
                            currentNote < melody.length &&
                            melody[currentNote]['noteIndex'] == index && 
                            isPlaying;
                          
                          return GestureDetector(
                            onTap: () => handleKeyPress(index),
                            child: Container(
                              width: 80,
                              height: 120,
                              margin: EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: note['color'],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCurrentlyPlaying ? Colors.yellow[400]! : Colors.transparent,
                                  width: isCurrentlyPlaying ? 4 : 0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: note['color'].withOpacity(0.4),
                                    blurRadius: isCurrentlyPlaying ? 15 : 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    note['name'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Nota ${index + 1}',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Visualizador de melodía
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Tu Melodía',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      
                      SizedBox(height: 10),
                      
                      Expanded(
                        child: melody.isEmpty
                          ? Center(
                              child: Text(
                                isRecording ? 'Toca las teclas...' : 'No hay melodía',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: melody.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  Map<String, dynamic> note = entry.value;
                                  
                                  bool isCurrentlyPlaying = currentNote == index && isPlaying;
                                  
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: notes[note['noteIndex']]['color'],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCurrentlyPlaying ? Colors.yellow[400]! : Colors.transparent,
                                        width: isCurrentlyPlaying ? 3 : 0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: notes[note['noteIndex']]['color'].withOpacity(0.4),
                                          blurRadius: isCurrentlyPlaying ? 10 : 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        notes[note['noteIndex']]['name'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                      ),
                      
                      if (melody.isNotEmpty)
                        Text(
                          '${melody.length} notas grabadas',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Estado de grabación
              if (isRecording)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red[500],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'GRABANDO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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