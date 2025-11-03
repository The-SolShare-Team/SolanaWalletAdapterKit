//
//  File.swift
//  SolanaWalletAdapterKit
//
//  Created by William Jin on 2025-11-02.
//

import Foundation

public enum WalletAdapterError: LocalizedError {
    case urlBuildFailed(baseURL: String)
    case walletNotConnected
    case missingSession
    case missingSharedKey
    case invalidResponse
    case missingResponseParameters([String])
    case walletError(code: String, message: String?)
    case decryptionFailed(reason: String)
    case encryptionFailed(reason: String)
    case invalidPublicKey
    case invalidCluster(String)
    case timeout
    case userCancelled
    case walletNotInstalled(walletName: String)
    
    public var errorDescription: String? {
        switch self {
        case .urlBuildFailed(let baseURL):
            return "Failed to build URL with base: \(baseURL)"
        case .walletNotConnected:
            return "Wallet is not connected. Please connect first."
        case .missingSession:
            return "Session is missing. Connection may have been lost."
        case .missingSharedKey:
            return "Shared encryption key is missing. Please reconnect."
        case .invalidResponse:
            return "Received invalid response from wallet"
        case .missingResponseParameters(let params):
            return "Missing required parameters in wallet response: \(params.joined(separator: ", "))"
        case .walletError(let code, let message):
            if let msg = message {
                return "Wallet error (\(code)): \(msg)"
            }
            return "Wallet error: \(code)"
        case .decryptionFailed(let reason):
            return "Failed to decrypt wallet response: \(reason)"
        case .encryptionFailed(let reason):
            return "Failed to encrypt request: \(reason)"
        case .invalidPublicKey:
            return "Invalid public key format"
        case .invalidCluster(let cluster):
            return "Invalid cluster: \(cluster)"
        case .timeout:
            return "Request timed out. Please try again."
        case .userCancelled:
            return "User cancelled the request"
        case .walletNotInstalled(let walletName):
            return "\(walletName) wallet is not installed"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .walletNotConnected, .missingSession, .missingSharedKey:
            return "Try reconnecting to your wallet."
        case .timeout:
            return "Check your internet connection and try again."
        case .walletNotInstalled(let walletName):
            return "Please install \(walletName) from the App Store."
        case .userCancelled:
            return nil
        default:
            return "If the problem persists, please contact support."
        }
    }
}
