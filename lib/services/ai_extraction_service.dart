// lib/services/ai_extraction_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_entry.dart';

class AIExtractionService {
  static const String _apiKeyPref = 'claude_api_key';
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key);
  }

  Future<ExtractedData> extractSpeedometerData(String imagePath) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return ExtractedData(
        success: false,
        errorMessage: 'API key not configured. Please set your Claude API key in Settings.',
      );
    }

    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final extension = imagePath.split('.').last.toLowerCase();
      final mediaType = extension == 'png' ? 'image/png' : 'image/jpeg';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-opus-4-5',
          'max_tokens': 500,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': '''This is a speedometer/odometer image from a motorcycle or bike. 
                  Please extract the odometer reading (total distance traveled in km or miles).
                  
                  Respond ONLY with a JSON object in this exact format:
                  {
                    "odometer_reading": <number or null>,
                    "unit": "km" or "miles",
                    "confidence": "high" or "medium" or "low",
                    "raw_text": "<any text you can read from the image>"
                  }
                  
                  If you cannot read the odometer clearly, set odometer_reading to null.
                  Do not include any other text, just the JSON.'''
                }
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;

        // Clean and parse JSON
        final cleanedContent = content.trim().replaceAll('```json', '').replaceAll('```', '').trim();
        final extracted = jsonDecode(cleanedContent);

        return ExtractedData(
          odometerReading: extracted['odometer_reading'] != null
              ? (extracted['odometer_reading'] as num).toDouble()
              : null,
          rawText: extracted['raw_text'],
          success: extracted['odometer_reading'] != null,
          errorMessage: extracted['odometer_reading'] == null
              ? 'Could not read odometer clearly. Please enter manually.'
              : null,
        );
      } else {
        final errorBody = jsonDecode(response.body);
        return ExtractedData(
          success: false,
          errorMessage: 'API Error: ${errorBody['error']?['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      return ExtractedData(
        success: false,
        errorMessage: 'Failed to process image: ${e.toString()}',
      );
    }
  }

  Future<ExtractedData> extractMachineData(String imagePath) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return ExtractedData(
        success: false,
        errorMessage: 'API key not configured. Please set your Claude API key in Settings.',
      );
    }

    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final extension = imagePath.split('.').last.toLowerCase();
      final mediaType = extension == 'png' ? 'image/png' : 'image/jpeg';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-opus-4-5',
          'max_tokens': 500,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': '''This is an image of a petrol/fuel filling machine display in India.
                  Please extract:
                  1. Amount in Rupees (total cost)
                  2. Liters filled (quantity of fuel)
                  3. Rate/Price per liter
                  
                  Respond ONLY with a JSON object in this exact format:
                  {
                    "amount_rupees": <number or null>,
                    "liters": <number or null>,
                    "rate_per_liter": <number or null>,
                    "confidence": "high" or "medium" or "low",
                    "raw_text": "<any text you can read from the display>"
                  }
                  
                  Common labels on Indian petrol machines:
                  - Amount/Rs/INR = total cost in rupees
                  - Volume/Qty/Ltr = liters filled
                  - Rate/Price = price per liter
                  
                  If a value cannot be read, set it to null.
                  Do not include any other text, just the JSON.'''
                }
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;

        final cleanedContent = content.trim().replaceAll('```json', '').replaceAll('```', '').trim();
        final extracted = jsonDecode(cleanedContent);

        bool hasData = extracted['amount_rupees'] != null ||
            extracted['liters'] != null ||
            extracted['rate_per_liter'] != null;

        return ExtractedData(
          amountPaid: extracted['amount_rupees'] != null
              ? (extracted['amount_rupees'] as num).toDouble()
              : null,
          litersFilled: extracted['liters'] != null
              ? (extracted['liters'] as num).toDouble()
              : null,
          pricePerLiter: extracted['rate_per_liter'] != null
              ? (extracted['rate_per_liter'] as num).toDouble()
              : null,
          rawText: extracted['raw_text'],
          success: hasData,
          errorMessage: !hasData ? 'Could not read machine display. Please enter manually.' : null,
        );
      } else {
        final errorBody = jsonDecode(response.body);
        return ExtractedData(
          success: false,
          errorMessage: 'API Error: ${errorBody['error']?['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      return ExtractedData(
        success: false,
        errorMessage: 'Failed to process image: ${e.toString()}',
      );
    }
  }
}
