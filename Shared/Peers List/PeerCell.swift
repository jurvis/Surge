//
//  PeerCell.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import SwiftUI

struct PeerCell: View {
    @StateObject var viewModel: PeerCellViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(viewModel.name)
            Spacer()
            
            HStack {
                Text(viewModel.liquidityDisplayString)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Color(.darkGray))
                statusImage()
                    .font(.system(size: 14))
            }
        }
    }
    
    @ViewBuilder
    fileprivate func statusImage() -> some View {
        switch viewModel.connectionStatus {
        case .unconnected:
            Image(systemName: "circle.fill")
                .foregroundColor(Color(.systemGray2))
        case .pending(_):
            Image(systemName: "circle.dotted")
                .foregroundColor(.orange)
        case .connected(_):
            Image(systemName: "circle.fill")
                .foregroundColor(.green)
        }
    }
}

struct PeerCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            PeerCell(
                viewModel: PeerCellViewModel(name: "Alice",
                                             connectionStatus: .connected(
                                                PeerCellViewModel.LiquidityInformation(inboundLiqudity: 100, outboundLiqudity: 250)
                                             ))
            )
        }
    }
}
