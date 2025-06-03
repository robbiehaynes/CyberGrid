//
//  Store.swift
//  CyberGrid
//
//  Created by Robert Haynes on 03/06/2025.
//

import StoreKit

class Store {
    
    static let shared = Store()
    private var productIDs = ["com.haynoways.CyberGrid.removeAds"]
    
    var products: [Product] = []
    var purchasedProducts: Set<Product> = []
    var transactionListener: Task<Void, Error>?
    
    private var productsLoaded = false
    
    init() {
        transactionListener = listenForTransactions()
    }
    
    func loadProducts() async {
        guard !productsLoaded else { return }
        do {
            products = try await Product.products(for: productIDs)
            productsLoaded = true
            await updateCurrentEntitlements()
        } catch {
            print("Error fetching product: \(error.localizedDescription)")
        }
    }
    
    func purchaseProduct(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(.verified(let transaction)):
            purchasedProducts.insert(product)
            await transaction.finish()
            return transaction
        default:
            return nil
        }
    }
    
    func listenForTransactions() -> Task < Void, Error > {
        return Task.detached {
            for await result in Transaction.updates {
                await self.handle(transactionVerification: result)
            }
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
    }
    
    private func updateCurrentEntitlements() async {
        for await result in Transaction.currentEntitlements {
            await self.handle(transactionVerification: result)
        }
    }
    
    private func handle(transactionVerification result: VerificationResult <Transaction> ) async {
        switch result {
        case let.verified(transaction):
            guard
                let product = self.products.first(where: {
                    $0.id == transaction.productID
                })
            else {
                return
            }
            self.purchasedProducts.insert(product)
            await transaction.finish()
        default:
            return
        }
    }
}
