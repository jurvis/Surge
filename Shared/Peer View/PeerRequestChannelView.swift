//
//  PeerRequestChannelView.swift
//  Surge
//
//  Created by Jurvis on 12/25/22.
//

import SwiftUI

struct PeerRequestChannelView: View {
    @EnvironmentObject var peer: Peer
    @StateObject var viewModel: PeerRequestChannelViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading) {
                    TextField("Channel Value", text: $viewModel.channelValue)
                        .keyboardType(.numberPad)
                        .font(.subheadline)
                        .padding(.leading)
                        .frame(height: 44)
                    
                    Divider().padding(.leading, 12)
                    
                    TextField("Reserve Amount", text: $viewModel.reserveAmount)
                        .keyboardType(.numberPad)
                        .font(.subheadline)
                        .padding(.leading)
                        .frame(height: 44)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Channel Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.createNewFundingTransaction(for: peer)
                    }
                } label: {
                    Text("Open Channel")
                }
                .disabled(!viewModel.isSaveButtonEnabled)
            }
        }
    }
}

struct PeerRequestChannelView_Previews: PreviewProvider {
    static var previews: some View {
        PeerRequestChannelView(viewModel: PeerRequestChannelViewModel(isViewActive: .constant(true)))
    }
}
