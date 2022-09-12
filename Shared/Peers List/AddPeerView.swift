//
//  AddPeerView.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import SwiftUI

struct AddPeerView: View {
    @StateObject var viewModel: AddPeerViewModel = AddPeerViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading) {
                    TextField("Peer Public Key", text: $viewModel.pubKey)
                        .font(.subheadline)
                        .padding(.leading)
                        .frame(height: 44)
                    
                    Divider().padding(.leading, 12)
                    
                    TextField("Name", text: $viewModel.name)
                        .font(.subheadline)
                        .padding(.leading)
                        .frame(height: 44)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
            }
            .navigationTitle("Add Peer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.onDimiss?()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.savePeer()
                    } label: {
                        Text("Save")
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
        }
    }
}

struct AddPeerView_Previews: PreviewProvider {
    static var previews: some View {
        AddPeerView()
    }
}
