//
//  ContentView.swift
//  draft
//
//  Created by davidtam on 20/5/24.
//

import SwiftUI
import UIKit

typealias FiatMethodHandler = (Result<FiatMethodResponse, HTTPError>) -> Void

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

extension BuySellVM {
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
}

final
class BuySellVM: ObservableObject {
    var didTapDismiss: EmptyHandler?
    
    // computed from api
    @Published var resp: FiatMethodResponse = .init(success: nil, data: nil)
    @Published var error: String = ""
    @Published var countries: [CountryLayout] = []
    @Published var assets: [String] = []
    @Published var merchants: [Merchant] = []
    @Published var minAmount: Double = 50
    
    let maxInputLength: Int = 13
    
    // default params
    @Published var isBuy: Bool = true
    @Published var amount: String = "0"
    @Published var asset: String = "TON"
    @Published var rate: Double = 6.1
    @Published var currency: String = "USD"
    @Published var country: String = "US"
    @Published var method: String = PayMethod.creditCardVisaMaster.rawValue
    @Published var merchant: String = "" // service provider
    
    init(didTapDismiss: EmptyHandler? = nil) {
        self.didTapDismiss = didTapDismiss
    }
    
    // theme
    let main: Color = Color.blue
    let layer1: Color = Color(UIColor.secondarySystemBackground)
    let layer2: Color = Color(UIColor.secondarySystemFill)
    let layer3: Color = Color(UIColor.secondaryLabel)
    let mainLabel: Color = Color.primary
    let secondaryLabel: Color = Color.secondary
    
    let tagTint: Color = Color.blue
    let tagBackground: Color = Color.blue.opacity(0.3)
    let cornerRadius: CGFloat = 10
    
    // haptic
    var lightFeedback: UIImpactFeedbackGenerator?
    var mediumFeedback: UIImpactFeedbackGenerator?
    var heavyFeedback: UIImpactFeedbackGenerator?
    var rigidFeedback: UIImpactFeedbackGenerator?
    var softFeedback: UIImpactFeedbackGenerator?
    
    func initHaptic() {
        lightFeedback = UIImpactFeedbackGenerator(style: .light)
        lightFeedback?.prepare()
        
        mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
        mediumFeedback?.prepare()
        
        heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
        heavyFeedback?.prepare()
        
        rigidFeedback = UIImpactFeedbackGenerator(style: .rigid)
        rigidFeedback?.prepare()
        
        softFeedback = UIImpactFeedbackGenerator(style: .soft)
        softFeedback?.prepare()
    }
    
