//
//  AuthInterceptorExample.swift
//  DocAssist-ios
//
//  Example usage of authentication interceptor
//

import Foundation

/*
 USAGE EXAMPLES:
 
 // 1. Initialize tokens when user logs in or tokens are received
 AuthTokenManager.shared.setTokens(
   authToken: "your_auth_token",
   refreshToken: "your_refresh_token"
 )
 
 // 2. Use HTTPNetworkRequest for API calls (automatically adds auth headers)
 let httpRequest = HTTPNetworkRequest()
 
 // GET request example
 httpRequest.get(url: URL(string: "https://api.example.com/data")!) { result in
   switch result {
   case .success(let response):
     if let data = response.dictionary() {
       print("Response: \(data)")
     }
   case .failure(let error):
     print("Error: \(error)")
   }
 }
 
 // POST request example
 let body: [String: Any] = ["key": "value"]
 let bodyData = try? JSONSerialization.data(withJSONObject: body)
 
 httpRequest.post(url: URL(string: "https://api.example.com/create")!, body: bodyData) { result in
   switch result {
   case .success(let response):
     print("Status: \(response.statusCode)")
   case .failure(let error):
     print("Error: \(error)")
   }
 }
 
 // 3. Check if session is active
 httpRequest.checkIfSessionIsActive { result in
   switch result {
   case .success(let isActive):
     print("Session active: \(isActive)")
   case .failure(let error):
     print("Error: \(error)")
   }
 }
 
 // 4. Refresh session
 httpRequest.refreshSession { result in
   switch result {
   case .success(let newToken):
     print("New token: \(newToken)")
   case .failure(let error):
     print("Error: \(error)")
   }
 }
 
 // 5. Create session
 let sessionParams: [String: Any] = [
   "userId": "123",
   "deviceId": "device_123"
 ]
 
 httpRequest.createSession(parameters: sessionParams) { result in
   switch result {
   case .success(let response):
     if let data = response.dictionary() {
       print("Session created: \(data)")
     }
   case .failure(let error):
     print("Error: \(error)")
   }
 }
 
 // 6. The NetworkCall class automatically uses the interceptor
 // No changes needed - it will automatically add auth headers to streaming requests
 
 // 7. Custom interceptor usage
 let customInterceptor = AuthInterceptor(
   tokenManager: AuthTokenManager.shared,
   shouldRefreshOn401: true
 )
 
 let customHttpRequest = HTTPNetworkRequest(interceptor: customInterceptor)
 
 */
