//
//  ContentView.swift
//  draft
//
//  Created by davidtam on 20/5/24.
//

import SwiftUI

typealias FiatMethodHandler = (Result<FiatMethodResponse, HTTPError>) -> Void

@MainActor final
class BuySellVM: ObservableObject {
    @Published var resp: FiatMethodResponse = .init(success: nil, data: nil)
    @Published var error: String = ""
    
    @Published var countries: [CountryLayout] = []
    
    // params
    @Published var isBuy: Bool = true
    @Published var amount: Double = 0
    @Published var country: String = "FR"
    @Published var method: String = "credit-card" // credit card, crypto
    @Published var merchant: String = "mercuryo" // service provider
    
    func update(completion: FiatMethodHandler? = nil) {
        Network(apiFetcher: APIFetcher()).getFiatMethods { result in
            switch result {
            case .success(let data):
                self.resp = data
                
                // TODO: update default params
                if let countries = data.data?.layoutByCountry {
                    self.countries = countries
                }
                
            case .failure(let error):
                self.error = error.localizedDescription
            }
            
            completion?(result)
        }
    }
}

struct BuySellConfig: View {
    @StateObject var vm: BuySellVM = BuySellVM()
    
    var body: some View {
        VStack {
            HeaderView {
                HStack(alignment: .center, spacing: 8, content: {
                    Button {
                        vm.isBuy = true
                    } label: {
                        Text("Buy")
                            .font(.body.bold())
                    }
                    .foregroundColor(vm.isBuy ? .white : Color(hex: "#8B94A2"))
                    
                    Button {
                        vm.isBuy = false
                    } label: {
                        Text("Sell")
                            .font(.body.bold())
                    }
                    .foregroundColor(!vm.isBuy ? .white : Color(hex: "#8B94A2"))
                })
            } left: {
                Button {} label: {
                    Text(vm.country)
                        .font(.body.bold())
                }
                .foregroundColor(.white)
                .frame(width: 44, height: 32)
                .background(Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            } right: {
                Button {} label: {
                    Image(systemName: "xmark")
                        .font(.body.bold())
                }
                .foregroundColor(.white)
                .frame(width: 44, height: 32)
                .background(Color.secondary)
                .clipShape(Circle())
            }
            .frame(height: 50)
            
            Button {
                vm.update()
            } label: {
                Text("Fiat?")
            }
            
            ScrollView {
                Text(vm.resp.data.debugDescription)
            }
            
            Spacer()
            
            if vm.resp.data != nil {
                NavigationLink {
                    BuySellMerchant()
                        .environmentObject(vm)
                } label: {
                    Text("Continue")
                }
                .buttonStyle(BigButtonStyle(backgroundColor: .blue, textColor: .white))
            } else {
                Text("Loading")
            }
        }
        .padding([.top, .horizontal])
        .navigationBarBackButtonHidden(true)
    }
}

struct BuySellMerchant: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: BuySellVM
    
    @State var showCountry: Bool = false
    @State var showAmount: Bool = false
    
    var body: some View {
        VStack {
            HeaderView {
                VStack {
                    Text("Operator")
                        .font(.title3.bold())
                        .foregroundColor(Color.white)
                    Text(vm.method)
                        .font(.body)
                        .foregroundColor(Color(hex: "#8B94A2"))
                }
            } left: {
                Button {
                    self.presentation.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.bold())
                }
                .foregroundColor(.white)
                .frame(width: 44, height: 32)
                .background(Color.secondary)
                .clipShape(Circle())
            } right: {
                Button {} label: {
                    Image(systemName: "xmark")
                        .font(.body.bold())
                }
                .foregroundColor(.white)
                .frame(width: 44, height: 32)
                .background(Color.secondary)
                .clipShape(Circle())
            }
            .frame(height: 50)

            Button {
                showCountry = true
            } label: {
                HStack {
                    Text(vm.country)
                    Text("Chinese Yuan")
                    Spacer()
                    Button {} label: {
                        Image(systemName: "chevron.up.chevron.down")
                    }
                }
            }
            .buttonStyle(BigButtonStyle(backgroundColor: .secondary.opacity(0.4), textColor: .white))
            
            if let methods = vm.countries.first(where: { $0.countryCode == vm.country })?.methods, !methods.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(methods) { method in
                            Button {
                                vm.merchant = method
                            } label: {
                                HStack {
                                    vm.merchant == method ?
                                        Color.red.frame(width: 52, height: 52) :
                                        Color.blue.frame(width: 52, height: 52)
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(method)
                                        Text("Probably nothing")
                                    }
                                    
                                    Spacer()
                                    
                                    vm.merchant == method ?
                                        Image("ic.radio.selected") : Image("ic.radio.unselect")
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 12)
                        }
                    }
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            } else {
                Text("select another country?, or we not support it yet")
            }
            
            ScrollView {
                Text(vm.resp.data.debugDescription)
            }
            
            Spacer()
            
            NavigationLink(isActive: $showAmount) {
                BuySellAmount()
                    .environmentObject(vm)
            } label: {
                Text("Continue")
            }
            .buttonStyle(BigButtonStyle(backgroundColor: .blue, textColor: .white))
        }
        .padding([.top, .horizontal])
        .navigationBarBackButtonHidden(true)
        
        .sheet(isPresented: $showCountry) {
            BuySellCurrency()
                .environmentObject(vm)
        }
    }
}

