import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SoundGenerator {
  static void playFrequency(double frequency) async {
    try {
      if (frequency > 800) {
        HapticFeedback.selectionClick();
        await Future.delayed(Duration(milliseconds: 50));
        HapticFeedback.selectionClick();
      } else if (frequency > 600) {
        HapticFeedback.lightImpact();
        await Future.delayed(Duration(milliseconds: 80));
        HapticFeedback.lightImpact();
      } else if (frequency > 400) {
        HapticFeedback.mediumImpact();
      } else if (frequency > 300) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.heavyImpact();
        await Future.delayed(Duration(milliseconds: 100));
        HapticFeedback.heavyImpact();
      }
      SystemSound.play(SystemSoundType.click);
    } catch (e) {
      print('Error playing sound: $e');
    }
  }
}

class GridComposer extends StatefulWidget {
  @override
  _GridComposerState createState() => _GridComposerState();
}

class _GridComposerState extends State<GridComposer> {
  // Grid de 16x16 para máxima flexibilidad
  List<List<bool>> grid = List.generate(16, (i) => List.generate(16, (j) => false));
  bool isPlaying = false;
  int currentBeat = 0;
  int tempo = 120;
  Timer? playbackTimer;
  bool isDragging = false;
  bool dragValue = false;

  // Instrumentos con frecuencias reales como Chrome Music Lab
  final List<Map<String, dynamic>> instruments = [
    {'color': Color(0xFFF44336), 'frequency': 1046.5}, // C6 - Rojo
    {'color': Color(0xFFE91E63), 'frequency': 987.8},  // B5 - Rosa
    {'color': Color(0xFF9C27B0), 'frequency': 880.0},  // A5 - Púrpura
    {'color': Color(0xFF673AB7), 'frequency': 783.99}, // G5 - Púrpura profundo
    {'color': Color(0xFF3F51B5), 'frequency': 698.46}, // F5 - Índigo
    {'color': Color(0xFF2196F3), 'frequency': 659.25}, // E5 - Azul
    {'color': Color(0xFF03A9F4), 'frequency': 587.33}, // D5 - Azul claro
    {'color': Color(0xFF00BCD4), 'frequency': 523.25}, // C5 - Cian
    {'color': Color(0xFF009688), 'frequency': 466.16}, // A#4 - Verde azulado
    {'color': Color(0xFF4CAF50), 'frequency': 415.30}, // G#4 - Verde
    {'color': Color(0xFF8BC34A), 'frequency': 369.99}, // F#4 - Verde lima
    {'color': Color(0xFFCDDC39), 'frequency': 329.63}, // E4 - Lima
    {'color': Color(0xFFFFEB3B), 'frequency': 293.66}, // D4 - Amarillo
    {'color': Color(0xFFFFC107), 'frequency': 261.63}, // C4 - Ámbar
    {'color': Color(0xFFFF9800), 'frequency': 246.94}, // B3 - Naranja
    {'color': Color(0xFFFF5722), 'frequency': 220.00}, // A3 - Naranja profundo
  ];

  @override
  void initState() {
    super.initState();
    // Forzar orientación horizontal
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    playbackTimer?.cancel();
    // Restaurar orientaciones
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void playSound(int instrumentIndex) {
    double frequency = instruments[instrumentIndex]['frequency'].toDouble();
    SoundGenerator.playFrequency(frequency);
  }

  void handleCellInteraction(int row, int col, bool value) {
    setState(() {
      grid[row][col] = value;
    });
    
    if (value) {
      playSound(row);
    }
  }

  void onPanStart(DragStartDetails details, int row, int col) {
    setState(() {
      isDragging = true;
      dragValue = !grid[row][col];
      grid[row][col] = dragValue;
    });
    
    if (dragValue) {
      playSound(row);
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (!isDragging) return;
    
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // Calcular qué celda está siendo tocada
    double cellWidth = (renderBox.size.width - 100) / 16; // 100px para labels
    double cellHeight = 30;
    
    int col = ((localPosition.dx - 100) / cellWidth).floor();
    int row = ((localPosition.dy - 120) / cellHeight).floor(); // 120px para header
    
    if (row >= 0 && row < 16 && col >= 0 && col < 16) {
      if (grid[row][col] != dragValue) {
        setState(() {
          grid[row][col] = dragValue;
        });
        
        if (dragValue) {
          playSound(row);
        }
      }
    }
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      isDragging = false;
    });
  }

  void togglePlay() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      int beatDuration = (60000 / tempo / 4).round();
      
