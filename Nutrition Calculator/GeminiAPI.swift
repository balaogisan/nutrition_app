//
//  GeminiAPI.swift
//  Nutrition Calculator
//
//  Created by SHAOYUN HSU on 2025/7/5.
//

import Foundation
import UIKit

class GeminiAPI {
    static let shared = GeminiAPI()
    
    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["GEMINI_API_KEY"] as? String else {
            fatalError("GEMINI_API_KEY not found in Config.plist")
        }
        return apiKey
    }
    
    private func compressImage(_ imageData: Data) -> Data? {
        guard let originalImage = UIImage(data: imageData) else {
            print("❌ Failed to create UIImage from data")
            return nil
        }
        
        let originalSize = originalImage.size
        let newSize = CGSize(width: originalSize.width / 2, height: originalSize.height / 2)
        
        print("📐 Original size: \(originalSize), New size: \(newSize)")
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        originalImage.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let compressedImage = resizedImage else {
            print("❌ Failed to resize image")
            return nil
        }
        
        guard let compressedData = compressedImage.jpegData(compressionQuality: 0.5) else {
            print("❌ Failed to compress image to JPEG")
            return nil
        }
        
        let compressionRatio = Double(compressedData.count) / Double(imageData.count)
        print("📊 Compression ratio: \(String(format: "%.1f", compressionRatio * 100))% (\(imageData.count) → \(compressedData.count) bytes)")
        
        return compressedData
    }

    func analyzeFood(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        print("🔍 Gemini API: Starting food analysis")
        print("📸 Original image data size: \(imageData.count) bytes")
        
        // Compress the image before sending to API
        guard let compressedImageData = compressImage(imageData) else {
            print("❌ Failed to compress image, using original")
            analyzeWithImageData(imageData, completion: completion)
            return
        }
        
        print("✅ Using compressed image: \(compressedImageData.count) bytes")
        analyzeWithImageData(compressedImageData, completion: completion)
    }
    
    private func analyzeWithImageData(_ imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("hsu.Nutrition-Calculator", forHTTPHeaderField: "X-Ios-Bundle-Identifier")

        let base64Image = imageData.base64EncodedString()
        let prompt = "這是一張食物照片，請直接用 JSON 回答如下格式：{\"name\":..., \"calories\":..., \"protein\":..., \"fat\":..., \"carbs\":..., \"weighs\":..., \"results\":[{\"source\": \"...\", \"calories\": ..., \"protein\": ..., \"fat\": ..., \"carbs\": ...}]}"
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("📤 Request body size: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            print("❌ Failed to serialize request body: \(error)")
            completion(.failure(error))
            return
        }

        logRequest(requestBody: requestBody)

        print("🚀 Sending request to Gemini API...")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ No data received")
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            print("📥 Response data size: \(data.count) bytes")
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                print("✅ Full API Response: \(String(describing: json))")
                
                // Extract the text content from the response
                if let candidates = json?["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    print("📝 Extracted text: \(text)")
                    completion(.success(text))
                } else {
                    print("❌ Unable to extract text from response structure")
                    completion(.failure(NSError(domain: "Invalid response format", code: 0)))
                }
            } catch {
                print("❌ JSON parsing error: \(error)")
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                completion(.failure(error))
            }
        }.resume()
    }
    
    func searchFoodNutrition(foodName: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("🔍 Gemini API: Starting food nutrition search for '\(foodName)'")
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("hsu.Nutrition-Calculator", forHTTPHeaderField: "X-Ios-Bundle-Identifier")

        let prompt = "請搜尋一項食物：\(foodName)，請直接用 JSON 回答如下格式：{\"name\":..., \"calories\":..., \"protein\":..., \"fat\":..., \"carbs\":..., \"weighs\":..., \"results\":[{\"source\": \"...\", \"calories\": ..., \"protein\": ..., \"fat\": ..., \"carbs\": ...}]}"
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Failed to serialize request body: \(error)")
            completion(.failure(error))
            return
        }

        print("🚀 Sending request to Gemini API for nutrition facts...")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ No data received")
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let candidates = json?["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    print("📝 Extracted text: \(text)")
                    completion(.success(text))
                } else {
                    print("❌ Unable to extract text from response structure")
                    print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                    completion(.failure(NSError(domain: "Invalid response format", code: 0)))
                }
            } catch {
                print("❌ JSON parsing error: \(error)")
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                completion(.failure(error))
            }
        }.resume()
    }

    private func logRequest(requestBody: [String: Any]) {
        guard let url = URL(string: "https://gcslog-2824223740.asia-east1.run.app") else {
            print("❌ Invalid logging URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Failed to serialize logging request body: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Logging request error: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("❌ Logging request failed with status code: \(httpResponse.statusCode)")
                if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                    print("📝 Logging response body: \(responseBody)")
                }
            }
        }.resume()
    }
}

