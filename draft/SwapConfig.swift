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

enum SwapStatus {
    case enterAmount
    case chooseToken
    case loading
    case ready
    case failure
    case success
}

@MainActor final
class SwapVM: ObservableObject {
    @Published var status: SwapStatus = .enterAmount
    
    @Published var wallet: [String: Asset] = [
        "TON": Asset(name: "Toncoin", code: "TON", balance: 999),
        "USDT": Asset(name: "Tether USD", code: "USD₮", balance: 333)
    ]
    
    @Published var sendToken: String = ""
    @Published var sendAmount: Double = 0
    @Published var receiveToken: String = ""
    @Published var receiveAmount: Double = 0
    
    @Published var detail = SwapDetail()
    @Published var swapRate = ""
    
    @Published var tokenQuery: String = ""
    @Published var suggestedTokens: [String] = [
        "usdt",
        "anon",
        "not",
        "btc",
        "grc",
        
        "1usdt",
//        "1anon",
//        "1not",
//        "1btc",
//        "1grc",
    ]
    
    @Published var otherTokens: [String] = [
        "ton",
        "usdt",
        "glint",
        "utya",
        "poveldurev"
    ]
    
    @Published var slippage: Double = 1
    @Published var predefinedSlippage: [Double] = [1,3,5]
    @Published var isExpert = false
    
    @Published var temp: String = ""
    
    let main: Color = Color.blue
    let layer1: Color = Color(UIColor.secondarySystemBackground)
    let layer2: Color = Color(UIColor.secondarySystemFill)
    let layer3: Color = Color(UIColor.secondaryLabel)
    let mainLabel: Color = Color.primary
    let secondaryLabel: Color = Color.secondary
    let cornerRadius: CGFloat = 14
    
    func updateState() {
        let dontHaveSendAmount = sendAmount == 0
        let dontHaveReceiveToken = receiveToken.isEmpty
        let dontHaveReceiveAmount = receiveAmount == 0
        let dontHaveProvider = detail.provider == nil
        
        if dontHaveSendAmount {
            status = .enterAmount
            return
        }
        
        if dontHaveReceiveToken {
            status = .chooseToken
            return
        }
        
        if dontHaveProvider || dontHaveProvider {
            status = .loading
            
            // mock loading detail
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                withAnimation {
                    self.swapRate = "1 \(self.sendToken) ~= ? \(self.receiveToken)"
                    self.detail = SwapDetail.defaultInstance
                    self.status = .ready
                }
            })
            
            return
        }
        
        if !dontHaveSendAmount &&
            !dontHaveReceiveToken &&
            !dontHaveReceiveAmount &&
            !dontHaveProvider {
            status = .ready
            return
        }
    }
}

struct SwapConfig: View {
    @StateObject var vm = SwapVM()
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    @ViewBuilder
    func buildHeader() -> some View {
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
    }
    
    @ViewBuilder
    func buildFromAssetView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text("Send")
                    .font(.callout)
                    .foregroundColor(vm.secondaryLabel)
                Spacer()
                