    func update(completion: FiatMethodHandler? = nil) {
        DispatchQueue.main.async {
            Network(apiFetcher: APIFetcher()).getFiatMethods { result in
                switch result {
                case .success(let data):
                    withAnimation {
                        self.resp = data
                    }
                    
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
    }
    
    func updateMerchants() {
        guard self.resp.data != nil else { return }
        
        // reset
        self.assets = []
        self.merchants = []
        
        switch isBuy {
        case true:
            
            // update asset,each have N merchant available (for 1 mode, not include swap)
            self.resp.data?.buy?.forEach({ buyItem in
                if let assets = buyItem.assets, buyItem.type?.contains("buy") ?? false {
                    // update assets
                    self.assets.append(contentsOf: assets)
                    
                    // update merchants
                    self.merchants.append(contentsOf: buyItem.items ?? [])
                }
            })
            
        case false:
            
            // update asset,each have N merchant available (for 1 mode, not include swap)
            self.resp.data?.sell?.forEach({ sellItem in
                if let assets = sellItem.assets, sellItem.type?.contains("sell") ?? false {
                    // update assets
                    self.assets.append(contentsOf: assets)
                    
                    // update merchants
                    self.merchants.append(contentsOf: sellItem.items ?? [])
                }
            })
        }
    }
}

struct BuySell: View {
    @StateObject var vm: BuySellVM
    init(vm: BuySellVM = BuySellVM()) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    @State var showCountry = false
    
    @ViewBuilder
    func textField() -> some View {
        HStack(alignment: .center, spacing: 4) {
            DynamicSizeInputField(text: $vm.amount, maxLength: vm.maxInputLength)
                .fixedSize(horizontal: true, vertical: false)
                .keyboardType(.decimalPad)
                .foregroundColor(vm.mainLabel)
                .multilineTextAlignment(.center)

            Button {} label: {
                Text(vm.asset)
                    .font(.system(size: DynamicFontSizeTextField.dynamicSize(vm.amount), weight: .bold, design: .default))
            }
            .foregroundColor(vm.secondaryLabel)
            
//            Picker("Token?", selection: $vm.asset) {
//                ForEach(vm.assets, id: \.self) { key in
//                    Text(key).tag(key)
//                }
//            }
//            .pickerStyle(.menu)
//            .border(.red, width: 1)
        }
    }
    
    @ViewBuilder
    func buildBuySellHeader() -> some View {
        HStack(alignment: .center, spacing: 8) {
            Button {
                vm.mediumFeedback?.impactOccurred()
                vm.isBuy = true
                vm.updateMerchants()
            } label: {
                VStack(alignment: .center, spacing: 4) {
                    Text("Buy")
                        .font(.title3.bold())
                    
                    if vm.isBuy {
                        Color.blue
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                    } else {
                        Color.clear
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: 50)
            }
            .foregroundColor(vm.isBuy ? .primary : .secondary)
            
            Button {
                vm.mediumFeedback?.impactOccurred()
                vm.isBuy = false
                // vm.updateMerchants()
            } label: {
                VStack(alignment: .center, spacing: 4) {
                    Text("Sell")
                        .font(.title3.bold())
                    
                    if !vm.isBuy {
                        Color.blue
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                    } else {
                        Color.clear
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: 56)
            }
            .foregroundColor(!vm.isBuy ? .primary : .secondary)
        }
    }
    
    @ViewBuilder
    func buildHeader() -> some View {
        HeaderView {
            buildBuySellHeader()
        } left: {
            Text(vm.country)
                .font(.caption.bold())
                .padding(8)
                .background(vm.layer2)
                .clipShape(Capsule())
                .onTapGesture {
                    vm.mediumFeedback?.impactOccurred()
                    showCountry = true
                }
        } right: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onTapGesture {
                    vm.mediumFeedback?.impactOccurred()
                    vm.didTapDismiss?()
                }
        }
        .frame(height: 50)
    }
    
    @ViewBuilder
    func buildLoading() -> some View {
        VStack {
            Spacer()
            Text("Loading ..")
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
        }
    }
    
    @ViewBuilder
    func buildBuySellValue() -> some View {
        Group {
            if let buysellAmount = Double(vm.amount.prefix(vm.maxInputLength)) {
                Text("\((buysellAmount*vm.rate).trimmedString) \(vm.currency.uppercased())")
            } else {
                Text("0 \(vm.currency.uppercased())")
            }
        }
        .padding(8)
        .font(.caption)
        .foregroundColor(vm.secondaryLabel)
        .overlay(
            Capsule()
                .stroke(vm.secondaryLabel, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    func buildAmountInput() -> some View {
        VStack(alignment: .center, spacing: 16) {
            textField()
                .padding(.top, 12)
            
            VStack(alignment: .center, spacing: 12) {
                buildBuySellValue()
                
                Text("Min. amount: \(vm.minAmount.trimmedString) \(vm.asset)")
                    .font(.caption)
                    .foregroundColor(vm.secondaryLabel)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(vm.layer2)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
    }
    
    @ViewBuilder
    func buildPaymentOptions() -> some View {
        VStack(spacing: 0) {
            ForEach(PayMethod.allCases, id: \.rawValue) { method in
                Button {
                    vm.mediumFeedback?.impactOccurred()
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
        .background(vm.layer2)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
    }
    
    @ViewBuilder
    func buildContinueButton() -> some View {
        if let buySellAmount = Double(vm.amount),
           buySellAmount > 0 && vm.resp.data != nil && buySellAmount >= vm.minAmount {
            NavigationLink {
                BuySellMerchant()
                    .environmentObject(vm)
            } label: {
                Text("Continue")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(vm.mainLabel)
                    .background(vm.main)
                    .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
            }
            .gesture(TapGesture().onEnded({ _ in
                vm.mediumFeedback?.impactOccurred()
            }))
        } else {
            Text("Continue")
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(vm.secondaryLabel)
                .background(vm.main.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
        }
    }
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                if vm.resp.data == nil {
                    buildLoading()
                } else {
                    buildHeader()
                    ScrollView {
                        buildAmountInput()
                        buildPaymentOptions()
                    }
                    
                    Spacer()
                    buildContinueButton()
                }
            }
            
            .onAppear {
                if vm.resp.data == nil {
                    vm.update()
                }
                
                if vm.mediumFeedback == nil {
                    vm.initHaptic()
                }
            }
            
            .padding()
            .navigationBarBackButtonHidden(true)
            
            .sheet(isPresented: $showCountry) {
                BuySellCurrency()
                    .environmentObject(vm)
            }
            
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}

struct BuySellMerchant: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: BuySellVM
    
    @State var showCountry: Bool = false
    @State var showAmount: Bool = false
    
    @ViewBuilder
    func buildHeader() -> some View {
        HeaderView {
            VStack {
                Text("Operator")
                    .font(.title3.bold())
                    .foregroundColor(vm.mainLabel)
                Text(vm.method)
                    .font(.body)
                    .foregroundColor(vm.secondaryLabel)
            }
        } left: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onTapGesture {
                    self.presentation.wrappedValue.dismiss()
                }
        } right: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        }
        .frame(height: 50)
    }
    
    @ViewBuilder
    func buildCountrySelection() -> some View {
        HStack {
            Text(vm.country)
                .font(.body.bold())
                .foregroundColor(vm.mainLabel)
            
            if let info = BuySellVM.countriesInfo[vm.country] {
                Text(info)
                    .font(.body)
                    .foregroundColor(vm.secondaryLabel)
            }
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .foregroundColor(vm.secondaryLabel)
        }
        
        .padding()
        .background(vm.layer2)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
        
        .contentShape(Rectangle())
        .onTapGesture {
            vm.mediumFeedback?.impactOccurred()
            vm.merchant = ""
            showCountry = true
        }
    }
    
    @ViewBuilder
    func buildProviderSelection(methods: [String], currency: String) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(methods.sorted(by: >)) { method in
                    HStack(alignment: .center, spacing: 16) {
                        if let merchant = vm.merchants.first(where: { $0.title?.uppercased() == method.uppercased() }),
                           let iconURL = URL(string: merchant.iconURL ?? "") {
                            Image(systemName: "questionmark.square.fill")
                                .data(url: iconURL)
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        } else {
                            Image(systemName: "questionmark.square.fill")
                                .resizable()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .foregroundColor(Color.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .center, spacing: 6) {
                                Text(method.capitalized)
                                    .font(.body.bold())
                                    .foregroundColor(vm.mainLabel)
                                
                                if method.lowercased() == "mercuryo" {
                                    Text("BEST")
                                        .padding(4)
                                        .font(.caption.bold())
                                        .foregroundColor(vm.tagTint)
                                        .background(vm.tagBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                }
                            }
                            
                            Text("? \(currency.uppercased()) for 1 \(vm.asset.uppercased())")
                                .font(.callout)
                                .foregroundColor(vm.secondaryLabel)
                        }
                        
                        Spacer()
                        
                        vm.merchant == method ?
//                                        Image("ic.radio.selected") : Image("ic.radio.unselect")
                            Text("x") : Text("")
                    }
                    
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.mediumFeedback?.impactOccurred()
                        vm.merchant = method
                    }
                    
                    Divider()
                        .padding(.leading, 16)
                }
            }
            .background(vm.layer2)
            .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
        }
    }
    
    @ViewBuilder
    func buildContinueButton() -> some View {
        NavigationLink {
            BuySellAmount()
                .environmentObject(vm)
        } label: {
            Text("Continue")
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(vm.mainLabel)
                .background(vm.main)
                .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
        }
        .gesture(TapGesture().onEnded({ _ in
            vm.mediumFeedback?.impactOccurred()
        }))
    }
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                buildHeader()
                buildCountrySelection()
                
                if let currency = vm.countries.first(where: { $0.countryCode == vm.country })?.currency,
                    let methods = vm.countries.first(where: { $0.countryCode == vm.country })?.methods, !methods.isEmpty {
                    buildProviderSelection(methods: methods, currency: currency)
                } else {
                    Spacer()
                    Text("we're working to supprt many country 😉")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(vm.mainLabel)
                }
                
                Spacer()
                
                if vm.resp.data != nil && !vm.merchant.isEmpty {
                    buildContinueButton()
                } else {
                    Text("Please select a merchant ☕️")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(vm.mainLabel)
                }
            }
            
            .padding([.top, .horizontal])
            .navigationBarBackButtonHidden(true)
            
            .sheet(isPresented: $showCountry) {
                BuySellCurrency()
                    .environmentObject(vm)
            }
        }
    }
}

struct BuySellCurrency: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: BuySellVM
    
    @ViewBuilder
    func buildHeader() -> some View {
        HeaderView {
            Text("Currency")
                .font(.title3.bold())
        } left: {
            Color.clear
                .frame(width: 32, height: 32)
        } right: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onTapGesture {
                    vm.mediumFeedback?.impactOccurred()
                    presentation.wrappedValue.dismiss()
                }
        }
        .frame(height: 50)
    }
    
    @ViewBuilder
    func buildCountryList() -> some View {
        VStack(spacing: 0) {
            ForEach(vm.countries) { country in
                if country.currency != "-" {
                    HStack(alignment: .center) {
                        Text((country.currency ?? "").uppercased())
                            .font(.body.bold())
                            .foregroundColor(vm.mainLabel)
                        
                        if let info = BuySellVM.countriesInfo[country.countryCode ?? ""] {
                            Text(info)
                                .font(.body)
                                .foregroundColor(vm.secondaryLabel)
                        }
                        
                        Spacer()

                        if vm.country == country.countryCode ?? "" {
//                                        Image("ic.currency.checkmark")
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 50)
                    
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.mediumFeedback?.impactOccurred()
                        vm.country = country.countryCode ?? ""
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                            presentation.wrappedValue.dismiss()
                        })
                    }
                }
            }
        }
        .background(vm.layer2)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            buildHeader()
            
