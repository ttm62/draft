//
//  SwapConfig.swift
//  draft
//
//  Created by davidtam on 20/5/24.
//

import SwiftUI

struct Asset {
    var name: String
    var code: String
    var balance: Double
}

@MainActor final
class SwapVM: ObservableObject {
    @Published var balances: [String: Asset] = [:]
    
    @Published var sendToken: String = "TONN"
    @Published var sendAmount: Double = 1234
    @Published var receiveToken: String = ""
    @Published var receiveAmount: Double = 0
    
    let layer1: Color = Color(UIColor.secondarySystemBackground)
    let layer2: Color = Color(UIColor.secondarySystemFill)
    let layer3: Color = Color(UIColor.secondaryLabel)
    let mainLabel: Color = Color.primary
    let secondaryLabel: Color = Color.secondary
    let cornerRadius: CGFloat = 14
}

struct SwapConfig: View {
    @StateObject var vm = SwapVM()
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                
                HeaderView {
                    Text("Swap")
                        .font(.title3.bold())
                        .foregroundColor(vm.mainLabel)
                } left: {
                    Image(systemName: "slider.horizontal.2.square")
                        .resizable()
                        .foregroundColor(vm.mainLabel)
                        .frame(width: 16, height: 16)
                        .padding(8)
                        .background(vm.layer2)
                        .clipShape(Circle())
                } right: {
                    Image(systemName: "xmark")
                        .resizable()
                        .foregroundColor(vm.mainLabel)
                        .frame(width: 16, height: 16)
                        .padding(8)
                        .background(vm.layer2)
                        .clipShape(Circle())
                }
                .frame(height: 50)

                ZStack {
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .center) {
                                Text("Send")
                                    .font(.callout)
                                    .foregroundColor(vm.secondaryLabel)
                                Spacer()
                                Text("Balance: 99,000.01 TON")
                                    .font(.callout)
                                    .foregroundColor(vm.secondaryLabel)
                                Button {} label: {
                                    Text("MAX")
                                        .font(.body.bold())
                                }
                            }
                            
                            HStack(alignment: .center) {
                                Button {} label: {
                                    HStack(alignment: .center, spacing: 4) {
                                        Color.primary.frame(width: 24, height: 24)
                                            .clipShape(Capsule())
                                        Text("TON")
                                            .font(.body.bold())
                                            .foregroundColor(vm.mainLabel)
                                    }
                                    .padding(6)
                                    .background(vm.layer3)
                                    .clipShape(Capsule())
                                }
                                .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("1000")
                                    .font(.title.bold())
                                    .foregroundColor(vm.mainLabel)
                            }
                        }
                        .padding(.horizontal)
                        .frame(height: 100)
                        .background(vm.layer2)
                        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .center) {
                                Text("Receive")
                                    .font(.callout)
                                    .foregroundColor(vm.secondaryLabel)
                                Spacer()
                            }
                            
                            HStack(alignment: .center) {
                                Button {} label: {
                                    HStack(alignment: .center, spacing: 4) {
    //                                    Color.white.frame(width: 20, height: 20)
    //                                        .clipShape(Capsule())
                                        Text("Choose".uppercased())
                                            .font(.body.bold())
                                            .foregroundColor(vm.mainLabel)
                                    }
                                    .padding(6)
                                    .background(vm.layer3)
                                    .clipShape(Capsule())
                                }
                                .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("0")
                                    .font(.title.bold())
                                    .foregroundColor(vm.mainLabel)
                            }
                        }
                        .padding(.horizontal)
                        .frame(height: 100)
                        .background(vm.layer2)
                        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                    }
                    
                    HStack(alignment: .center) {
                        Spacer()
                        Image(systemName: "arrow.up.arrow.down")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundColor(vm.mainLabel)
                            .padding(10)
                            .background(vm.layer3)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 30)
                }
                
                Text("Choose Token")
                    .font(.body.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(vm.layer2)
                    .foregroundColor(vm.mainLabel)
                    .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                
                Spacer()
            }
            .navigationBarBackButtonHidden(true)
            
            .background(vm.layer1)
            .padding([.top, .horizontal])
            
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}

#Preview {
    SwapConfig()
}