                if let asset = vm.wallet[vm.sendToken] {
                    Text("Balance: \(String(asset.balance)) \(asset.code)")
                        .font(.callout)
                        .foregroundColor(vm.secondaryLabel)
                    Text("MAX")
                        .font(.body.bold())
                        .onTapGesture {
                            vm.sendAmount = asset.balance
                        }
                }
            }
            
            HStack(alignment: .center) {
                buildTokenButton(asset: $vm.sendToken)
                Spacer()
                TextField("0", text: $vm.temp)
                    .fixedSize(horizontal: true, vertical: false)
                    .font(.title.bold())
                    .limitLength($vm.temp, to: 9)
                    .onReceive(vm.$temp) {
                        vm.sendAmount = Double("\($0)".prefix(9)) ?? 0
                        print(vm.sendAmount)
                        vm.updateState()
                    }
                    .keyboardType(.decimalPad)
            }
        }
        .padding(.horizontal)
        .frame(height: 100)
        .background(vm.layer2)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
    }
    
    @ViewBuilder
    func buildToAssetView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text("Receive")
                    .font(.callout)
                    .foregroundColor(vm.secondaryLabel)
                Spacer()
            }
            
            HStack(alignment: .center) {
                buildTokenButton(asset: $vm.receiveToken)
                Spacer()
                Text(String(vm.receiveAmount))
                    .font(.title.bold())
                    .foregroundColor(vm.mainLabel)
            }
            
            if !vm.swapRate.isEmpty {
                Divider()
                HStack(alignment: .center) {
                    Text(vm.swapRate)
                    Spacer()
                    ProgressView()
                }
                .font(.callout)
                .foregroundColor(vm.secondaryLabel)
                Divider()
            }
            
            vm.detail.buildView()
        }
        .padding()
        .background(vm.layer2)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
    }
    
    @ViewBuilder
    func buildSwapIcon() -> some View {
        HStack(alignment: .center) {
            Spacer()
            VStack {
                Spacer()
                    .frame(height: 86)
                
                Image(systemName: "arrow.up.arrow.down")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(vm.mainLabel)
                    .padding(10)
                    .background(vm.layer3)
                    .clipShape(Circle())
                    .padding(.trailing, 40)
            }
        }
    }
    
    @ViewBuilder
    func buildSwapButton() -> some View {
        Group {
            if case .enterAmount = vm.status {
                Text("Enter amount")
            }
            
            if case .chooseToken = vm.status {
                Text("Choose token")
            }
            
            if case .loading = vm.status {
                ProgressView()
            }
            
            if case .ready = vm.status {
                NavigationLink {
                    SwapConfirm()
                        .environmentObject(vm)
                } label: {
                    Text("Continue")
                }

            }
        }
        .font(.body.bold())
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(vm.layer2)
        .foregroundColor(vm.mainLabel)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
    }
    
    @ViewBuilder
    func buildTokenButton(asset: Binding<String>) -> some View {
        NavigationLink {
            SwapToken(asset: asset)
                .environmentObject(vm)
        } label: {
            if asset.wrappedValue.isEmpty {
                Text("Choose".uppercased())
                    .font(.body.bold())
                    .foregroundColor(vm.mainLabel)
                    .padding(6)
                    .background(vm.layer3)
                    .clipShape(Capsule())
            } else {
                HStack(alignment: .center, spacing: 4) {
                    Color.primary.frame(width: 24, height: 24)
                        .clipShape(Capsule())
                    Text(asset.wrappedValue.uppercased())
                        .font(.body.bold())
                        .foregroundColor(vm.mainLabel)
                }
                .padding(6)
                .background(vm.layer3)
                .clipShape(Capsule())
            }
        }
    }
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                buildHeader()
                
                ZStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {
                        buildFromAssetView()
//                            .onAppear {
//                                vm.sendToken = vm.wallet.keys.first!
//                            }
                        buildToAssetView()
                    }
                    buildSwapIcon()
                }
                
                buildSwapButton()
                
                Spacer()
            }
            .navigationBarBackButtonHidden(true)
            
            .background(vm.layer1)
            .padding()
            
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}

struct SwapToken: View {
    @Environment(\.presentationMode) var presentation
    
    @EnvironmentObject var vm: SwapVM
    @Binding var asset: String
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                HeaderView {
                    Text("Choose Token")
                        .font(.title.bold())
                } right: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .padding(8)
                        .onTapGesture {
                            presentation.wrappedValue.dismiss()
                        }
                }

                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .frame(width: 16, height: 16)
                    TextField("Search", text: $vm.tokenQuery)
                }
                .frame(height: 48)
                .padding(.horizontal, 12)
                .padding(.vertical, 0)
                .background(vm.layer2)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                // Suggested tokens
                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested")
                        .font(.title3.bold())
                    
                    FlowLayout(vm.suggestedTokens, spacing: 4) { tag in
                        HStack(alignment: .center, spacing: 4) {
                            vm.layer3
                                .frame(width: 28, height: 28, alignment: .center)
                                .clipShape(Circle())
                            Text(tag)
                        }
                        .foregroundColor(vm.mainLabel)
                        .padding(6)
                        .background(vm.layer2)
                        .clipShape(Capsule(style: .continuous))
                        .onTapGesture {
                            asset = tag.uppercased()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                                presentation.wrappedValue.dismiss()
                            })
                        }
                    }
                }
                .border(.red, width: 1)
                
                // Other tokens
                VStack(alignment: .leading, spacing: 10) {
                    Text("Other")
                        .font(.title3.bold())
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(vm.otherTokens) { token in
                                Button {} label: {
                                    HStack(alignment: .center, spacing: 16) {
                                        vm.layer2.frame(width: 44, height: 44, alignment: .center)
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .center, spacing: 2) {
                                            HStack(alignment: .center) {
                                                Text(token)
                                                Spacer()
                                                Text("100000")
                                            }
                                            .font(.body.bold())
                                            .foregroundColor(vm.mainLabel)
                                            
                                            HStack(alignment: .center) {
                                                Text("toncoin")
                                                Spacer()
                                                Text("$600")
                                            }
                                            .font(.callout)
                                            .foregroundColor(vm.secondaryLabel)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(height: 76)
                                
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                        .background(vm.layer2)
                        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                    }
                }
                
//                Spacer()
                
                Text("Close")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.layer2)
                    .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
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

struct SwapConfirm: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: SwapVM
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                HeaderView {
                    Text("Confirm Swap")
                        .font(.title.bold())
                } right: {
                    Image(systemName: "xmark")
                        .frame(width: 16, height: 16)
                        .padding(8)
                        .background(vm.layer2)
                        .clipShape(Circle())
                        .onTapGesture {
                            presentation.wrappedValue.dismiss()
                        }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center) {
                            Text("Send")
                            Spacer()
                            Text("$6000.01")
                        }
                        .font(.callout)
                        .foregroundColor(vm.secondaryLabel)
                        
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
                            Spacer()
                            Text("$600010,10")
                        }
                        .font(.callout)
                        .foregroundColor(vm.secondaryLabel)
                        
                        HStack(alignment: .center) {
                            Button {} label: {
                                HStack(alignment: .center, spacing: 4) {
                                    Color.primary.frame(width: 24, height: 24)
                                        .clipShape(Capsule())
                                    Text("USD₮")
                                        .font(.body.bold())
                                        .foregroundColor(vm.mainLabel)
                                }
                                .padding(6)
                                .background(vm.layer3)
                                .clipShape(Capsule())
                            }
                            .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("6000")
                                .font(.title.bold())
                                .foregroundColor(vm.mainLabel)
                        }
                        
                        Divider()
                        
                        vm.detail.buildView()
                    }
                    .padding()
                    .background(vm.layer2)
                    .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                }

                Spacer()
                
                HStack(alignment: .center, spacing: 16) {
                    Text("Cancel")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vm.layer2)
                        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                    
                    Text("Confirm")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vm.main)
                        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                }
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

