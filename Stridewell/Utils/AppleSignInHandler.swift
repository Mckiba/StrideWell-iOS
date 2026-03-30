//
//  AppleSignInHandler.swift
//  Stridewell
//
//  Wraps Apple's ASAuthorizationController in a single async call.
//  Returns the raw identity token and un-hashed nonce; callers send
//  these to POST /auth/apple and update AuthStore on success.
//

import AuthenticationServices
import CryptoKit
import Foundation

@MainActor
final class AppleSignInHandler: NSObject {

    struct Credential {
        let identityToken: String   // raw JWT from Apple
        let rawNonce: String        // un-hashed — sent to backend
    }

    private var continuation: CheckedContinuation<Credential?, Never>?
    private var pendingRawNonce: String = ""

    // MARK: - Public

    func signIn() async -> Credential? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation

            let rawNonce = generateNonce()
            pendingRawNonce = rawNonce

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(rawNonce)    // Apple receives the SHA-256 hex digest

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Nonce Helpers

    private func generateNonce(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard status == errSecSuccess else {
            fatalError("SecRandomCopyBytes failed: OSStatus \(status)")
        }
        return Data(randomBytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInHandler: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let identityToken = String(data: tokenData, encoding: .utf8)
        else {
            continuation?.resume(returning: nil)
            continuation = nil
            return
        }
        continuation?.resume(returning: Credential(
            identityToken: identityToken,
            rawNonce: pendingRawNonce
        ))
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // ASAuthorizationError.canceled (1001) = user tapped Cancel — not a real failure.
        continuation?.resume(returning: nil)
        continuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInHandler: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}
