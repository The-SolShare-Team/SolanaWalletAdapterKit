#import "@preview/zebraw:0.5.5": *

#set page(paper: "us-letter", height: auto)
#show link: underline
#set par(justify: true)

#show heading.where(level: 2): it => [
  #pagebreak(weak: true)
  #it
]

#show outline.entry: emph

#heading(outlined: false)[SolanaWalletAdapterKit]

The following document outlines the core design goals of the project, through a mix of code examples and comments. The APIs described below are still in development and heavily subject to change.

Some liberties were taken in regards to the standard Mobile Wallet Adapter API, in order to integrate seamlessly with Swift idioms.

Though not reflected below, type and thread safety were core considerations in the underlying technical implementations.

#outline(indent: 0pt)

== Easy integration with SwiftUI and UIKit

Due to the iOS sandbox, communication must be made through deeplinking. SolanaWalletAdapterKit provides a unified global callback handler for easy integration.

#zebraw(
  highlight-lines: (2, 4, 12),
  ```swift
  import SwiftUI
  import SolanaWalletAdapterKit

  SolanaWalletAdapter.registerCallbackScheme("myappcallback")

  @main
  struct MyApp: App {
      var body: some Scene {
          WindowGroup {
              ContentView()
                  .onOpenURL {
                    if SolanaWalletAdapter.handleCallback($0) else { return }
                    // ...
                  }
          }
      }
  }
  ```,
)

Or in UIKit,
#zebraw(
  highlight-lines: (2, 4, 9),
  ```swift
  import UIKit
  import SolanaWalletAdapterKit

  SolanaWalletAdapter.registerCallbackScheme("myappcallback")

  func application(_ application: UIApplication,
                   open url: URL,
                   options: [UIApplicationOpenURLOptionsKey : Any] = [:] ) -> Bool {
      if SolanaWalletAdapter.handleCallback($0) else { return true }
      // ...
  }
  ```,
)

== Type-safe RPC requests
To compensate for Phantom's deprecation of the #link("https://docs.phantom.com/phantom-deeplinks/provider-methods/signandsendtransaction")[SignAndSendTransaction] deeplinking endpoint, SolanaWalletAdapterKit provides a type-safe interface for making RPC requests to the Solana blockchain.#footnote[Only a subset of RPC methods (those required for transaction broadcasting) were found to be within the project's current scope.]

Example 1: `getVersion` RPC Method
#zebraw(
  ```swift
  let client = SolanaRPCClient(endpoint: .mainnet)
  let response = try await client.getVersion()
  ```,
)

Example 2: `getLatestBlockhash` RPC Method
#zebraw(
  ```swift
  let client = SolanaRPCClient(endpoint: .devnet)
  let response = try await client.getLatestBlockhash(configuration: (
                                                        commitment: .processed,
                                                        minContextSlot: 10))
  let latestBlockhash = response.blockhash
  ```,
)

Normally, the end-consummer of this library should only seldom need to resort to an RPC client, as they should, most of the time, be abstracted by higher level methods.

== Convenient transaction building
Transactions are the core component of any interaction with the blockchain, and so, having
ergonomic and idiomatic ways to build them is crucial. To achieve this, we created an API deeply inspired by SwiftUI itself, providing a declarative "DSL" for transaction building.

#zebraw(
  ```swift
    let myTransaction = try Transaction(
        blockhash: try await client.getLatestBlockhash().blockhash
    ) {
        for i in 0..<3 {
            MemoProgram.publishMemo(
                account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                memo: "abc: \(i)")
        }
        if someCondition {
            SystemProgram.transfer(
                from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                lamports: Int64(i))
        }
    }
  ```,
)

Programs are also easy to define, thanks to powerful protocols taking care of most of the heavy lifting.

#zebraw(
  ```swift
  import SwiftBorsh

  public enum MemoProgram: Program, Instruction {
      public static let programId: PublicKey =
        "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr"

      case publishMemo(account: PublicKey, memo: String)

      public var accounts: [AccountMeta] {
          return switch self {
          case .publishMemo(let account, _):
              [
                  AccountMeta(publicKey: account, isSigner: true, isWritable: true)
              ]
          }
      }

      public var data: BorshEncodable {
          switch self {
          case .publishMemo(_, let memo): memo
          }
      }
  }
  ```,
)

In cases where complicated payloads are needed, the encoding and decoding can be offloaded to the `SwiftBorsh` companion library, a specification-compliant implementation of the Borsh format. All primitive types are handled transparently, from strings to results, and compound types can have their implementation automatically generated by conformance macros.

#zebraw(
  highlight-lines: (1, 9),
  ```swift
  @BorshEncodable
  private struct CreateAccountData {
      let index: Int32 = 2
      let lamports: Int64
      let space: Int64
      let programId: PublicKey
  }

  @BorshCodable
  enum MyEnum: Equatable {
      case A, B
      case C(test: Int32, test2: Int64, test3: (Int64, Int64))
      case D(Int32, test: Int64, (Int64, Int64), Float32)
  }
  ```,
)

== Transparent wallet connections

SolanaWalletAdapterKit provides a unified interface for connecting to multiple Solana wallets, abstracting away the differences in their deeplinking schemes. Connecting to a wallet is as simple as calling a single method, and the library takes care of the rest.

#zebraw(
  ```swift
  let myApp = AppIdentity(name: "MyAwesomeApp",
                          url: "solshare.team",
                          icon: "favicon.ico")

  let wallet: Wallet = switch userSelection { // User selection from UI
      case .phantom: PhantomWallet(for: myApp, cluster: .devnet)
      case .solflare: SolflareWallet(for: myApp, cluster: .devnet)
      case .backpack: BackpackWallet(for: myApp, cluster: .devnet)
  }
  ```,
)

The first time the wallet is used, it needs to be paired with the app.
#zebraw(
  ```swift
  if !wallet.connected {
    try await wallet.pair()
  }
  ```,
)

Once this is done, all the expected operations can be executed, under an implementation-agnostic API. That is, independently of the native functionality of the wallet.
#zebraw(
  ```swift
  try await wallet.signAndSendTransaction(myTransaction)
  ```,
)
For example, in the case of Phantom, the above would automatically be polyfilled into a `signTransaction` deeplink and a native transaction broadcast through an RPC client.

For convenience, the wallet also exposes property like `publicKey` in a way that is compatible with SwiftUI's reactivity model.

Implementing new wallets is also almost trivial. In the case of a fully standard deeplink compliant wallet like Solflare, it can be done in as few as three lines of code.
#zebraw(
  ```swift
  struct SolflareWallet: DeeplinkWallet {
      static let baseURL = URL(string: "https://solflare.com/ul/v1")!
  }
  ```,
)
