//
//  draftApp.swift
//  draft
//
//  Created by davidtam on 20/5/24.
//

import SwiftUI

@main
struct draftApp: App {
    
    @State var showBuySell: Bool = false
    @State var showSwap: Bool = false
    @State var showStake: Bool = false
    @State var showSlide: Bool = false
    
    var body: some Scene {
        WindowGroup {
//            Demo()
            
            NavigationView {
                VStack {
                    Spacer()
                    Text("BuySell").onTapGesture{ showBuySell = true }
                    Spacer()
                    Text("Swap").onTapGesture{ showSwap = true }
                    Spacer()
                    Text("Stake").onTapGesture{ showStake = true }
                    Spacer()
                    Text("Other").onTapGesture { showSlide = true }
                    Spacer()
                }
                
                .sheet(isPresented: $showBuySell, content: {
                    NavigationView {
                        BuySell(vm: BuySellVM(didTapDismiss: {
                            showBuySell = false
                        }))
                    }
                })
                
                .sheet(isPresented: $showSwap, content: {
                    NavigationView { Swap(vm: SwapVM(didTapDismiss: {
                        showSwap = false
                    }))}
                })
                
                .sheet(isPresented: $showStake, content: {
                    NavigationView { Stake(vm: StakeViewModel(didTapDismiss: {
                        showStake = false
                    }))}
                })
                
                .sheet(isPresented: $showSlide, content: {
                    NavigationView { DragDemo() }
                })
            }
            
        }
    }
}
