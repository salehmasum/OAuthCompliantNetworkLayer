//
//  AuthManager.swift
//  OAuth2App
//
//  Created by Saleh Masum on 26/8/2022.
//

import Foundation

final class AuthManager {
    static let shared = AuthManager()
    private init() {}
    
    struct Constants {
        static let authorizationApiUrl = "https://accounts.spotify.com/authorize"
        static let clientID = "6e02d3002fa04708a41bc36e7e2ad80e"
        static let clientSecret = "b6bbc7d0bd5f460b9a608f970cff2e0e"
        static let tokenAPIURL  = "https://accounts.spotify.com/api/token"
        static let redirectURI = "https://www.google.com/"
        static let scopes = "user-read-private%20playlist-modify-public%20playlist-read-public%20user-follow-read%20user-library-modify%20user-library-read%20user-read-email"
        static let access_token = "access_token"
        static let refresh_token = "refresh_token"
        static let expirationDate = "expirationDate"
    }
    
    public var base64EncodedString: String {
        let basicToken = Constants.clientID+":"+Constants.clientSecret
        let basicTokenData = basicToken.data(using: .utf8)!
        return basicTokenData.base64EncodedString()
    }
    
    public var signInUrl: URL? {
        let authorizationUrlString = "\(Constants.authorizationApiUrl)?response_type=code&client_id=\(Constants.clientID)&scopes=\(Constants.scopes)&redirect_uri=\(Constants.redirectURI)&show_dialog=TRUE"
        return URL(string: authorizationUrlString)
    }
    
    private var accessToken: String? {
        return UserDefaults.standard.string(forKey: Constants.access_token)
    }
    
    private var refreshToken: String? {
        return UserDefaults.standard.string(forKey: Constants.refresh_token)
    }
    
    private var expirationDate: Date? {
        return UserDefaults.standard.object(forKey: Constants.expirationDate) as? Date
    }
    
    private var isAccessTokenExpired: Bool {
        guard let expirationDate = expirationDate else {
            return false
        }
        let fiveMinutes: TimeInterval = 300
        let currentDate = Date()
        return currentDate.addingTimeInterval(fiveMinutes) >= expirationDate
    }
    
    private var isRefreshCallOnGoing = false
    private var onRefreshBlock = [(String)->Void]()
    
    public func withValidToken(completion: @escaping (String) -> Void) {
        
        guard !isRefreshCallOnGoing else {
            //Add request to Queue since token refresh request is ongoing
            onRefreshBlock.append(completion)
            return
        }
        
        if isAccessTokenExpired {
            refreshIfNeeded { [weak self] success in
                if let accessToken = self?.accessToken, success {
                    completion(accessToken)
                }
            }
        }
        else if let accessToken = self.accessToken {
            completion(accessToken)
        }
    }
    
    public func refreshIfNeeded(completion: ((Bool) -> Void)?) {
        
        guard !isRefreshCallOnGoing else {
            return
        }
        
        guard isAccessTokenExpired else {
            completion?(true)
            return
        }
        
        isRefreshCallOnGoing = true
        
        guard let refreshToken = self.refreshToken else { return }
        guard let tokenUrl = URL(string: Constants.tokenAPIURL) else { return }
        var urlComponents = URLComponents()
        urlComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: Constants.refresh_token),
            URLQueryItem(name: Constants.refresh_token, value: refreshToken)
        ]
        
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(base64EncodedString)", forHTTPHeaderField: "Authorization")
        request.httpBody = urlComponents.query?.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            self?.isRefreshCallOnGoing = false
            guard let data = data, error == nil else {
                completion?(false)
                return
            }
            do {
                let tokenResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                self?.onRefreshBlock.forEach{ $0(tokenResponse.access_token) }
                self?.onRefreshBlock.removeAll()
                self?.cacheTokens(tokenResponse: tokenResponse)
                completion?(true)
            }
            catch {
                print(error.localizedDescription)
                completion?(false)
            }
        }
        task.resume()
        
    }
    
    public func exchangeCodeForToken(code: String, completion: @escaping ((Bool) -> Void)) {
        
        guard let tokenUrl = URL(string: Constants.tokenAPIURL) else { return }
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(base64EncodedString)", forHTTPHeaderField: "Authorization")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI)
        ]
        
        request.httpBody = components.query?.data(using: .utf8)
        
        //Initiage the network call
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            do {
                let tokenResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                self?.cacheTokens(tokenResponse: tokenResponse)
                completion(true)
            }
            catch {
                print(error.localizedDescription)
                completion(false)
            }
        }
        task.resume()
        
    }
    
    private func cacheTokens(tokenResponse: AuthResponse) {
        UserDefaults.standard.setValue(tokenResponse.access_token, forKey: Constants.access_token)
        if let refreshToken = tokenResponse.refresh_token {
            UserDefaults.standard.setValue(refreshToken, forKey: Constants.refresh_token)
        }
        
        let tokenExpireTime = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
        UserDefaults.standard.setValue(tokenExpireTime, forKey: Constants.expirationDate)
    }
    
    
}
