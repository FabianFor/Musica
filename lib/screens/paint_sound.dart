import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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
  
  Color selectedColor = Color(0xFFFF6B6B);
  bool isPlaying = false;
  bool isDrawing = false;

  // Colores con diferentes tipos de sonido
  final Map<Color, Map<String, dynamic>> colorSounds = {
    Color(0xFFFF6B6B): {'name': 'Do5', 'soundType': 'high1'},
    Color(0xFF4ECDC4): {'name': 'Sol4', 'soundType': 'high2'},
    Color(0xFF45B7D1): {'name': 'Mi4', 'soundType': 'mid1'},
    Color(0xFF96CEB4): {'name': 'Re4', 'soundType': 'mid2'},
    Color(0xFFFFEAA7): {'name': 'Do4', 'soundType': 'mid3'},
    Color(0xFFDDA0DD): {'name': 'La3', 'soundType': 'low1'},
    Color(0xFFFFB347): {'name': 'Sol3', 'soundType': 'low2'},
    Color(0xFFF8BBD9): {'name': 'Fa3', 'soundType': 'bass'},
  };

  @override
  void dispose() {
    super.dispose();
  }

  // Reproducir sonido según el color usando flutter_beep
  void playSound(Color color) async {
    try {
      String soundType = colorSounds[color]?['soundType'] ?? 'mid1';
      
      switch (soundType) {
        case 'high1':
          FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_HIGH_PBX_L);
          break;
        case 'high2':
          FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_HIGH_PBX_S_X4);
          break;
        case 'mid1':
          FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_MED_PBX_L);
          break;
        case 'mid2':
          FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_MED_PBX_S_X4);
          break;
        case 'mid3':
          FlutterBeep.beep();
          break;
        case 'low1':
          FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_LOW_PBX_L);
          break;
        case 'low2':
          FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_LOW_PBX_S_X4);
          break;
        case 'bass':
          HapticFeedback.heavyImpact();
          FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ABBR_ALERT);
          break;
        default:
          FlutterBeep.beep();
      }
    } catch (e) {
      // Fallback a vibración
      HapticFeedback.lightImpact();
      print('Sound error: $e');
    }
  }

  // Empezar a dibujar
  void startDrawing(Offset position) {
    setState(() {
      isDrawing = true;
      currentStroke = [position];
      currentTimestamps = [DateTime.now().millisecondsSinceEpoch];
    });
    playSound(selectedColor);
  }

  // Continuar dibujando
  void draw(Offset position) {
    if (!isDrawing) return;
    
    setState(() {
      currentStroke.add(position);
      currentTimestamps.add(DateTime.now().millisecondsSinceEpoch);
    });
    
    // Reproducir sonido ocasionalmente mientras dibuja
    if (currentStroke.length % 5 == 0) {
      playSound(selectedColor);
    }
  }

  // Terminar de dibujar
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

  // Reproducir composición
  void playComposition() async {
    if (strokes.isEmpty) return;
    
    setState(() {
      isPlaying = true;
    });

    // Combinar todos los puntos con timestamps
    List<Map<String, dynamic>> allPoints = [];
    
    for (int i = 0; i < strokes.length; i++) {
      for (int j = 0; j < strokes[i].length; j++) {
        allPoints.add({
          'timestamp': strokeTimestamps[i][j],
          'color': strokeColors[i],
        });
      }
    }
    
    allPoints.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    
    if (allPoints.isEmpty) {
      setState(() {
        isPlaying = false;
      });
      return;
    }
    
    int startTime = allPoints[0]['timestamp'];
    
    for (int i = 0; i < allPoints.length; i++) {
      int delay = ((allPoints[i]['timestamp'] - startTime) * 0.3).round();
      
      Timer(Duration(milliseconds: delay), () {
        playSound(allPoints[i]['color']);
        
        if (i == allPoints.length - 1) {
          Timer(Duration(milliseconds: 300), () {
            setState(() {
              isPlaying = false;
            });
          });
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
                'PAINT & SOUND',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Controles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: strokes.isEmpty ? null : (isPlaying ? () {
                      setState(() {
                        isPlaying = false;
                      });
                    } : playComposition),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: strokes.isEmpty ? Colors.grey[400] : Colors.blue[500],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: (strokes.isEmpty ? Colors.grey : Colors.blue).withOpacity(0.3),
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
                  
                  GestureDetector(
                    onTap: clearCanvas,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[500],
                        borderRadius: BorderRadius.circular(8),
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
              
              // Paleta de colores
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: colorSounds.keys.map((color) => GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                          playSound(color);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: selectedColor == color ? Colors.grey[800]! : Colors.grey[400]!,
                              width: selectedColor == color ? 4 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                    
                    SizedBox(height: 8),
                    
                    Text(
                      colorSounds[selectedColor]?['name'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Canvas para dibujar
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 3),
                  ),
                  child: GestureDetector(
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
                      painter: DrawingPainter(
                        strokes: strokes,
                        strokeColors: strokeColors,
                        currentStroke: currentStroke,
                        currentColor: selectedColor,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
              
              // Estado de reproducción
              if (isPlaying)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue[500],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'REPRODUCIENDO',
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

// Custom Painter para el canvas
class DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Color> strokeColors;
  final List<Offset> currentStroke;
  final Color currentColor;

  DrawingPainter({
    required this.strokes,
    required this.strokeColors,
    required this.currentStroke,
    required this.currentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 8;

    // Dibujar trazos guardados
    for (int i = 0; i < strokes.length; i++) {
      if (strokes[i].length < 2) continue;
      
      paint.color = strokeColors[i];
      
      final path = Path();
      path.moveTo(strokes[i][0].dx, strokes[i][0].dy);
      
      for (int j = 1; j < strokes[i].length; j++) {
        path.lineTo(strokes[i][j].dx, strokes[i][j].dy);
      }
      
      canvas.drawPath(path, paint);
    }

    // Dibujar trazo actual
    if (currentStroke.length >= 2) {
      paint.color = currentColor;
      
      final path = Path();
      path.moveTo(currentStroke[0].dx, currentStroke[0].dy);
      
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}