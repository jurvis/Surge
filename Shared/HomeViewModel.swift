//
//  HomeViewModel.swift
//  Surge
//
//  Created by Jurvis on 9/10/22.
//

import Foundation

class HomeViewModel: ObservableObject {
    @Published var sheetToShow: Sheet?
    
    enum Sheet: Identifiable {
        var id: Self { self }
        case transactionHistory
        case peers
    }
    
    func showTransactionHistory() {
        self.sheetToShow = .transactionHistory
    }
    
    func showPeers() {
        self.sheetToShow = .peers
    }
}
