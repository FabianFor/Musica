import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/grid_composer.dart';
import 'screens/paint_sound.dart';
import 'screens/melody_builder.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar audio
  await AudioService.initialize();
  
  // Forzar orientación horizontal para toda la app
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Maker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            // Panel izquierdo con logo
            Container(
              width: 300,
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4285F4),
                    Color(0xFF34A853),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo grande
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  Text(
                    'MUSIC',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  
                  Text(
                    'MAKER',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  Text(
                    'Create music with colors,\nbeats and melodies',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Panel derecho con opciones
            Expanded(
              child: Container(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Opciones en columna para horizontal
                    Column(
                      children: [
                        _buildModeCard(
                          context,
                          'SONG MAKER',
                          'Create beats and rhythms with a grid',
                          LinearGradient(
                            colors: [Color(0xFF4285F4), Color(0xFF1976D2)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          Icons.grid_4x4_rounded,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GridComposer()),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        _buildModeCard(
                          context,
                          'PAINT & SOUND',
                          'Draw your music with colors and sounds',
                          LinearGradient(
                            colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          Icons.brush_rounded,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PaintSound()),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        _buildModeCard(
                          context,
                          'MELODY MAKER',
                          'Compose melodies with virtual piano',
                          LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          Icons.piano_rounded,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MelodyBuilder()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    String title,
    String subtitle,
    Gradient gradient,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      height: 80,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 6,
        shadowColor: Colors.black12,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  SizedBox(width: 20),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        
                        SizedBox(height: 4),
                        
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    AudioService.dispose();
    super.dispose();
  }
}