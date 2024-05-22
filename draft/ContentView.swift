//
//  ContentView.swift
//  draft
//
//  Created by davidtam on 20/5/24.
//

import SwiftUI

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

typealias FiatMethodHandler = (Result<FiatMethodResponse, HTTPError>) -> Void

@MainActor final
class BuySellVM: ObservableObject {
    @Published var resp: FiatMethodResponse = .init(success: nil, data: nil)
    @Published var error: String = ""
    
    @Published var countries: [CountryLayout] = []
    @Published var assets: [String] = []
    @Published var asset: String = "TON"
    @Published var merchants: [Merchant] = []
    
    // params
    @Published var isBuy: Bool = true
    @Published var amount: Double = 0
    @Published var country: String = "us"
    @Published var method: String = PayMethod.creditCardVisaMaster.rawValue
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

extension View {
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}

struct BuySellConfig: View {
    @StateObject var vm: BuySellVM = BuySellVM()
    
    @State private var temp = "0"
    @State var showCountry = false
    
    @ViewBuilder
    func textField() -> some View {
        HStack(alignment: .center, spacing: 4) {
            DynamicFontSizeTextField(text: $temp, maxLength: 15)
                .fixedSize(horizontal: true, vertical: false)
                .keyboardType(.decimalPad)
                .foregroundColor(Color.white)
                .multilineTextAlignment(.center)

            Button {} label: {
                Text(vm.asset)
                    .font(.system(size: DynamicFontSizeTextField.dynamicSize(temp), weight: .bold, design: .default))
            }
            .foregroundColor(Color.gray.opacity(0.8))
            
//            Picker("Token?", selection: $vm.asset) {
//                ForEach(vm.assets, id: \.self) { key in
//                    Text(key).tag(key)
//                }
//            }
//            .pickerStyle(.menu)
//            .border(.red, width: 1)
        }
    }
    
    var body: some View {
        VStack {
            HeaderView {
                HStack(alignment: .center, spacing: 8) {
                    Button {
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
            } left: {
                Button {
                    showCountry = true
                } label: {
                    Text(vm.country)
                        .font(.callout.bold())
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .foregroundColor(Color.primary)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(Capsule())
                
//                Text("FR")
//                    .padding(8)
//                    .font(.body.bold())
//                    .background(Color(UIColor.secondarySystemBackground))
//                    .clipShape(Capsule())
//                    .onTapGesture {
//                        showCountry = true
//                    }
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
                
                VStack(alignment: .center, spacing: 14) {
                    textField()
                    
                    VStack(alignment: .center, spacing: 12) {
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
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(height: 160)
                
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
                vm.merchant = ""
                showCountry = true
            } label: {
                HStack {
                    Text(vm.country)
                    if let info = BuySellVM.countriesInfo[vm.country] {
                        Text(info)
                            .font(.body)
                            .foregroundColor(Color.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                }
            }
            .buttonStyle(BigButtonStyle(backgroundColor: .secondary.opacity(0.4), textColor: .white))
            
            if let currency = vm.countries.first(where: { $0.countryCode == vm.country })?.currency,
                let methods = vm.countries.first(where: { $0.countryCode == vm.country })?.methods,
//               let
                !methods.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(methods) { method in
                            Button {
                                vm.merchant = method
                            } label: {
                                HStack {
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
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(method.capitalized)
                                        Text("? \(currency.uppercased()) for 1 \(vm.asset.uppercased())")
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
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: BuySellVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderView {
                Text("Currency")
            } left: {
                Text("")
            } right: {
                Button {
                    presentation.wrappedValue.dismiss()
                } label: {
//                    Image(systemName: "xmark")
                    Text("x")
                }
            }
            .frame(height: 50)
            
            if !vm.countries.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(vm.countries) { country in
                            if country.currency != "-" {
                                Button {
                                    vm.country = country.countryCode ?? ""
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                                        presentation.wrappedValue.dismiss()
                                    })
                                } label: {
                                    HStack(alignment: .center) {
                                        Text((country.currency ?? "").uppercased())
                                            .font(.body.bold())
                                        
                                        if let info = BuySellVM.countriesInfo[country.countryCode ?? ""] {
                                            Text(info)
                                                .font(.body)
                                                .foregroundColor(Color.secondary)
                                        }
                                        
                                        Spacer()
        
                                        if vm.country == country.countryCode ?? "" {
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
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HeaderView {
                EmptyView()
            } left: {
                Button {
                    presentation.wrappedValue.dismiss()
                } label: {
                    Text("b")
                }
            } right: {
                Button {} label: {
                    Text("x")
                }
            }
            .frame(height: 50)
            
            if let merchant = vm.merchants.first(where: { $0.title?.uppercased() == vm.merchant.uppercased() }) {
                VStack(alignment: .center, spacing: 16) {
                    Image(systemName: "")
                        .data(url: URL(string: merchant.iconURL!)!)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text(merchant.title?.capitalized ?? "-")
                    Text(merchant.subtitle?.capitalized ?? "-")
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .center, spacing: 16) {
                    Image(systemName: "questionmark.square.fill")
                        .resizable()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    
                    Text("Please select a merchant")
                }
                .frame(maxWidth: .infinity)
            }
            
            if vm.isBuy {
                VStack(alignment: .leading, spacing: 16) {
                    if let currency = vm.countries.first(where: { $0.countryCode?.uppercased() == vm.country.uppercased() })?.currency?.uppercased() {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("You pay")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            
                            textField(amount: $vm.amount, isFocus: $isFocus, asset: currency)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isFocus ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("You get")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        
                        textField(amount: $getAmount, isFocus: .constant(false), asset: vm.asset)
                            .disabled(true)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isFocus ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("You sell")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        
                        textField(amount: $getAmount, isFocus: $isFocus, asset: vm.asset)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isFocus ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    
                    if let currency = vm.countries.first(where: { $0.countryCode?.uppercased() == vm.country.uppercased() })?.currency?.uppercased() {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("You get")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            
                            textField(amount: $vm.amount, isFocus: .constant(false), asset: currency)
                                .disabled(true)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isFocus ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            
            Spacer()
            
            if case .initialize = status {
                Text("Continue")
                    .font(.body.bold())
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .onTapGesture {
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
        .padding([.top, .horizontal])
        .navigationBarBackButtonHidden(true)
        
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    @ViewBuilder
    func textField(amount: Binding<Double>, isFocus: Binding<Bool>, asset: String) -> some View {
        let text = Binding<String>(
            get: {
                amount.wrappedValue > 0 ?
                    String(format: "%.2f", amount.wrappedValue) : "0"
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
                Text(asset.uppercased())
                    .font(.system(size: 20, weight: .regular, design: .default))
            }
            .foregroundColor(Color(UIColor.secondaryLabel))
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
        
//        BuySellConfig()
        
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