      playbackTimer = Timer.periodic(Duration(milliseconds: beatDuration), (timer) {
        setState(() {
          currentBeat = (currentBeat + 1) % 16;
        });
        
        for (int row = 0; row < 16; row++) {
          if (grid[row][currentBeat]) {
            playSound(row);
          }
        }
      });
    } else {
      playbackTimer?.cancel();
    }
  }

  void clearGrid() {
    setState(() {
      grid = List.generate(16, (i) => List.generate(16, (j) => false));
      currentBeat = 0;
      isPlaying = false;
    });
    playbackTimer?.cancel();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            // Panel lateral izquierdo
            Container(
              width: 200,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                border: Border(
                  right: BorderSide(color: Color(0xFFE8EAED), width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Text(
                    'SONG MAKER',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3C4043),
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Play button
                  Container(
                    width: 64,
                    height: 64,
                    child: Material(
                      color: Color(0xFF4285F4),
                      borderRadius: BorderRadius.circular(32),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(32),
                        onTap: togglePlay,
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Clear button
                  TextButton.icon(
                    onPressed: clearGrid,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Control de tempo
                  Text(
                    'Tempo',
                    style: TextStyle(
                      color: Color(0xFF5F6368),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Color(0xFF4285F4),
                      inactiveTrackColor: Color(0xFFE8EAED),
                      thumbColor: Color(0xFF4285F4),
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: tempo.toDouble(),
                      min: 60,
                      max: 200,
                      divisions: 140,
                      onChanged: (value) {
                        setState(() {
                          tempo = value.round();
                        });
                      },
                    ),
                  ),
                  
                  Text(
                    '$tempo',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  Spacer(),
                  
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios, color: Color(0xFF4285F4)),
                  ),
                ],
              ),
            ),
            
            // Grid principal
            Expanded(
              child: Column(
                children: [
                  // Header con números de beat
                  Container(
                    height: 50,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 100), // Espacio para alinear
                        ...List.generate(16, (i) {
                          bool isCurrentBeat = currentBeat == i && isPlaying;
                          return Expanded(
                            child: Container(
                              height: 32,
                              margin: EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isCurrentBeat ? Color(0xFF4285F4) : Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isCurrentBeat ? Color(0xFF4285F4) : Color(0xFFE8EAED),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: isCurrentBeat ? Colors.white : Color(0xFF9AA0A6),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  
                  // Grid de instrumentos
                  Expanded(
                    child: GestureDetector(
                      onPanStart: (details) {
                        RenderBox renderBox = context.findRenderObject() as RenderBox;
                        Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                        
                        double cellWidth = (renderBox.size.width - 100) / 16;
                        int col = ((localPosition.dx - 100) / cellWidth).floor();
                        int row = ((localPosition.dy - 50) / 30).floor();
                        
                        if (row >= 0 && row < 16 && col >= 0 && col < 16) {
                          onPanStart(details, row, col);
                        }
                      },
                      onPanUpdate: onPanUpdate,
                      onPanEnd: onPanEnd,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: List.generate(16, (rowIndex) => Container(
                            height: 30,
                            margin: EdgeInsets.symmetric(vertical: 1),
                            child: Row(
                              children: [
                                // Indicador de color del instrumento
                                Container(
                                  width: 100,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: instruments[rowIndex]['color'],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${(instruments[rowIndex]['frequency'] as double).round()}Hz',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Celdas del grid
                                ...List.generate(16, (colIndex) {
                                  bool isActive = grid[rowIndex][colIndex];
                                  bool isCurrentBeat = currentBeat == colIndex && isPlaying;
                                  
                                  return Expanded(
                                    child: Container(
                                      height: 28,
                                      margin: EdgeInsets.symmetric(horizontal: 1),
                                      decoration: BoxDecoration(
                                        color: isActive 
                                          ? instruments[rowIndex]['color']
                                          : (isCurrentBeat ? Color(0xFFE3F2FD) : Color(0xFFF8F9FA)),
                                        borderRadius: BorderRadius.circular(2),
                                        border: isCurrentBeat ? Border.all(
                                          color: Color(0xFF4285F4),
                                          width: 2,
                                        ) : Border.all(
                                          color: Color(0xFFE8EAED),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          )),
                        ),
                      ),
                    ),
                  ),
                  
                  // Estado de reproducción
                  Container(
                    height: 40,
                    child: isPlaying 
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFF34A853),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Playing beat ${currentBeat + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : SizedBox.shrink(),
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