import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:math' as math;

class SoundGenerator {
  static const int sampleRate = 44100;
  static const double duration = 0.3; // 300ms por nota
  
  // Generar tono sinusoidal
  static Uint8List generateTone(double frequency) {
    final int frameCount = (sampleRate * duration).round();
    final samples = Float32List(frameCount);
    
    for (int i = 0; i < frameCount; i++) {
      final double time = i / sampleRate;
      final double amplitude = math.sin(2 * math.pi * frequency * time) * 0.3;
      samples[i] = amplitude;
    }
    
    // Convertir a bytes
    final bytes = ByteData(frameCount * 4);
    for (int i = 0; i < frameCount; i++) {
      bytes.setFloat32(i * 4, samples[i], Endian.little);
    }
    
    return bytes.buffer.asUint8List();
  }
  
  // Reproducir sonido usando vibración y sistema
  static void playFrequency(double frequency) async {
    try {
      // Crear diferentes patrones de vibración basados en la frecuencia
      if (frequency > 800) {
        // Tonos agudos - vibración rápida
        HapticFeedback.selectionClick();
        await Future.delayed(Duration(milliseconds: 50));
        HapticFeedback.selectionClick();
        await Future.delayed(Duration(milliseconds: 30));
        HapticFeedback.selectionClick();
      } else if (frequency > 600) {
        // Tonos medios-agudos
        HapticFeedback.lightImpact();
        await Future.delayed(Duration(milliseconds: 80));
        HapticFeedback.lightImpact();
      } else if (frequency > 400) {
        // Tonos medios
        HapticFeedback.mediumImpact();
        await Future.delayed(Duration(milliseconds: 100));
        HapticFeedback.lightImpact();
      } else if (frequency > 300) {
        // Tonos graves
        HapticFeedback.heavyImpact();
        await Future.delayed(Duration(milliseconds: 120));
        HapticFeedback.mediumImpact();
      } else {
        // Tonos muy graves - patrón largo
        HapticFeedback.heavyImpact();
        await Future.delayed(Duration(milliseconds: 150));
        HapticFeedback.heavyImpact();
      }
      
      // Añadir sonido del sistema para feedback auditivo
      SystemSound.play(SystemSoundType.click);
      
    } catch (e) {
      print('Error playing sound: $e');
    }
  }
  
  // Reproducir acorde (múltiples frecuencias)
  static void playChord(List<double> frequencies) async {
    for (double freq in frequencies) {
      playFrequency(freq);
      await Future.delayed(Duration(milliseconds: 50));
    }
  }
  
  // Reproducir secuencia de notas
  static void playSequence(List<double> frequencies, int tempo) async {
    int delay = (60000 / (tempo * 4)).round();
    
    for (double freq in frequencies) {
      playFrequency(freq);
      await Future.delayed(Duration(milliseconds: delay));
    }
  }
}