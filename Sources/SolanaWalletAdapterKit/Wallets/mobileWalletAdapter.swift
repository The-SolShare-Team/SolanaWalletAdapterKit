//
//  mobileWalletAdapter.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-22.
//

import Foundation
import SwiftUI
import Combine
import CryptoKit


// note that all this works because swift classes are reference type, do NOT do this with structs

// each provider public function is wrapped for convenient calling
// should probably include this as an example implementation in docs

// TODO: just realised this should not be in the demo app, but should be in the package itself

// separate the UIapp calls and just do them directly in the demo app

public class MobileWalletAdapter: ObservableObject {
    @Published public var storedWallets: [String: Wallet?]
    @Published public var activeWallet: Wallet?
    @Published public var demoAppMetadataUrl: String
    @Published public var redirectProtocol: String
    
    public init(demoAppMetadataUrl: String = "https://solshare.syc.onl", redirectProtocol: String = "solanaMWADemo://") {
        storedWallets =
        [ "backpack": nil,
            "solflare": nil,
            "phantom": nil] //put hard coded into a constants file eventually
        activeWallet = nil
        self.demoAppMetadataUrl = demoAppMetadataUrl
        self.redirectProtocol = redirectProtocol
    }
    
//    public func checkWhatWalletsExists() -> [String: Bool] {
//        var returnDict: [String : Bool] = [:]
//        for (key, wallet) in storedWallets {
//            returnDict["key"] = (wallet != nil)
//        }
//        return returnDict
//    }
    
    public func ensureWalletExists(_ provider: WalletProvider) throws -> Wallet? {
        guard let wallet = storedWallets[provider.rawValue] else {
            throw NSError(domain: "wallet", code: 0, userInfo: [NSLocalizedDescriptionKey: "No wallet found for this provider"])
        }
        return wallet!
    }
    
    
    public func activateExistingWallet(provider: WalletProvider) throws {
        let wallet = try ensureWalletExists(provider)
        activeWallet = wallet!
    }
    
    
    public func createNewWallet(privateKey: Curve25519.KeyAgreement.PrivateKey?, provider: WalletProvider = WalletProvider.backpack) {
        activeWallet = WalletFactory.createWallet(provider: provider, privateKey: privateKey)!
        storedWallets[activeWallet!.provider.rawValue] = activeWallet
    }
    
    // wrappers for active wallet's provider public functions for easier calling and auto passing of certain parameters (namely redirect link)
    
    private func openURL(_ url: URL) async throws {
        #if canImport(UIKit)
        _ = await MainActor.run {
            UIApplication.shared.open(url)
        }
        #elseif canImport(AppKit)
        _ = await MainActor.run{
            NSWorkspace.shared.open(url)
        }
        #else
        throw PlatformError.unsupported
        #endif
    }
    
    
    public func connect(cluster: String?) async throws {
        let connectionUrl = try await activeWallet?.connect(appUrl: demoAppMetadataUrl, redirectLink: "\(redirectProtocol)connected", cluster: cluster)
        try await openURL(connectionUrl!)
    }
    
    public func disconnect() async throws {
        let disconnectUrl = try await activeWallet?.disconnect(redirectLink: "\(redirectProtocol)disconnected")
        try await openURL(disconnectUrl!)
    }
    
    public func signAndSendTransaction(transaction: Data, sendOptions: SendOptions?) async throws {
        let signAndSendTransUrl = try await activeWallet?.signAndSendTransaction(redirectLink: "\(redirectProtocol)signAndSendTransaction", transaction: transaction, sendOptions: sendOptions)
        try await openURL(signAndSendTransUrl!)
    }
    
    public func signAllTransactions(transactions: [Data]) async throws {
        let signAllUrl = try await activeWallet?.signAllTransactions(redirectLink: "\(redirectProtocol)signAllTransactions", transactions: transactions)
        try await openURL(signAllUrl!)
    }
    
    public func signTransaction(transaction: Data) async throws {
        let signTransUrl = try await activeWallet?.signTransaction(redirectLink: "\(redirectProtocol)signTransaction", transaction: transaction)
        try await openURL(signTransUrl!)
    }
    public func signMessage(message: String, encodingFormat: EncodingFormat?) async throws {
        let signMessageUrl = try await activeWallet?.signMessage(redirectLink: "\(redirectProtocol)signMessage", message: message, encodingFormat: encodingFormat)
        try await openURL(signMessageUrl!)
    }
    
    public func browse(url: String, ref: String) async throws {
        let browseUrl = try await activeWallet?.browse(url: url, ref: ref)
        try await openURL(browseUrl!)
    }
    
    // Main deep link redirect handler, browse doesn't conform to this redirect deep link pipeline
    
    public func handleRedirect(_ url: URL) async throws -> (any WalletResponse)? {
        var walletResponse: (any WalletResponse)? = nil
        switch url.host! {
        case "connected":
            walletResponse = try await (activeWallet?.handleConnectRedirect(url))!
        case "disconnected":
            try await activeWallet?.handleDisconnectRedirect(url)
            self.activeWallet = nil
        case "signAndSendTransaction":
            walletResponse = try await (activeWallet?.handleSignAndSendTransactionRedirect(url))!
        case "signAllTransactions":
            walletResponse = try await (activeWallet?.handleSignAllTransactionsRedirect(url))!
        case "signTransaction":
            walletResponse = try await (activeWallet?.handleSignTransactionRedirect(url))!
        case "signMessage":
            walletResponse = try await (activeWallet?.handleSignMessageRedirect(url))!
        default:
            print(url.host!) // should be browse
            break;
        }
        return walletResponse
        
    }
}
