import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:math' as math;

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isInitialized = false;
  
  // Inicializar el servicio de audio
  static Future<void> initialize() async {
    if (!_isInitialized) {
      await _player.setPlayerMode(PlayerMode.lowLatency);
      _isInitialized = true;
    }
  }
  
  // Generar tono sinusoidal WAV
  static Uint8List generateWaveTone(double frequency, double duration) {
    const int sampleRate = 44100;
    const int bitsPerSample = 16;
    const int channels = 1;
    
    final int frameCount = (sampleRate * duration).round();
    final int byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final int blockAlign = channels * bitsPerSample ~/ 8;
    final int dataSize = frameCount * blockAlign;
    final int fileSize = 36 + dataSize;
    
    final ByteData wave = ByteData(44 + dataSize);
    
    // WAV Header
    wave.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    wave.setUint32(4, fileSize, Endian.little);
    wave.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    wave.setUint32(12, 0x666D7420, Endian.big); // "fmt "
    wave.setUint32(16, 16, Endian.little); // fmt chunk size
    wave.setUint16(20, 1, Endian.little); // audio format (PCM)
    wave.setUint16(22, channels, Endian.little);
    wave.setUint32(24, sampleRate, Endian.little);
    wave.setUint32(28, byteRate, Endian.little);
    wave.setUint16(32, blockAlign, Endian.little);
    wave.setUint16(34, bitsPerSample, Endian.little);
    wave.setUint32(36, 0x64617461, Endian.big); // "data"
    wave.setUint32(40, dataSize, Endian.little);
    
    // Generar muestras de audio
    for (int i = 0; i < frameCount; i++) {
      final double time = i / sampleRate;
      
      // Envolvente ADSR simple para sonido más natural
      double envelope = 1.0;
      double attackTime = 0.05;
      double decayTime = 0.1;
      double sustainLevel = 0.7;
      double releaseTime = 0.2;
      
      if (time < attackTime) {
        envelope = time / attackTime;
      } else if (time < attackTime + decayTime) {
        envelope = 1.0 - (1.0 - sustainLevel) * ((time - attackTime) / decayTime);
      } else if (time > duration - releaseTime) {
        envelope = sustainLevel * ((duration - time) / releaseTime);
      } else {
        envelope = sustainLevel;
      }
      
      // Mezclar múltiples armónicos para un sonido más rico
      double sample = 0.0;
      sample += math.sin(2 * math.pi * frequency * time) * 0.8; // Fundamental
      sample += math.sin(2 * math.pi * frequency * 2 * time) * 0.3; // Octava
      sample += math.sin(2 * math.pi * frequency * 3 * time) * 0.1; // Quinta
      
      sample *= envelope * 0.3; // Volumen general
      
      // Convertir a 16-bit signed integer
      int sampleValue = (sample * 32767).round().clamp(-32768, 32767);
      wave.setInt16(44 + i * 2, sampleValue, Endian.little);
    }
    
    return wave.buffer.asUint8List();
  }
  
  // Reproducir frecuencia específica
  static Future<void> playFrequency(double frequency, {double duration = 0.3}) async {
    try {
      await initialize();
      
      final waveData = generateWaveTone(frequency, duration);
      await _player.play(BytesSource(waveData));
      
    } catch (e) {
      print('Error playing frequency: $e');
    }
  }
  
  // Reproducir acorde (múltiples frecuencias)
  static Future<void> playChord(List<double> frequencies, {double duration = 0.5}) async {
    try {
      await initialize();
      
      // Crear un sonido que mezcle todas las frecuencias
      const int sampleRate = 44100;
      final int frameCount = (sampleRate * duration).round();
      final int dataSize = frameCount * 2;
      final int fileSize = 36 + dataSize;
      
      final ByteData wave = ByteData(44 + dataSize);
      
      // WAV Header
      wave.setUint32(0, 0x52494646, Endian.big);
      wave.setUint32(4, fileSize, Endian.little);
      wave.setUint32(8, 0x57415645, Endian.big);
      wave.setUint32(12, 0x666D7420, Endian.big);
      wave.setUint32(16, 16, Endian.little);
      wave.setUint16(20, 1, Endian.little);
      wave.setUint16(22, 1, Endian.little);
      wave.setUint32(24, sampleRate, Endian.little);
      wave.setUint32(28, sampleRate * 2, Endian.little);
      wave.setUint16(32, 2, Endian.little);
      wave.setUint16(34, 16, Endian.little);
      wave.setUint32(36, 0x64617461, Endian.big);
      wave.setUint32(40, dataSize, Endian.little);
      
      // Generar muestras mezclando frecuencias
      for (int i = 0; i < frameCount; i++) {
        final double time = i / sampleRate;
        
        double envelope = 1.0;
        double attackTime = 0.05;
        double releaseTime = 0.2;
        
        if (time < attackTime) {
          envelope = time / attackTime;
        } else if (time > duration - releaseTime) {
          envelope = (duration - time) / releaseTime;
        }
        
        double sample = 0.0;
        for (double freq in frequencies) {
          sample += math.sin(2 * math.pi * freq * time) / frequencies.length;
        }
        
        sample *= envelope * 0.4;
        
        int sampleValue = (sample * 32767).round().clamp(-32768, 32767);
        wave.setInt16(44 + i * 2, sampleValue, Endian.little);
      }
      
      await _player.play(BytesSource(wave.buffer.asUint8List()));
      
    } catch (e) {
      print('Error playing chord: $e');
    }
  }
  
  // Detener reproducción
  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }
  
  // Limpiar recursos
  static Future<void> dispose() async {
    try {
      await _player.dispose();
      _isInitialized = false;
    } catch (e) {
      print('Error disposing audio: $e');
    }
  }
}