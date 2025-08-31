import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

class MelodyBuilder extends StatefulWidget {
  @override
  _MelodyBuilderState createState() => _MelodyBuilderState();
}

class _MelodyBuilderState extends State<MelodyBuilder> {
  List<Map<String, dynamic>> melody = [];
  bool isRecording = false;
  bool isPlaying = false;
  int currentNote = -1;
  int currentPlayingNote = -1;

  // Notas del piano con colores vibrantes como Chrome Music Lab
  final List<Map<String, dynamic>> notes = [
    {'name': 'C', 'fullName': 'Do', 'color': Color(0xFFE91E63), 'frequency': 261.63},
    {'name': 'D', 'fullName': 'Re', 'color': Color(0xFF9C27B0), 'frequency': 293.66},
    {'name': 'E', 'fullName': 'Mi', 'color': Color(0xFF673AB7), 'frequency': 329.63},
    {'name': 'F', 'fullName': 'Fa', 'color': Color(0xFF3F51B5), 'frequency': 349.23},
    {'name': 'G', 'fullName': 'Sol', 'color': Color(0xFF2196F3), 'frequency': 392.00},
    {'name': 'A', 'fullName': 'La', 'color': Color(0xFF03A9F4), 'frequency': 440.00},
    {'name': 'B', 'fullName': 'Si', 'color': Color(0xFF00BCD4), 'frequency': 493.88},
    {'name': 'C+', 'fullName': 'Do+', 'color': Color(0xFF009688), 'frequency': 523.25},
  ];

  @override
  void dispose() {
    super.dispose();
  }

  // Reproducir nota con patrones de vibración únicos
  void playNote(int noteIndex) async {
    try {
      double frequency = notes[noteIndex]['frequency'];
      
      // Crear patrones de vibración únicos basados en la frecuencia
      if (frequency < 300) {
        // Notas graves
        HapticFeedback.heavyImpact();
        await Future.delayed(Duration(milliseconds: 100));
        HapticFeedback.mediumImpact();
      } else if (frequency < 350) {
        HapticFeedback.mediumImpact();
        await Future.delayed(Duration(milliseconds: 80));
        HapticFeedback.lightImpact();
      } else if (frequency < 400) {
        HapticFeedback.mediumImpact();
      } else if (frequency < 450) {
        HapticFeedback.lightImpact();
        await Future.delayed(Duration(milliseconds: 50));
        HapticFeedback.selectionClick();
      } else if (frequency < 500) {
        HapticFeedback.lightImpact();
      } else {
        // Notas agudas
        HapticFeedback.selectionClick();
        await Future.delayed(Duration(milliseconds: 30));
        HapticFeedback.selectionClick();
      }
      
      SystemSound.play(SystemSoundType.click);
      
    } catch (e) {
      print('Sound error: $e');
    }
  }

