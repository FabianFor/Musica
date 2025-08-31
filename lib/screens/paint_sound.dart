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

class PaintSound extends StatefulWidget {
  @override
  _PaintSoundState createState() => _PaintSoundState();
}

class _PaintSoundState extends State<PaintSound> {
  List<List<Offset>> strokes = [];
  List<Color> strokeColors = [];
  List<List<int>> strokeTimestamps = [];
  
  List<Offset> currentStroke = [];
  List<int> currentTimestamps = [];
  
  Color selectedColor = Color(0xFFE91E63);
  bool isPlaying = false;
  bool isDrawing = false;
  int playbackIndex = -1;

  // Colores con frecuencias como Chrome Music Lab
  final Map<Color, Map<String, dynamic>> colorSounds = {
    Color(0xFFE91E63): {'name': 'C5', 'frequency': 523.25},
    Color(0xFF9C27B0): {'name': 'D5', 'frequency': 587.33},
    Color(0xFF673AB7): {'name': 'E5', 'frequency': 659.25},
    Color(0xFF3F51B5): {'name': 'F5', 'frequency': 698.46},
    Color(0xFF2196F3): {'name': 'G5', 'frequency': 783.99},
    Color(0xFF03A9F4): {'name': 'A5', 'frequency': 880.00},
    Color(0xFF00BCD4): {'name': 'B5', 'frequency': 987.77},
    Color(0xFF009688): {'name': 'C6', 'frequency': 1046.5},
  };

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
    // Restaurar orientaciones
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void playSound(Color color) {
    double frequency = colorSounds[color]?['frequency']?.toDouble() ?? 523.25;
    SoundGenerator.playFrequency(frequency);
  }

  void startDrawing(Offset position) {
    setState(() {
      isDrawing = true;
      currentStroke = [position];
      currentTimestamps = [DateTime.now().millisecondsSinceEpoch];
    });
    playSound(selectedColor);
  }

  void draw(Offset position) {
    if (!isDrawing) return;
    
    setState(() {
      currentStroke.add(position);
      currentTimestamps.add(DateTime.now().millisecondsSinceEpoch);
    });
    
    // Reproducir sonido cada cierto número de puntos para líneas suaves
    if (currentStroke.length % 10 == 0) {
      playSound(selectedColor);
    }
  }

  void stopDrawing() {
    if (isDrawing && currentStroke.isNotEmpty) {
      setState(() {
        strokes.add(List.from(currentStroke));
        strokeColors.add(selectedColor);
        strokeTimestamps.add(List.from(currentTimestamps));
        currentStroke.clear();
        currentTimestamps.clear();
        isDrawing = false;
      });
    }
  }

