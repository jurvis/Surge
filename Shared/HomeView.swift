//
//  ContentView.swift
//  Shared
//
//  Created by Jurvis on 9/4/22.
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 48) {
                        VStack {
                            Text("100")
                                .font(.system(size: 72, design: .rounded))
                                .foregroundColor(Color(.darkText))
                            Text("sats")
                                .font(.system(.callout))
                                .foregroundColor(Color(.darkText))
                        }
                                            
                        HStack(spacing: 62) {
                            Button {
                                print("Show Send Screen")
                            } label: {
                                VStack(spacing: 4) {

                                    Image(systemName: "paperplane.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.orange)
                                    Text("Send")
                                        .font(.callout)
                                        .foregroundColor(Color(.darkText))
                                }
                            }
                            
                            Button {
                                print("Show Receive Screen")
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "qrcode.viewfinder")
                                        .font(.system(size: 48))
                                        .foregroundColor(.teal)
                                    Text("Receive")
                                        .font(.callout)
                                        .foregroundColor(Color(.darkText))
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.showTransactionHistory()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 40))
                            .foregroundColor(Color(.systemGray))
                    }
                }
                .navigationBarItems(
                    trailing: Button(action: {
                        print("Open Peers Menu")
                        viewModel.showPeers()
                    }, label:  {
                        Image(systemName: "person.3.sequence.fill")
                            .foregroundColor(Color(.darkText))
                    })
                )
            }
            .sheet(item: $viewModel.sheetToShow) { sheet in
                switch sheet {
                case .transactionHistory:
                    TransactionListView()
                case .peers:
                    PeersListView()
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(viewModel: HomeViewModel())
    }
}
