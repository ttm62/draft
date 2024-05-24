//
//  draftApp.swift
//  draft
//
//  Created by davidtam on 20/5/24.
//

import SwiftUI

@main
struct draftApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                BuySell()
//                Swap()
//                Stake()
                
//                SwapSlippage()
//                    .environmentObject(SwapVM())
                
//                StakeProvider(
//                    provider: .constant("Tonkeeper Queue #1"),
//                    infoDict: .constant(["APY":"~5%", "Minimal deposit":"1 TON"])
//                )
//                .environmentObject(StakeViewModel())
            }
        }
    }
}