  void playComposition() async {
    if (strokes.isEmpty) return;
    
    setState(() {
      isPlaying = true;
      playbackIndex = 0;
    });

    List<Map<String, dynamic>> allPoints = [];
    
    for (int i = 0; i < strokes.length; i++) {
      // Solo reproducir cada 5 puntos para no saturar
      for (int j = 0; j < strokes[i].length; j += 5) {
        allPoints.add({
          'timestamp': strokeTimestamps[i][j],
          'color': strokeColors[i],
          'strokeIndex': i,
          'pointIndex': j,
        });
      }
    }
    
    allPoints.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    
    if (allPoints.isEmpty) {
      setState(() {
        isPlaying = false;
        playbackIndex = -1;
      });
      return;
    }
    
    int startTime = allPoints[0]['timestamp'];
    
    for (int i = 0; i < allPoints.length; i++) {
      int delay = ((allPoints[i]['timestamp'] - startTime) * 0.3).round();
      
      Timer(Duration(milliseconds: delay), () {
        if (mounted && isPlaying) {
          playSound(allPoints[i]['color']);
          setState(() {
            playbackIndex = i;
          });
          
          if (i == allPoints.length - 1) {
            Timer(Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  isPlaying = false;
                  playbackIndex = -1;
                });
              }
            });
          }
        }
      });
    }
  }

  void clearCanvas() {
    setState(() {
      strokes.clear();
      strokeColors.clear();
      strokeTimestamps.clear();
      currentStroke.clear();
      currentTimestamps.clear();
      isPlaying = false;
      playbackIndex = -1;
    });
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
              width: 250,
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
                    'PAINT & SOUND',
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
                      color: strokes.isEmpty ? Color(0xFFE8EAED) : Color(0xFF4285F4),
                      borderRadius: BorderRadius.circular(32),
                      elevation: strokes.isEmpty ? 0 : 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(32),
                        onTap: strokes.isEmpty ? null : (isPlaying ? () {
                          setState(() {
                            isPlaying = false;
                            playbackIndex = -1;
                          });
                        } : playComposition),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: strokes.isEmpty ? Color(0xFF9AA0A6) : Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Clear button
                  TextButton.icon(
                    onPressed: clearCanvas,
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
                  
                  // Paleta de colores
                  Text(
                    'Color Palette',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3C4043),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Grid de colores 2x4
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: colorSounds.keys.take(4).map((color) {
                          bool isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                              playSound(color);
                              HapticFeedback.selectionClick();
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? Color(0xFF4285F4) : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: isSelected ? 12 : 6,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      SizedBox(height: 12),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: colorSounds.keys.skip(4).map((color) {
                          bool isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                              playSound(color);
                              HapticFeedback.selectionClick();
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? Color(0xFF4285F4) : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: isSelected ? 12 : 6,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Información del color seleccionado
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      colorSounds[selectedColor]?['name'] ?? '',
                      style: TextStyle(
                        color: selectedColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  Spacer(),
                  
                  // Estado de reproducción
                  if (isPlaying)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            'Playing...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: 16),
                  
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios, color: Color(0xFF4285F4)),
                  ),
                ],
              ),
            ),
            
            // Canvas para dibujar
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFE8EAED), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      // Canvas principal
                      GestureDetector(
                        onPanStart: (details) {
                          RenderBox renderBox = context.findRenderObject() as RenderBox;
                          Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                          startDrawing(localPosition);
                        },
                        onPanUpdate: (details) {
                          RenderBox renderBox = context.findRenderObject() as RenderBox;
                          Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                          draw(localPosition);
                        },
                        onPanEnd: (details) {
                          stopDrawing();
                        },
                        child: CustomPaint(
                          painter: SmoothDrawingPainter(
                            strokes: strokes,
                            strokeColors: strokeColors,
                            currentStroke: currentStroke,
                            currentColor: selectedColor,
                            isPlaying: isPlaying,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                      
                      // Placeholder cuando está vacío
                      if (strokes.isEmpty && currentStroke.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.brush_outlined,
                                size: 64,
                                color: Color(0xFFE8EAED),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Draw something to create music!',
                                style: TextStyle(
                                  color: Color(0xFF9AA0A6),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Use your finger to draw and hear the sounds',
                                style: TextStyle(
                                  color: Color(0xFFBDC1C6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter mejorado para líneas suaves
class SmoothDrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Color> strokeColors;
  final List<Offset> currentStroke;
  final Color currentColor;
  final bool isPlaying;

  SmoothDrawingPainter({
    required this.strokes,
    required this.strokeColors,
    required this.currentStroke,
    required this.currentColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Dibujar trazos guardados con líneas suaves
    for (int i = 0; i < strokes.length; i++) {
      if (strokes[i].length < 2) continue;
      
      paint.color = strokeColors[i];
      
      final path = Path();
      path.moveTo(strokes[i][0].dx, strokes[i][0].dy);
      
      // Crear líneas suaves usando curvas cuadráticas
      for (int j = 1; j < strokes[i].length - 1; j++) {
        final current = strokes[i][j];
        final next = strokes[i][j + 1];
        final controlPoint = Offset(
          (current.dx + next.dx) / 2,
          (current.dy + next.dy) / 2,
        );
        path.quadraticBezierTo(current.dx, current.dy, controlPoint.dx, controlPoint.dy);
      }
      
      // Agregar el último punto
      if (strokes[i].length > 1) {
        path.lineTo(strokes[i].last.dx, strokes[i].last.dy);
      }
      
      canvas.drawPath(path, paint);
    }

    // Dibujar trazo actual con líneas suaves
    if (currentStroke.length >= 2) {
      paint.color = currentColor;
      paint.strokeWidth = 5; // Trazo actual más grueso
      
      final path = Path();
      path.moveTo(currentStroke[0].dx, currentStroke[0].dy);
      
      for (int i = 1; i < currentStroke.length - 1; i++) {
        final current = currentStroke[i];
        final next = currentStroke[i + 1];
        final controlPoint = Offset(
          (current.dx + next.dx) / 2,
          (current.dy + next.dy) / 2,
        );
        path.quadraticBezierTo(current.dx, current.dy, controlPoint.dx, controlPoint.dy);
      }
      
      if (currentStroke.length > 1) {
        path.lineTo(currentStroke.last.dx, currentStroke.last.dy);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}