import CoreHaptics

struct SwapSlippage: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: SwapVM
    
    @State var temp: String = ""
    
    @State private var lightFeedback: UIImpactFeedbackGenerator?
    @State private var mediumFeedback: UIImpactFeedbackGenerator?
    @State private var heavyFeedback: UIImpactFeedbackGenerator?
    @State private var rigidFeedback: UIImpactFeedbackGenerator?
    @State private var softFeedback: UIImpactFeedbackGenerator?
    
    @ViewBuilder
    func textField(amount: Binding<Double>, isFocus: Binding<Bool>, asset: String) -> some View {
        let text = Binding<String>(
            get: {
                amount.wrappedValue > 0 ?
                    String(format: "%.2f", amount.wrappedValue) : "0"
            },
            set: { text in
                vm.slippage = Double(text) ?? 0
            }
        )
        
        HStack(alignment: .center, spacing: 4) {
            TextField("", text: text, onEditingChanged: { edit in
                isFocus.wrappedValue = edit
            })
            .keyboardType(.decimalPad)
            .fixedSize(horizontal: true, vertical: false)
            .font(.callout)
            .multilineTextAlignment(.center)
            
            Button {} label: {
                Text(asset.uppercased())
                    .font(.callout)
                    .font(.system(size: 20, weight: .regular, design: .default))
            }
            .foregroundColor(vm.secondaryLabel)
            
            Spacer()
        }
    }
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                HeaderView {
                    Text("Settings")
                        .font(.title.bold())
                } right: {
                    Image(systemName: "xmark")
                        .frame(width: 16, height: 16)
                        .padding(8)
                        .background(vm.layer2)
                        .clipShape(Circle())
                        .onTapGesture {
                            presentation.wrappedValue.dismiss()
                        }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Slippage")
                        .font(.headline.bold())
                    Text(LocalizedStringKey("The amount the price can change \nunfavorably before the trade reverts"))
                        .font(.callout)
                        .foregroundColor(vm.secondaryLabel)
                }
                
                if vm.isExpert {
                    textField(amount: $vm.slippage, isFocus: .constant(false), asset: "%")
                        .padding()
                        .background(vm.layer2)
                        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                } else {
                    HStack(alignment: .center, spacing: 4) {
                        Text("Custom %")
                        Spacer()
                    }
                    .padding()
                    .foregroundColor(vm.secondaryLabel)
                    .background(vm.layer2)
                    .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                    .keyboardType(.decimalPad)
                }
                
                HStack(alignment: .center, spacing: 16) {
                    ForEach(vm.predefinedSlippage, id: \.description) { slippage in
                        Text(String(format: "%.0f%%", slippage))
                            .font(.callout.bold())
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(vm.layer2)
                            .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                            .onTapGesture {
                                vm.slippage = slippage
                                mediumFeedback?.impactOccurred()
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous)
                                    .stroke(vm.main, lineWidth: vm.slippage == slippage ? 2 : 0)
                            )
                    }
                }
                
                Toggle(isOn: $vm.isExpert) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Expert Mode")
                            .font(.headline.bold())
                            .foregroundColor(vm.mainLabel)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Allows high price impact trades.")
                            Text("Use at your own risk.")
                        }
                        .font(.callout)
                        .foregroundColor(vm.secondaryLabel)
                    }
                }
                .padding()
                .background(vm.layer2)
                .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                .onChange(of: vm.isExpert) { value in
                    if !vm.isExpert {
                        vm.slippage = vm.predefinedSlippage.first!
                    }
                }
                
                Spacer()
            }
            .navigationBarBackButtonHidden(true)
            
            .background(vm.layer1)
            .padding()
            
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            
            VStack {
                Spacer()
                Text("Save")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.main)
                    .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
            }
            .padding()
        }
        .onAppear {
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
    }
}