            if !vm.countries.isEmpty {
                ScrollView {
                    buildCountryList()
                }
            } else {
                Spacer()
            }
        }
        .padding()
    }
}

enum TransactionStatus: Int, CaseIterable {
    case initialize = 0
    case processing
    case success
    case failed
    
    func getName() -> String {
        switch self {
        case .initialize: return "buysell.status.continue"
        case .processing: return "buysell.status.processing"
        case .success: return "buysell.status.success"
        case .failed: return "buysell.status.failed"
        }
    }
    
    @ViewBuilder
    func getView() -> some View {
        if case .processing = self {
            HStack(alignment: .center, spacing: 5) {
                Text("Processing")
                    .font(.body.bold())
                ProgressView()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
        }
        
        if case .success = self {
            Text("Success")
                .font(.body.bold())
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
        }
        
        if case .failed = self {
            Text("Failed")
                .font(.body.bold())
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    func getColor() -> Color {
        switch self {
        case .initialize: return .blue
        case .processing: return .secondary
        case .success: return .green
        case .failed: return .red
        }
    }
}

struct BuySellAmount: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: BuySellVM
    
    @State var isFocus: Bool = false
    @State var getAmount: Double = 0
    @State var status: TransactionStatus = .initialize
    
    @ViewBuilder
    func buildHeader() -> some View {
        HeaderView {
            EmptyView()
        } left: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onTapGesture {
                    vm.mediumFeedback?.impactOccurred()
                    presentation.wrappedValue.dismiss()
                }
        } right: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        }
        .frame(height: 50)
    }
    