struct BuySellCurrency: View {
    @EnvironmentObject var vm: BuySellVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderView {
                Text("Currency")
            } left: {
                Text("")
            } right: {
                Button {
                } label: {
                    Image(systemName: "xmark")
                }
            }
            .frame(height: 50)
            
            if !vm.countries.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(vm.countries) { item in
                            Button {
                                vm.country = item.countryCode ?? ""
                            } label: {
                                HStack(alignment: .center) {
                                    Text(item.currency ?? "")
                                    Text(item.countryCode ?? "")
    
                                    Spacer()
    
                                    if vm.country == item.countryCode ?? "" {
//                                        Image("ic.currency.checkmark")
                                        Image(systemName: "checkmark")
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 50)
                        }
                    }
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            
            Button {
//                dismiss()
                //                onContinue?()
            } label: {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
//            .buttonStyle(BorderedProminentButtonStyle())
        }
        .border(.red, width: 1)
        .padding([.horizontal, .top])
        .navigationBarBackButtonHidden(true)
    }
}

struct BuySellAmount: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: BuySellVM
    
    @State var isFocusPay: Bool = false
    @State var getAmount: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderView {
                EmptyView()
            } left: {
                Button {
                    presentation.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            } right: {
                Button {} label: {
                    Image(systemName: "xmark")
                }
            }
            .frame(height: 50)
            
            Color.blue
                .frame(width: 72, height: 72)
            Text(vm.merchant)
            Text("Instantly buy with a credit card")
            
            VStack(alignment: .leading, spacing: 6) {
                Text("You pay")
                textField(amount: $vm.amount, isFocus: $isFocusPay)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.secondary.opacity(0.2))
            .clipShape(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
//            .overlay {
//                RoundedRectangle(cornerRadius: 10, style: .continuous)
//                    .stroke(isFocusPay ? Color.blue : Color.clear, lineWidth: 2)
//            }
            .keyboardType(.decimalPad)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("You get")
                textField(amount: $getAmount, isFocus: .constant(false))
                    .disabled(true)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.secondary.opacity(0.2))
            .clipShape(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .keyboardType(.decimalPad)
            
            Spacer()
        }
        .padding([.top, .horizontal])
        .navigationBarBackButtonHidden(true)
        
        .contentShape(Rectangle())
//        .onTapGesture {
//            hideKeyboard()
//        }
    }
    
    @ViewBuilder
    func textField(amount: Binding<Double>, isFocus: Binding<Bool>) -> some View {
        let text = Binding<String>(
            get: {
                amount.wrappedValue > 0 ?
                String(format: "%.5f", amount.wrappedValue) : "0"
            },
            set: { text in
                vm.amount = Double(text) ?? 0
            }
        )
        
        HStack(alignment: .center, spacing: 4) {
            TextField("", text: text, onEditingChanged: { edit in
                isFocus.wrappedValue = edit
            })
            .keyboardType(.decimalPad)
            .fixedSize(horizontal: true, vertical: false)
            .font(.system(size: 20, weight: .regular, design: .rounded))
            .multilineTextAlignment(.center)
            
            Button {} label: {
                Text("TON")
                    .font(.system(size: 20, weight: .regular, design: .default))
            }
            .background(Color.gray.opacity(0.8))
        }
    }
}

#Preview {
    NavigationView {
//        BuySellConfig()
//            .environmentObject(FiatMethodVM())
        
        BuySellMerchant()
            .background(Color(hex: "#11161E"))
    }
}