#Preview {
    NavigationView {
        SwapConfig()
        
//        SwapToken()
//        SwapConfirm()
//        SwapSlippage()
//            .environmentObject(SwapVM())
    }
}


import SwiftUI

struct FlowLayout<Data, RowContent>: View where Data: RandomAccessCollection, RowContent: View, Data.Element: Identifiable, Data.Element: Hashable {
    @State private var height: CGFloat = .zero
    
    private var data: Data
    private var spacing: CGFloat
    private var rowContent: (Data.Element) -> RowContent
    
    public init(_ data: Data, spacing: CGFloat = 4, @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent) {
        self.data = data
        self.spacing = spacing
        self.rowContent = rowContent
    }
    
    var body: some View {
        GeometryReader { geometry in
            content(in: geometry)
                .background(viewHeight(for: $height))
        }
        .frame(height: height)
    }
    
    private func content(in geometry: GeometryProxy) -> some View {
        var bounds = CGSize.zero
        
        return ZStack {
            ForEach(data) { item in
                rowContent(item)
                    .padding(.all, spacing)
                    .alignmentGuide(VerticalAlignment.center) { dimension in
                        let result = bounds.height
                        
                        if let firstItem = data.first, item == firstItem {
                            bounds.height = 0
                        }
                        return result
                    }
                    .alignmentGuide(HorizontalAlignment.center) { dimension in
                        if abs(bounds.width - dimension.width) > geometry.size.width {
                            bounds.width = 0
                            bounds.height -= dimension.height
                        }
                        
                        let result = bounds.width
                        
                        if let firstItem = data.first, item == firstItem {
                            bounds.width = 0
                        } else {
                            bounds.width -= dimension.width
                        }
                        return result
                    }
            }
        }
    }
    
    private func viewHeight(for binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}

struct SwapDetail {
    
    var priceImpact: Double?
    var minimumReceived: Double?
    var liquidityProviderFee: Double?
    var blockchainFee: String?
    var route: String?
    var provider: String?
    
    var fromAsset: String?
    var toAsset: String?
    
    var mainLabel: Color = Color.primary
    var secondaryLabel: Color = Color.secondary
    
    static var defaultInstance: SwapDetail = .init(
        priceImpact: 0.001,
        minimumReceived: 6000.01,
        liquidityProviderFee: 0.00000000001,
        blockchainFee: "0.11 - 0.17 TON",
        route: "TON >> USDT",
        provider: "STON.fi",
        fromAsset: "TON",
        toAsset: "USDT",
        mainLabel: Color.primary,
        secondaryLabel: Color.secondary
    )
    
    @ViewBuilder
    func buildDetailRow(title: String, content: String, didTapInfo: (()->Void)? = nil) -> some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 2) {
                Text(title)
                if let didTapInfo {
                    Image(systemName: "info.circle.fill")
                }
            }
            .foregroundColor(secondaryLabel)
            .onTapGesture { // for user to tap on the whole text, not just info icon
                didTapInfo?()
            }
            
            Spacer()
            Text(content)
                .foregroundColor(mainLabel)
        }
    }
    
    @ViewBuilder
    func buildView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let priceImpact {
                buildDetailRow(title: "priceImpact", content: String(priceImpact) + "%") {
                    print("here is your code")
                }
            }
            if let minimumReceived {
                buildDetailRow(title: "minimumReceived", content: String(minimumReceived))
            }
            if let liquidityProviderFee {
                buildDetailRow(title: "liquidityProviderFee", content: String(liquidityProviderFee))
            }
            if let blockchainFee {
                buildDetailRow(title: "blockchainFee", content: String(blockchainFee))
            }
            if let route {
                buildDetailRow(title: "route", content: String(route))
            }
            if let provider {
                buildDetailRow(title: "provider", content: String(provider))
            }
        }
        .font(.callout.bold())
    }
}


struct LimitLengthModifier: ViewModifier {
    @Binding var text: String
    var length: Int

    func body(content: Content) -> some View {
        content
            .onReceive(text.publisher.collect()) {
                if $0.count > length {
                    text = String($0.prefix(length))
                }
            }
    }
}

extension View {
    func limitLength(_ text: Binding<String>, to length: Int) -> some View {
        self.modifier(LimitLengthModifier(text: text, length: length))
    }
}
