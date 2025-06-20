import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Initialize Supabase (panggil di main.dart)
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? "your_supabase_url_here",
      anonKey: dotenv.env['ANON_KEY'] ?? "your_anon_key_here",
    );
  }
  
  // Upload KTP image to Supabase Storage - FIXED VERSION
  static Future<String?> uploadKtpImage(File imageFile, String fileName) async {
    try {
      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        print('Error: File does not exist at path: ${imageFile.path}');
        return null;
      }

      // Read file as bytes
      Uint8List fileBytes;
      try {
        fileBytes = await imageFile.readAsBytes();
        print('File size: ${fileBytes.length} bytes');
      } catch (e) {
        print('Error reading file bytes: $e');
        return null;
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path).toLowerCase();
      
      // Ensure we have a valid extension
      final validExtension = extension.isNotEmpty ? extension : '.jpg';
      final uniqueFileName = 'ktp_${timestamp}_${fileName.replaceAll(' ', '_')}$validExtension';
      
      print('Uploading file: $uniqueFileName');
      print('File path: ${imageFile.path}');
      
      // Upload file to Supabase Storage using bytes
      final response = await _client.storage
          .from('ktp-images')
          .uploadBinary(uniqueFileName, fileBytes, 
            fileOptions: FileOptions(
              contentType: _getContentType(validExtension),
              upsert: true, // Allow overwrite if file exists
            ),
          );
      
      print('Upload response: $response');
      
      // Get public URL
      final publicUrl = _client.storage
          .from('ktp-images')
          .getPublicUrl(uniqueFileName);
      
      print('Public URL: $publicUrl');
      return publicUrl;
      
    } catch (e) {
      print('Error uploading image: $e');
      print('Error type: ${e.runtimeType}');
      if (e is StorageException) {
        print('Storage error message: ${e.message}');
        print('Storage error status code: ${e.statusCode}');
      }
      return null;
    }
  }
  
  // Helper method to get content type based on file extension
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }
  
  // Delete KTP image from Supabase Storage
  static Future<bool> deleteKtpImage(String fileName) async {
    try {
      print('Deleting file: $fileName');
      
      final response = await _client.storage
          .from('ktp-images')
          .remove([fileName]);
          
      print('Delete response: $response');
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      if (e is StorageException) {
        print('Storage error message: ${e.message}');
        print('Storage error status code: ${e.statusCode}');
      }
      return false;
    }
  }
  
  // Get file name from URL
  static String getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return path.basename(uri.path);
    } catch (e) {
      print('Error parsing URL: $e');
      return '';
    }
  }
  
  // Test connection to Supabase
  static Future<bool> testConnection() async {
    try {
      // Try to list files in the bucket to test connection
      final response = await _client.storage
          .from('ktp-images')
          .list();
      print('Connection test successful: ${response.length} files found');
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
  
  // Create bucket if it doesn't exist (call this once in your app initialization)
  static Future<bool> createBucketIfNotExists() async {
    try {
      // Try to create bucket (will fail if already exists, which is fine)
      await _client.storage.createBucket('ktp-images', 
        const BucketOptions(
          public: true,
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],// 5MB limit
        ),
      );
      print('Bucket created successfully');
      return true;
    } catch (e) {
      if (e.toString().contains('already exists')) {
        print('Bucket already exists');
        return true;
      }
      print('Error creating bucket: $e');
      return false;
    }
  }
}