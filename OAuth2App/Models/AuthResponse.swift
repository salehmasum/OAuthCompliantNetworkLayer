//
//  AuthResponse.swift
//  OAuth2App
//
//  Created by Saleh Masum on 26/8/2022.
//

import Foundation

struct AuthResponse: Codable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String?
    let token_type: String
}
