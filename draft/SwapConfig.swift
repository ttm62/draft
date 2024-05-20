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
    
    @Published var sendToken: String = ""
    @Published var sendAmount: Double = 0
    @Published var receiveToken: String = ""
    @Published var receiveAmount: Double = 0
}

struct SwapConfig: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HeaderView {
                Text("Swap")
                    .font(.title3.bold())
            } left: {
                Button {} label: {
                    Image(systemName: "slider.horizontal.2.square")
                }
            } right: {
                Button {} label: {
                    Image(systemName: "xmark")
                }
            }
            .frame(height: 50)
            .border(.red, width: 1)

            ZStack {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center) {
                            Text("Send")
                            Spacer()
                            Text("Balance: 99,000.01 TON")
                            Button {} label: {
                                Text("MAX")
                                    .font(.body.bold())
                            }
                        }
                        
                        HStack(alignment: .center) {
                            Button {} label: {
                                HStack(alignment: .center, spacing: 4) {
                                    Color.white.frame(width: 20, height: 20)
                                        .clipShape(Capsule())
                                    Text("TON")
                                        .font(.body.bold())
                                }
                                .padding(6)
                                .background(Color.red)
                                .clipShape(Capsule())
                            }
                            .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("1000")
                                .font(.title.bold())
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 100)
                    .background(Color.gray.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center) {
                            Text("Receive")
                            Spacer()
                        }
                        
                        HStack(alignment: .center) {
                            Button {} label: {
                                HStack(alignment: .center, spacing: 4) {
//                                    Color.white.frame(width: 20, height: 20)
//                                        .clipShape(Capsule())
                                    Text("Choose")
                                        .font(.body.bold())
                                }
                                .padding(6)
                                .background(Color.red)
                                .clipShape(Capsule())
                            }
                            .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("0")
                                .font(.title.bold())
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 100)
                    .background(Color.gray.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                
                HStack(alignment: .center) {
                    Spacer()
                    
                    Button {} label: {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .foregroundColor(Color.gray)
                    }
                    .background(Color.white)
                    .clipShape(Circle())
                }
                .padding(.trailing, 30)
            }
            
            Spacer()
            
            Button {} label: {
                Text("Choose Token")
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding([.top, .horizontal])
        .navigationBarBackButtonHidden(true)
        
        .contentShape(Rectangle())
//        .onTapGesture {
//            hideKeyboard()
//        }
    }
}

#Preview {
    SwapConfig()
}
