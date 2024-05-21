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
    @Published var merchants: [Merchant] = []
    
    // params
    @Published var fromAsset: String = "TON"
    @Published var avaialableAssets: [String: [Merchant]] = [:]
    
    @Published var isBuy: Bool = true
    @Published var amount: Double = 0
    @Published var country: String = "fr"
    @Published var method: String = "creditcard.global" // credit card, crypto
    @Published var merchant: String = "" // service provider
    
    static let countriesInfo: [String: String] = [
        "RU": "Russia Ruble",
        "UA": "Ukraine Hryvnia",
        "DE": "Germany Euro",
        "ID": "Indonesia Rupiah",
        "IN": "India Rupee",
        "US": "United States Dollar",
        "BY": "Belarus Ruble",
        "GB": "United Kingdom Pound",
        "FR": "France Euro",
        "BR": "Brazil Real",
        "NG": "Nigeria Naira",
        "CA": "Canada Dollar",
    ]
    
    func update(completion: FiatMethodHandler? = nil) {
        Network(apiFetcher: APIFetcher()).getFiatMethods { result in
            switch result {
            case .success(let data):
                self.resp = data
                
                // TODO: update default params
                if let countries = data.data?.layoutByCountry {
                    self.countries = countries
                    self.country = self.countries.first?.countryCode ?? "?"
                }
                
                self.updateMerchants()
                
            case .failure(let error):
                self.error = error.localizedDescription
            }
            
            completion?(result)
        }
    }
    
    func updateMerchants() {
        guard self.resp.data != nil else { return }
        
        // reset
        self.avaialableAssets = [:]
        
        switch isBuy {
        case true:
            
            // update asset,each have N merchant available (for 1 mode, not include swap)
            self.resp.data?.buy?.forEach({ item in
                if item.type?.contains("buy") ?? false {
                    item.assets?.forEach({ asset in
                        self.avaialableAssets[asset.uppercased()] = item.items
                    })
                }
            })
            
        case false:
            
            // update asset,each have N merchant available (for 1 mode, not include swap)
            self.resp.data?.sell?.forEach({ item in
                if item.type?.contains("sell") ?? false {
                    item.assets?.forEach({ asset in
                        self.avaialableAssets[asset.uppercased()] = item.items
                    })
                }
            })
        }
    }
}

enum PayMethod: String, CaseIterable{
    case creditCardVisaMaster = "creditcard.global"
    case creditCardRUB = "creditcard.rub"
    case crypto = "crypto"
    case applePay = "applepay"
    
    func getImage() -> String {
        switch self {
        case .creditCardVisaMaster: return "ic.buysell.creditcard.global"
        case .creditCardRUB: return "ic.buysell.creditcard.rub"
        case .crypto: return "ic.buysell.crypto"
        case .applePay: return "ic.buysell.applepay"
        }
    }
    
    func getName() -> String {
        switch self {
        case .creditCardVisaMaster: return "buysell.creditcard.global"
        case .creditCardRUB: return "buysell.creditcard.rub"
        case .crypto: return "buysell.crypto"
        case .applePay: return "buysell.applepay"
        }
    }
}


extension View {
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}

struct BuySellConfig: View {
    @StateObject var vm: BuySellVM = BuySellVM()
    
    @State private var temp = "0"
    
