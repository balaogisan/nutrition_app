//
//  GeminiAPI.swift
//  Nutrition Calculator
//
//  Created by SHAOYUN HSU on 2025/7/5.
//

import Foundation

class GeminiAPI {
    static let shared = GeminiAPI()
    
    private var apiKey: String {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String else {
            fatalError("GEMINI_API_KEY not found in Info.plist")
        }
        return apiKey
    }

    func analyzeFood(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        print("🔍 Gemini API: Starting food analysis")
        print("📸 Image data size: \(imageData.count) bytes")
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64Image = imageData.base64EncodedString()
        let prompt = "這是一張食物照片，請直接用 JSON 回答如下格式：{\"name\":..., \"calories\":..., \"protein\":..., \"fat\":..., \"carbs\":...}"
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
}

