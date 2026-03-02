//
//  AuthService.swift
//  Fasting
//
//  Apple Sign In + Keychain credential storage
//  Ready for future server integration
//

import AuthenticationServices
import SwiftUI
import Combine

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isSignedIn: Bool = false
    @Published var userIdentifier: String?
    @Published var fullName: String?
    @Published var email: String?
    
    // For future server auth
    @Published var identityToken: String?
    @Published var authorizationCode: String?
    
    private let keychainService = "com.nana.fasting.auth"
    
    private init() {
        restoreSession()
    }
    
    // MARK: - Apple Sign In
    
    func handleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            
            userIdentifier = credential.user
            
            // Name & email only come on FIRST sign-in
            if let nameComponents = credential.fullName {
                let name = [nameComponents.givenName, nameComponents.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                if !name.isEmpty {
                    fullName = name
                    saveToKeychain(key: "fullName", value: name)
                }
            }
            
            if let emailValue = credential.email {
                email = emailValue
                saveToKeychain(key: "email", value: emailValue)
            }
            
            if let tokenData = credential.identityToken, let token = String(data: tokenData, encoding: .utf8) {
                identityToken = token
            }
            
            if let codeData = credential.authorizationCode, let code = String(data: codeData, encoding: .utf8) {
                authorizationCode = code
            }
            
            // Persist
            saveToKeychain(key: "userIdentifier", value: credential.user)
            isSignedIn = true
            
            // TODO: Send token to server
            // sendTokenToServer()
            
        case .failure(let error):
            print("[Auth] Sign in failed: \(error.localizedDescription)")
        }
    }
    
    func skipSignIn() {
        saveToKeychain(key: "guestMode", value: "true")
        isSignedIn = true
    }
    
    func signOut() {
        deleteFromKeychain(key: "userIdentifier")
        deleteFromKeychain(key: "fullName")
        deleteFromKeychain(key: "email")
        deleteFromKeychain(key: "guestMode")
        userIdentifier = nil
        fullName = nil
        email = nil
        identityToken = nil
        authorizationCode = nil
        isSignedIn = false
    }
    
    var isGuestMode: Bool {
        readFromKeychain(key: "guestMode") == "true" && userIdentifier == nil
    }
    
    // MARK: - Session Restore
    
    private func restoreSession() {
        if let uid = readFromKeychain(key: "userIdentifier") {
            userIdentifier = uid
            fullName = readFromKeychain(key: "fullName")
            email = readFromKeychain(key: "email")
            isSignedIn = true
            
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: uid) { [weak self] state, _ in
                Task { @MainActor in
                    if state == .revoked || state == .notFound {
                        self?.signOut()
                    }
                }
            }
        } else if readFromKeychain(key: "guestMode") == "true" {
            isSignedIn = true
        }
    }
    
    // MARK: - Future Server Integration
    
    func sendTokenToServer() async {
        guard let token = identityToken, let code = authorizationCode else { return }
        // TODO: POST to /auth/apple with identityToken + authorizationCode
        _ = token; _ = code
    }
    
    // MARK: - Keychain Helpers
    
    private func saveToKeychain(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }
    
    private func readFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
