import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class GridComposer extends StatefulWidget {
  @override
  _GridComposerState createState() => _GridComposerState();
}

class _GridComposerState extends State<GridComposer> {
  List<List<bool>> grid = List.generate(8, (i) => List.generate(16, (j) => false));
  bool isPlaying = false;
  int currentBeat = 0;
  int tempo = 120;
  Timer? playbackTimer;

  final AudioPlayer audioPlayer = AudioPlayer();

  // Instrumentos con colores y tipos de sonido
  final List<Map<String, dynamic>> instruments = [
    {'name': 'High', 'color': Color(0xFF6366f1), 'sound': 'high1'},
    {'name': 'Mid High', 'color': Color(0xFF8b5cf6), 'sound': 'high2'},
    {'name': 'Mid', 'color': Color(0xFFa855f7), 'sound': 'mid1'},
    {'name': 'Mid Low', 'color': Color(0xFFc084fc), 'sound': 'mid2'},
    {'name': 'Low', 'color': Color(0xFFd8b4fe), 'sound': 'low1'},
    {'name': 'Bass', 'color': Color(0xFFe879f9), 'sound': 'low2'},
    {'name': 'Kick', 'color': Color(0xFFf472b6), 'sound': 'kick'},
    {'name': 'Deep', 'color': Color(0xFFfb7185), 'sound': 'bass'},
  ];

  @override
  void dispose() {
    playbackTimer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  // Generar y reproducir tono usando feedback haptico
  void playSound(int instrumentIndex) async {
    try {
      // Usar diferentes tipos de vibración según el instrumento
      if (instrumentIndex < 2) {
        // Tonos altos
        HapticFeedback.lightImpact();
      } else if (instrumentIndex < 5) {
        // Tonos medios
        HapticFeedback.mediumImpact();
      } else {
        // Tonos bajos
        HapticFeedback.heavyImpact();
      }
      
      // También puedes usar sonidos del sistema si están disponibles
      SystemSound.play(SystemSoundType.click);
    } catch (e) {
      print('Sound error: $e');
    }
  }

  // Toggle celda del grid
  void toggleCell(int row, int col) {
    setState(() {
      grid[row][col] = !grid[row][col];
    });
    
    if (grid[row][col]) {
      playSound(row);
    }
  }

  // Controlar reproducción
  void togglePlay() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      int beatDuration = (60000 / tempo / 4).round(); // en milisegundos
      
      playbackTimer = Timer.periodic(Duration(milliseconds: beatDuration), (timer) {
        setState(() {
          currentBeat = (currentBeat + 1) % 16;
        });
        
        // Reproducir sonidos de la columna actual
        for (int row = 0; row < 8; row++) {
          if (grid[row][currentBeat]) {
            playSound(row);
          }
        }
      });
    } else {
      playbackTimer?.cancel();
    }
  }

  void stopPlayback() {
    setState(() {
      isPlaying = false;
      currentBeat = 0;
    });
    playbackTimer?.cancel();
  }

  void clearGrid() {
    setState(() {
      grid = List.generate(8, (i) => List.generate(16, (j) => false));
      currentBeat = 0;
      isPlaying = false;
    });
    playbackTimer?.cancel();
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
                'SONG MAKER',
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
                  // Play/Pause button
                  GestureDetector(
                    onTap: togglePlay,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue[500],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
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
                    onTap: clearGrid,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[500],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
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
              
              SizedBox(height: 20),
              
              // Control de tempo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tempo', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  SizedBox(width: 15),
                  Container(
                    width: 200,
                    child: Slider(
                      value: tempo.toDouble(),
                      min: 60,
                      max: 200,
                      divisions: 140,
                      activeColor: Colors.blue[500],
                      onChanged: (value) {
                        setState(() {
                          tempo = value.round();
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 15),
                  Container(
                    width: 40,
                    child: Text(
                      '$tempo',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 30),
              
              // Grid principal
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Header con números
                        Row(
                          children: [
                            SizedBox(width: 80), // Espacio para labels
                            ...List.generate(16, (i) => Container(
                              width: 40,
                              height: 30,
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )),
                          ],
                        ),
                        
                        // Filas de instrumentos
                        ...List.generate(8, (rowIndex) => Row(
                          children: [
                            // Label del instrumento
                            Container(
                              width: 80,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: instruments[rowIndex]['color'],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                instruments[rowIndex]['name'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            
                            // Celdas del grid
                            ...List.generate(16, (colIndex) => GestureDetector(
                              onTap: () => toggleCell(rowIndex, colIndex),
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: grid[rowIndex][colIndex] 
                                    ? instruments[rowIndex]['color'] 
                                    : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: currentBeat == colIndex && isPlaying
                                      ? Colors.blue[400]!
                                      : grid[rowIndex][colIndex] 
                                        ? Colors.grey[600]! 
                                        : Colors.grey[300]!,
                                    width: currentBeat == colIndex && isPlaying ? 3 : 2,
                                  ),
                                  boxShadow: grid[rowIndex][colIndex] ? [
                                    BoxShadow(
                                      color: instruments[rowIndex]['color'].withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ] : [],
                                ),
                              ),
                            )),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Indicador de beat
              if (isPlaying)
                Container(
                  margin: EdgeInsets.only(top: 20),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue[500],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Beat: ${currentBeat + 1}',
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