    @ViewBuilder
    func buildMerchantPreview() -> some View {
        if let merchant = vm.merchants.first(where: { $0.title?.uppercased() == vm.merchant.uppercased() }) {
            VStack(alignment: .center, spacing: 16) {
                Image(systemName: "")
                    .data(url: URL(string: merchant.iconURL!)!)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                Text(merchant.title?.capitalized ?? "-")
                    .font(.title2.bold())
                    .foregroundColor(vm.mainLabel)
                
                Text(merchant.subtitle?.capitalized ?? "-")
                    .font(.body)
                    .foregroundColor(vm.secondaryLabel)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(alignment: .center, spacing: 16) {
                Image(systemName: "questionmark.square.fill")
                    .resizable()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                Text("Please select a merchant")
                    .font(.body.bold())
                    .foregroundColor(vm.mainLabel)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    func buildBuySellPreview() -> some View {
        VStack(alignment: .leading, spacing: 16) {
//            if let currency = vm.countries.first(where: { $0.countryCode?.uppercased() == vm.country.uppercased() })?.currency?.uppercased() {
//                VStack(alignment: .leading, spacing: 6) {
//                    Text("You pay" )
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .foregroundColor(Color(UIColor.secondaryLabel))
//                    
//                    textField(isFocus: $isFocus, asset: currency)
//                }
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(
//                    RoundedRectangle(cornerRadius: 10, style: .continuous)
//                        .fill(Color(UIColor.secondarySystemBackground))
//                )
//                .overlay(
//                    RoundedRectangle(cornerRadius: 10, style: .continuous)
//                        .stroke(isFocus ? Color.blue : Color.clear, lineWidth: 2)
//                )
//            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("You pay")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(vm.secondaryLabel)
                
                textField(isFocus: $isFocus, asset: vm.currency)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous)
                    .fill(vm.layer2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isFocus ? Color.blue : Color.clear, lineWidth: 2)
            )
            
            VStack(alignment: .leading, spacing: 6) {
                Text("You get")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(vm.secondaryLabel)
                
                HStack(alignment: .center, spacing: 4) {
                    Text("0.000")
                        .foregroundColor(vm.mainLabel)
                    Text("TON")
                        .foregroundColor(vm.secondaryLabel)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous)
                    .fill(vm.layer2)
            )
            
            Text("2,3301.01 AMD for 1 TON")
                .padding(.leading, 12)
                .foregroundColor(vm.secondaryLabel)
        }
    }
    
    @ViewBuilder
    func buildStatusButton() -> some View {
        if case .initialize = status {
            Text("Continue")
                .font(.body.bold())
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .onTapGesture {
                    vm.mediumFeedback?.impactOccurred()
                    status = .processing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                        status = [.success, .failed].randomElement()!
                    })
                }
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            status.getView()
                .background(status.getColor())
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                buildHeader()
                buildMerchantPreview()
                buildBuySellPreview()
                
                Spacer()
            }
            .padding([.top, .horizontal])
            .navigationBarBackButtonHidden(true)
            
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            
            VStack {
                Spacer()
                buildStatusButton()
            }
            .padding()
        }
    }
    