  void handleKeyPress(int noteIndex) {
    playNote(noteIndex);
    
    setState(() {
      currentPlayingNote = noteIndex;
    });
    
    // Reset visual feedback después de un tiempo
    Timer(Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          currentPlayingNote = -1;
        });
      }
    });
    
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

  void playMelody() async {
    if (melody.isEmpty) return;
    
    setState(() {
      isPlaying = true;
      currentNote = 0;
    });
    
    int startTime = melody[0]['timestamp'];
    
    for (int i = 0; i < melody.length; i++) {
      int delay = ((melody[i]['timestamp'] - startTime) * 0.4).round();
      
      Timer(Duration(milliseconds: delay), () {
        if (mounted && isPlaying) {
          playNote(melody[i]['noteIndex']);
          setState(() {
            currentNote = i;
            currentPlayingNote = melody[i]['noteIndex'];
          });
          
          // Reset visual feedback
          Timer(Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                currentPlayingNote = -1;
              });
            }
          });
          
          if (i == melody.length - 1) {
            Timer(Duration(milliseconds: 800), () {
              if (mounted) {
                setState(() {
                  isPlaying = false;
                  currentNote = -1;
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
      currentNote = -1;
      currentPlayingNote = -1;
    });
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
      currentNote = -1;
      currentPlayingNote = -1;
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header minimalista
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Color(0xFF4285F4), size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'MELODY MAKER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3C4043),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            
            // Controles principales
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Record button
                  Container(
                    width: 56,
                    height: 56,
                    child: Material(
                      color: isRecording ? Color(0xFFEA4335) : Color(0xFF5F6368),
                      borderRadius: BorderRadius.circular(28),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: toggleRecording,
                        child: Icon(
                          Icons.fiber_manual_record,
                          color: Colors.white,
                          size: isRecording ? 32 : 24,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 20),
                  
                  // Play button
                  Container(
                    width: 56,
                    height: 56,
                    child: Material(
                      color: melody.isEmpty ? Color(0xFFE8EAED) : Color(0xFF4285F4),
                      borderRadius: BorderRadius.circular(28),
                      elevation: melody.isEmpty ? 0 : 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: melody.isEmpty ? null : (isPlaying ? stopPlayback : playMelody),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: melody.isEmpty ? Color(0xFF9AA0A6) : Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 20),
                  
                  // Clear button
                  Container(
                    height: 40,
                    child: TextButton.icon(
                      onPressed: clearMelody,
                      icon: Icon(Icons.clear, color: Color(0xFF5F6368), size: 18),
                      label: Text(
                        'Clear',
                        style: TextStyle(
                          color: Color(0xFF5F6368),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Piano virtual estilo Chrome Music Lab
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Virtual Piano',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3C4043),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Teclas del piano en dos filas para mejor acceso
                  Column(
                    children: [
                      // Primera fila (Do, Re, Mi, Fa)
                      Row(
                        children: notes.take(4).toList().asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> note = entry.value;
                          
                          bool isCurrentlyPlaying = currentPlayingNote == index;
                          bool isMelodyPlaying = currentNote != -1 && 
                            melody.isNotEmpty && 
                            currentNote < melody.length &&
                            melody[currentNote]['noteIndex'] == index && 
                            isPlaying;
                          
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => handleKeyPress(index),
                              child: Container(
                                height: 80,
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: note['color'],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (isCurrentlyPlaying || isMelodyPlaying) 
                                      ? Colors.white 
                                      : Colors.transparent,
                                    width: (isCurrentlyPlaying || isMelodyPlaying) ? 3 : 0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: note['color'].withOpacity(0.4),
                                      blurRadius: (isCurrentlyPlaying || isMelodyPlaying) ? 20 : 8,
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
                                      note['fullName'],
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Segunda fila (Sol, La, Si, Do+)
                      Row(
                        children: notes.skip(4).toList().asMap().entries.map((entry) {
                          int index = entry.key + 4;
                          Map<String, dynamic> note = entry.value;
                          
                          bool isCurrentlyPlaying = currentPlayingNote == index;
                          bool isMelodyPlaying = currentNote != -1 && 
                            melody.isNotEmpty && 
                            currentNote < melody.length &&
                            melody[currentNote]['noteIndex'] == index && 
                            isPlaying;
                          
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => handleKeyPress(index),
                              child: Container(
                                height: 80,
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: note['color'],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (isCurrentlyPlaying || isMelodyPlaying) 
                                      ? Colors.white 
                                      : Colors.transparent,
                                    width: (isCurrentlyPlaying || isMelodyPlaying) ? 3 : 0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: note['color'].withOpacity(0.4),
                                      blurRadius: (isCurrentlyPlaying || isMelodyPlaying) ? 20 : 8,
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
                                      note['fullName'],
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Visualizador de melodía
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Melody',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3C4043),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    Expanded(
                      child: melody.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isRecording ? Icons.fiber_manual_record : Icons.music_note_outlined,
                                  size: 48,
                                  color: isRecording ? Color(0xFFEA4335) : Color(0xFF9AA0A6),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  isRecording ? 'Recording... play some notes!' : 'No melody recorded yet',
                                  style: TextStyle(
                                    color: Color(0xFF9AA0A6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: notes[note['noteIndex']]['color'],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCurrentlyPlaying ? Colors.white : Colors.transparent,
                                      width: isCurrentlyPlaying ? 3 : 0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: notes[note['noteIndex']]['color'].withOpacity(0.4),
                                        blurRadius: isCurrentlyPlaying ? 12 : 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      notes[note['noteIndex']]['name'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                    ),
                    
                    if (melody.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${melody.length} notes recorded',
                          style: TextStyle(
                            color: Color(0xFF5F6368),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Estado de grabación/reproducción
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isRecording)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFFEA4335),
                        borderRadius: BorderRadius.circular(16),
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
                            'RECORDING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (isPlaying)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF34A853),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Playing note ${(currentNote ?? 0) + 1} of ${melody.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}