    @ViewBuilder
    func textField() -> some View {
        HStack(alignment: .center, spacing: 4) {
            DynamicFontSizeTextField(text: $temp, maxLength: 15)
                .fixedSize(horizontal: true, vertical: false)
                .keyboardType(.decimalPad)
                .foregroundColor(Color.white)
                .multilineTextAlignment(.center)

//            Button {} label: {
//                Text(vm.fromAsset)
//                    .font(.system(size: DynamicFontSizeTextField.dynamicSize(temp), weight: .bold, design: .default))
//            }
//            .foregroundColor(Color.gray.opacity(0.8))
            
            Picker("Token?", selection: $vm.fromAsset) {
                ForEach(vm.avaialableAssets.keys.sorted(), id: \.self) { key in
                    Text(key).tag(key)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    var body: some View {
        VStack {
            HeaderView {
                HStack(alignment: .center, spacing: 8, content: {
                    Button {
                        vm.isBuy = true
                    } label: {
                        Text("Buy")
                    }
                    .foregroundColor(vm.isBuy ? .primary : .secondary)
                    
                    Button {
                        vm.isBuy = false
                    } label: {
                        Text("Sell")
                            .font(.body.bold())
                    }
                    .foregroundColor(!vm.isBuy ? .primary : .secondary)
                })
            } left: {
                Button {} label: {
                    Text(vm.country)
                        .font(.body.bold())
                }
            } right: {
                Button {} label: {
                    Text("x")
                        .font(.body.bold())
                }
            }
            .frame(height: 50)
            
            if vm.resp.data == nil {
                Spacer()
                Text("Loading ..")
            } else {
                
                VStack(alignment: .center, spacing: 16) {
                    textField()
                    Text("6000.01 USD")
                        .padding(8)
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .overlay(
                            Capsule()
                                .stroke(Color.secondary, lineWidth: 1)
                        )
                    
                    Text("Min. amount: 50 TON")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(height: 180)
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(PayMethod.allCases, id: \.rawValue) { method in
                            Button {
                                vm.method = method.rawValue
                            } label: {
                                HStack {
                                    vm.method == method.rawValue ?
//                                        Image("ic.radio.selected") : Image("ic.radio.unselect")
                                    Text("x") : Text("-")
                                    
                                    Text(method.getName())
                                        .multilineTextAlignment(.leading)
                                        .padding(.leading, 6)
                                    
                                    Spacer()
                                    
                                    Image(method.getImage())
                                }
                            }
                            .frame(height: 50)
                            .padding(.leading, 10)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
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
            }
        }
        .onAppear {
            if vm.resp.data == nil {
                vm.update()
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
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
                    Text("b")
                }
            } right: {
                Button {} label: {
                    Text("x")
                }
            }
            .frame(height: 50)

            Button {
                showCountry = true
            } label: {
                HStack {
                    Text(vm.country)
                    if let info = BuySellVM.countriesInfo[vm.country] {
                        Text(info)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                }
            }
            .buttonStyle(BigButtonStyle(backgroundColor: .secondary.opacity(0.4), textColor: .white))
            
            if let currency = vm.countries.first(where: { $0.countryCode == vm.country })?.currency,
                let methods = vm.countries.first(where: { $0.countryCode == vm.country })?.methods,
                !methods.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(methods) { method in
                            Button {
                                vm.merchant = method
                            } label: {
                                HStack {
                                    Color.blue.frame(width: 52, height: 52)
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(method)
                                        Text("? \(currency.uppercased()) for 1 \(vm.fromAsset.uppercased())")
                                    }
                                    
                                    Spacer()
                                    
                                    vm.merchant == method ?
//                                        Image("ic.radio.selected") : Image("ic.radio.unselect")
                                    Text("x") : Text("")
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
                Spacer()
                Text("select another country =]")
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
//                    Image(systemName: "xmark")
                    Text("x")
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
                                    if let info = BuySellVM.countriesInfo[item.countryCode ?? ""] {
                                        Text(info)
                                    }
                                    
                                    Spacer()
    
                                    if vm.country == item.countryCode ?? "" {
//                                        Image("ic.currency.checkmark")
                                        Image(systemName: "checkmark")
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 50)
                            .foregroundColor(Color.primary)
                        }
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            
            Button {} label: {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
//            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding()
    }
}

enum MerchantIcon: String {
    case mercuryo = "mercuryo"
    case transak = "transak"
    case neocrypto = "neocrypto"
    case dreamwalker = "dreamwalker"
    
    func getImage() -> String {
        switch self {
        case .mercuryo: return "ic.merchant.mercuryo.pdf"
        case .transak: return "ic.merchant.transak.pdf"
        case .neocrypto: return "ic.merchant.neocrypto.pdf"
        case .dreamwalker: return "ic.merchant.dreamwalker.pdf"
        }
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
//                    Image(systemName: "xmark")
                    Text("x")
                }
            }
            .frame(height: 50)
            
            Color.blue
                .frame(width: 72, height: 72)
            Text(vm.merchant)
            Text("Instantly buy with a credit card")
            
            VStack(alignment: .leading, spacing: 6) {
                Text("You pay")
//                textField(amount: $vm.amount, isFocus: $isFocusPay)
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
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    @ViewBuilder
    func textField(amount: Binding<Double>, isFocus: Binding<Bool>) -> some View {
        let text = Binding<String>(
            get: {
                amount.wrappedValue > 0 ?
                String(format: "%.5f", amount.wrappedValue) : "0"
            },
            set: { text in
//                vm.amount = Double(text) ?? 0
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

struct Demo: View {
    @State private var temp = "0"

    var body: some View {
        VStack {
            DynamicFontSizeTextField(text: $temp, maxLength: 15)
                .padding()
                .background(Color.gray.opacity(0.5))
                .cornerRadius(8)
                .border(.red, width: 1)

            Text("You entered: \(temp)")
                .font(.headline)
                .padding()
        }
        .padding()
    }
}

#Preview {
    NavigationView {
//        Demo()
        
        BuySellConfig()
        
//        BuySellMerchant()
//            .environmentObject(BuySellVM())
    }
}

struct DynamicFontSizeTextField: UIViewRepresentable {
    @Binding var text: String
    var maxLength: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.text = text
        textField.font = UIFont.systemFont(ofSize: DynamicFontSizeTextField.dynamicSize(text))
        textField.textColor = UIColor.label
        textField.textAlignment = .center
        textField.keyboardType = .decimalPad
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if text.isEmpty {
            text = "0"
        }
        
        uiView.text = text
        uiView.font = UIFont.systemFont(ofSize: DynamicFontSizeTextField.dynamicSize(text))
    }
    
    static func dynamicSize(_ text: String) -> CGFloat {
        switch text.count {
        case 0...5:
            return 36
        case 6...8:
            return 34
        case 9...12:
            return 28
        case 13...15:
            return 24
        default:
            return 18
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: DynamicFontSizeTextField

        init(parent: DynamicFontSizeTextField) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            let newText = textField.text ?? ""
            if newText.count > parent.maxLength {
                textField.text = String(newText.prefix(parent.maxLength))
            }
            parent.text = textField.text ?? ""
            textField.font = UIFont.systemFont(ofSize: DynamicFontSizeTextField.dynamicSize(parent.text))
        }
    }
}
