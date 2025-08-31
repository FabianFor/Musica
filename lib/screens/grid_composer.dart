import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/audio_service.dart';

class GridComposer extends StatefulWidget {
  @override
  _GridComposerState createState() => _GridComposerState();
}

class _GridComposerState extends State<GridComposer> {
  List<List<bool>> grid = List.generate(12, (i) => List.generate(16, (j) => false));
  bool isPlaying = false;
  int currentBeat = 0;
  int tempo = 120;
  Timer? playbackTimer;
  bool isDragging = false;
  bool dragValue = false;
  String selectedInstrument = 'Piano';

  // Instrumentos con diferentes timbres
  final Map<String, List<Map<String, dynamic>>> instruments = {
    'Piano': [
      {'color': Color(0xFFE91E63), 'frequency': 1046.5},
      {'color': Color(0xFF9C27B0), 'frequency': 987.8},
      {'color': Color(0xFF673AB7), 'frequency': 880.0},
      {'color': Color(0xFF3F51B5), 'frequency': 783.99},
      {'color': Color(0xFF2196F3), 'frequency': 698.46},
      {'color': Color(0xFF03A9F4), 'frequency': 659.25},
      {'color': Color(0xFF00BCD4), 'frequency': 587.33},
      {'color': Color(0xFF009688), 'frequency': 523.25},
      {'color': Color(0xFF4CAF50), 'frequency': 466.16},
      {'color': Color(0xFF8BC34A), 'frequency': 415.30},
      {'color': Color(0xFFFFEB3B), 'frequency': 369.99},
      {'color': Color(0xFFFF9800), 'frequency': 329.63},
    ],
    'Flauta': [
      {'color': Color(0xFFE3F2FD), 'frequency': 2093.0},
      {'color': Color(0xFFBBDEFB), 'frequency': 1975.5},
      {'color': Color(0xFF90CAF9), 'frequency': 1760.0},
      {'color': Color(0xFF64B5F6), 'frequency': 1568.0},
      {'color': Color(0xFF42A5F5), 'frequency': 1396.9},
      {'color': Color(0xFF2196F3), 'frequency': 1318.5},
      {'color': Color(0xFF1E88E5), 'frequency': 1174.7},
      {'color': Color(0xFF1976D2), 'frequency': 1046.5},
      {'color': Color(0xFF1565C0), 'frequency': 932.3},
      {'color': Color(0xFF0D47A1), 'frequency': 830.6},
      {'color': Color(0xFF0A3A7A), 'frequency': 740.0},
      {'color': Color(0xFF082E5C), 'frequency': 659.3},
    ],
    'Guitarra': [
      {'color': Color(0xFFFFE0B2), 'frequency': 659.25},
      {'color': Color(0xFFFFCC02), 'frequency': 587.33},
      {'color': Color(0xFFFFB300), 'frequency': 523.25},
      {'color': Color(0xFFFF8F00), 'frequency': 466.16},
      {'color': Color(0xFFFF6F00), 'frequency': 415.30},
      {'color': Color(0xFFE65100), 'frequency': 369.99},
      {'color': Color(0xFFBF360C), 'frequency': 329.63},
      {'color': Color(0xFF8D2F00), 'frequency': 293.66},
      {'color': Color(0xFF5D1F00), 'frequency': 261.63},
      {'color': Color(0xFF4E1600), 'frequency': 246.94},
      {'color': Color(0xFF3E0E00), 'frequency': 220.00},
      {'color': Color(0xFF2E0A00), 'frequency': 196.00},
    ],
  };

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
    playbackTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void playSound(int instrumentIndex) {
    double frequency = instruments[selectedInstrument]![instrumentIndex]['frequency'].toDouble();
    AudioService.playFrequency(frequency, duration: 0.2);
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
        
        List<double> activeFrequencies = [];
        for (int row = 0; row < 12; row++) {
          if (grid[row][currentBeat]) {
            activeFrequencies.add(instruments[selectedInstrument]![row]['frequency'].toDouble());
          }
        }
        
        if (activeFrequencies.length > 1) {
          AudioService.playChord(activeFrequencies, duration: 0.15);
        } else if (activeFrequencies.length == 1) {
          AudioService.playFrequency(activeFrequencies[0], duration: 0.15);
        }
      });
    } else {
      playbackTimer?.cancel();
      AudioService.stop();
    }
  }

  void clearGrid() {
    setState(() {
      grid = List.generate(12, (i) => List.generate(16, (j) => false));
      currentBeat = 0;
      isPlaying = false;
    });
    playbackTimer?.cancel();
    AudioService.stop();
    HapticFeedback.mediumImpact();
  }

  void changeInstrument() {
    List<String> instrumentNames = instruments.keys.toList();
    int currentIndex = instrumentNames.indexOf(selectedInstrument);
    int nextIndex = (currentIndex + 1) % instrumentNames.length;
    
    setState(() {
      selectedInstrument = instrumentNames[nextIndex];
    });
    
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 800;
    
    // Calcular tamaños responsivos
    final double cellWidth = (screenSize.width - 40) / 16; // 40px margen total
    final double cellHeight = isLargeScreen ? 35 : 30;
    final double headerHeight = isLargeScreen ? 70 : 60;
    final double bottomHeight = isLargeScreen ? 80 : 70;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "SONG MAKER",
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue),
            onPressed: clearGrid,
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicadores de beat
          Container(
            height: headerHeight,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: List.generate(16, (i) {
                bool isCurrentBeat = currentBeat == i && isPlaying;
                return Container(
                  width: cellWidth,
                  height: isLargeScreen ? 30 : 25,
                  margin: EdgeInsets.symmetric(horizontal: 0.5),
                  decoration: BoxDecoration(
                    color: isCurrentBeat ? Color(0xFF4285F4) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isCurrentBeat ? Color(0xFF4285F4) : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: isCurrentBeat ? Colors.white : Colors.grey[600],
                        fontSize: isLargeScreen ? 12 : 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Grid de instrumentos - usa todo el espacio disponible
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                if (renderBox == null) return;
                
                Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                
                int col = (localPosition.dx / cellWidth).floor();
                int row = ((localPosition.dy - headerHeight) / cellHeight).floor();
                
                if (row >= 0 && row < 12 && col >= 0 && col < 16) {
                  setState(() {
                    isDragging = true;
                    dragValue = !grid[row][col];
                    grid[row][col] = dragValue;
                  });
                  
                  if (dragValue) {
                    playSound(row);
                    HapticFeedback.selectionClick();
                  }
                }
              },
              onPanUpdate: (details) {
                if (!isDragging) return;
                
                RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                if (renderBox == null) return;
                
                Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                
                int col = (localPosition.dx / cellWidth).floor();
                int row = ((localPosition.dy - headerHeight) / cellHeight).floor();
                
                if (row >= 0 && row < 12 && col >= 0 && col < 16) {
                  if (grid[row][col] != dragValue) {
                    setState(() {
                      grid[row][col] = dragValue;
                    });
                    
                    if (dragValue) {
                      playSound(row);
                    }
                  }
                }
              },
              onPanEnd: (details) {
                setState(() {
                  isDragging = false;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: List.generate(12, (rowIndex) => Container(
                    height: cellHeight,
                    margin: EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      children: List.generate(16, (colIndex) {
                        bool isActive = grid[rowIndex][colIndex];
                        bool isCurrentBeat = currentBeat == colIndex && isPlaying;
                        
                        return Container(
                          width: cellWidth,
                          height: cellHeight - 2,
                          margin: EdgeInsets.symmetric(horizontal: 0.5),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                grid[rowIndex][colIndex] = !grid[rowIndex][colIndex];
                              });
                              
                              if (grid[rowIndex][colIndex]) {
                                playSound(rowIndex);
                                HapticFeedback.selectionClick();
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isActive 
                                  ? instruments[selectedInstrument]![rowIndex]['color']
                                  : (isCurrentBeat ? Colors.blue.withOpacity(0.1) : Colors.white),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isCurrentBeat 
                                    ? Color(0xFF4285F4) 
                                    : (isActive 
                                      ? instruments[selectedInstrument]![rowIndex]['color'] 
                                      : Colors.grey[300]!),
                                  width: isCurrentBeat ? 2 : 1,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  )),
                ),
              ),
            ),
          ),
          
          // Barra inferior
          Container(
            height: bottomHeight,
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Play button
                IconButton(
                  onPressed: togglePlay,
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: Colors.blue, 
                    size: isLargeScreen ? 50 : 40,
                  ),
                ),
                
                SizedBox(width: 8),
                
                // Selector de instrumento
                GestureDetector(
                  onTap: changeInstrument,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectedInstrument == 'Piano' ? Icons.piano 
                          : selectedInstrument == 'Flauta' ? Icons.air
                          : Icons.music_note,
                          color: Colors.blue,
                          size: isLargeScreen ? 20 : 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          selectedInstrument,
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: isLargeScreen ? 14 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Spacer(),
                
                // Control de tempo
                Text(
                  "Tempo",
                  style: TextStyle(
                    fontSize: isLargeScreen ? 14 : 12,
                    color: Colors.grey[700],
                  ),
                ),
                Container(
                  width: isLargeScreen ? 120 : 80,
                  child: Slider(
                    value: tempo.toDouble(),
                    min: 60,
                    max: 200,
                    onChanged: (value) {
                      setState(() {
                        tempo = value.round();
                      });
                    },
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey[300],
                  ),
                ),
                Text(
                  "$tempo",
                  style: TextStyle(
                    fontSize: isLargeScreen ? 14 : 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                SizedBox(width: 8),
                
                // Clear button
                IconButton(
                  onPressed: clearGrid,
                  icon: Icon(
                    Icons.delete_outline, 
                    color: Colors.red[400],
                    size: isLargeScreen ? 24 : 20,
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