    @ViewBuilder
    func textField(isFocus: Binding<Bool>, asset: String) -> some View {
        HStack(alignment: .center, spacing: 4) {
            TextField("", text: $vm.amount, onEditingChanged: { edit in
                isFocus.wrappedValue = edit
            })
            .foregroundColor(vm.mainLabel)
            .keyboardType(.decimalPad)
            .fixedSize(horizontal: true, vertical: false)
            .multilineTextAlignment(.center)
            
            Text(asset.uppercased())
                .foregroundColor(vm.secondaryLabel)
        }
    }
}

#Preview {
    NavigationView {
//        BuySell()
        
        BuySellAmount()
            .environmentObject(BuySellVM())
        
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
        textField.font = UIFont.systemFont(ofSize: DynamicFontSizeTextField.dynamicSize(text), weight: .bold)
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

import SwiftUI
import UIKit

extension Image {
    static var imageCache = NSCache<NSURL, UIImage>()
    
    func data(url: URL) -> Self {
        if let cachedImage = Image.imageCache.object(forKey: url as NSURL) {
            return Image(uiImage: cachedImage).resizable()
        }
        
        var downloadedImage: UIImage?
        do {
            let data = try Data(contentsOf: url)
            downloadedImage = UIImage(data: data)
            if let image = downloadedImage {
                Image.imageCache.setObject(image, forKey: url as NSURL)
                return Image(uiImage: image).resizable()
            }
        } catch {
            print("Error loading image from URL: \(error)")
        }
        
        return self.resizable()
    }
}
