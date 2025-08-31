import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/audio_service.dart';

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

  final Map<Color, double> colorSounds = {
    Color(0xFFE91E63): 523.25,  // C5
    Color(0xFF9C27B0): 587.33,  // D5
    Color(0xFF673AB7): 659.25,  // E5
    Color(0xFF3F51B5): 698.46,  // F5
    Color(0xFF2196F3): 783.99,  // G5
    Color(0xFF03A9F4): 880.00,  // A5
    Color(0xFF00BCD4): 987.77,  // B5
    Color(0xFF009688): 1046.5,  // C6
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void playSound(Color color) {
    double frequency = colorSounds[color] ?? 523.25;
    AudioService.playFrequency(frequency, duration: 0.2);
  }

  void startDrawing(Offset position) {
    setState(() {
      isDrawing = true;
      currentStroke = [position];
      currentTimestamps = [DateTime.now().millisecondsSinceEpoch];
    });
    playSound(selectedColor);
    HapticFeedback.selectionClick();
  }

  void draw(Offset position) {
    if (!isDrawing) return;
    
    setState(() {
      currentStroke.add(position);
      currentTimestamps.add(DateTime.now().millisecondsSinceEpoch);
    });
    
    if (currentStroke.length % 20 == 0) {
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
    });

    List<Map<String, dynamic>> allPoints = [];
    
    for (int i = 0; i < strokes.length; i++) {
      for (int j = 0; j < strokes[i].length; j += 25) {
        allPoints.add({
          'timestamp': strokeTimestamps[i][j],
          'color': strokeColors[i],
        });
      }
    }
    
    allPoints.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    
    if (allPoints.isEmpty) {
      setState(() { isPlaying = false; });
      return;
    }
    
    int startTime = allPoints[0]['timestamp'];
    
    for (int i = 0; i < allPoints.length; i++) {
      int delay = ((allPoints[i]['timestamp'] - startTime) * 0.2).round();
      
      Timer(Duration(milliseconds: delay), () {
        if (mounted && isPlaying) {
          playSound(allPoints[i]['color']);
          
          if (i == allPoints.length - 1) {
            Timer(Duration(milliseconds: 400), () {
              if (mounted) {
                setState(() { isPlaying = false; });
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
    });
    AudioService.stop();
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
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 800;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "PAINT & SOUND",
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
            icon: Icon(Icons.delete_outline, color: Colors.red[400]),
            onPressed: clearCanvas,
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas principal - usa todo el espacio disponible
          Expanded(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: GestureDetector(
                  onPanStart: (details) {
                    startDrawing(details.localPosition);
                  },
                  onPanUpdate: (details) {
                    draw(details.localPosition);
                  },
                  onPanEnd: (details) {
                    stopDrawing();
                  },
                  child: CustomPaint(
                    painter: ResponsiveDrawingPainter(
                      strokes: strokes,
                      strokeColors: strokeColors,
                      currentStroke: currentStroke,
                      currentColor: selectedColor,
                      strokeWidth: isLargeScreen ? 6 : 4,
                    ),
                    size: Size.infinite,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: strokes.isEmpty && currentStroke.isEmpty
                        ? Center(
                            child: Icon(
                              Icons.brush_outlined,
                              size: isLargeScreen ? 80 : 60,
                              color: Colors.grey[300],
                            ),
                          )
                        : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Barra inferior con controles
          Container(
            height: isLargeScreen ? 80 : 70,
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Play button
                IconButton(
                  onPressed: strokes.isEmpty ? null : (isPlaying ? stopPlayback : playComposition),
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: strokes.isEmpty ? Colors.grey[400] : Colors.blue,
                    size: isLargeScreen ? 50 : 40,
                  ),
                ),
                
                SizedBox(width: 12),
                
                // Paleta de colores compacta
                Expanded(
                  child: Container(
                    height: isLargeScreen ? 50 : 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: colorSounds.keys.length,
                      itemBuilder: (context, index) {
                        Color color = colorSounds.keys.elementAt(index);
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
                            width: isLargeScreen ? 40 : 35,
                            height: isLargeScreen ? 40 : 35,
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                SizedBox(width: 12),
                
                // Estado de reproducción
                if (isPlaying)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF34A853),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'PLAYING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

// Custom Painter responsivo
class ResponsiveDrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Color> strokeColors;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double strokeWidth;

  ResponsiveDrawingPainter({
    required this.strokes,
    required this.strokeColors,
    required this.currentStroke,
    required this.currentColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Dibujar trazos guardados
    for (int i = 0; i < strokes.length; i++) {
      if (strokes[i].length < 2) continue;
      
      paint.color = strokeColors[i];
      
      final path = Path();
      path.moveTo(strokes[i][0].dx, strokes[i][0].dy);
      
      for (int j = 1; j < strokes[i].length - 1; j++) {
        final current = strokes[i][j];
        final next = strokes[i][j + 1];
        final controlPoint = Offset(
          (current.dx + next.dx) / 2,
          (current.dy + next.dy) / 2,
        );
        path.quadraticBezierTo(current.dx, current.dy, controlPoint.dx, controlPoint.dy);
      }
      
      if (strokes[i].length > 1) {
        path.lineTo(strokes[i].last.dx, strokes[i].last.dy);
      }
      
      canvas.drawPath(path, paint);
    }

    // Trazo actual
    if (currentStroke.length >= 2) {
      paint.color = currentColor;
      paint.strokeWidth = strokeWidth + 2;
      
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