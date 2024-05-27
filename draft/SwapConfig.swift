//
//  SwapConfig.swift
//  draft
//
//  Created by davidtam on 20/5/24.
//

import SwiftUI
import Combine

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

typealias SwapMethodHandler = (Result<RPCResponse<SwapMethod>, HTTPError>) -> Void
typealias SwapSimulateHandler = (Result<RPCResponse<SwapSimulate>, HTTPError>) -> Void

final
class SwapVM: ObservableObject {
    var didTapDismiss: EmptyHandler?
    
    // api
    @Published var methods: SwapMethod?
    @Published var simutale: SwapSimulate?
    
    @Published var swapableAsset: [SwapAsset] = []
    var suggestedTokens: [String] = [
        "ton",
        "not",
    ]
    
    @Published var status: SwapStatus = .enterAmount
    
    @Published var wallet: [String: Asset] = [
        "TON": Asset(name: "Toncoin", code: "TON", balance: 999),
        "USDT": Asset(name: "Tether USD", code: "USD₮", balance: 333)
    ]
    
    // input
    var shouldCommitChange: Bool = false
    @Published var offerToken: String = ""
    @Published var offerAmount: String = ""
    @Published var askToken: String = ""
    
    // computed
    @Published var receiveAmount: Double = 0
    @Published var swapRate: String?
    
    // searching
    @Published var isSearching: Bool = false // smooth transition
    @Published var searchQuery: String = ""
    @Published var searchResult: [SwapAsset] = []
    
    // setting
    @Published var slippage: Double = 1
    @Published var predefinedSlippage: [Double] = [1,3,5]
    @Published var isExpert = false
    
    var cancellables = Set<AnyCancellable>()
    
    init(didTapDismiss: EmptyHandler? = nil) {
        self.didTapDismiss = didTapDismiss
     
        Publishers.CombineLatest4($offerToken, $offerAmount, $askToken, $slippage)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateState()
            }
            .store(in: &cancellables)
        
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.performSearch()
            }
            .store(in: &cancellables)
    }
    
    let main: Color = Color.blue
    let layer1: Color = Color(UIColor.secondarySystemBackground)
    let layer2: Color = Color(UIColor.secondarySystemFill)
    let layer3: Color = Color(UIColor.secondaryLabel)
    let mainLabel: Color = Color.primary
    let secondaryLabel: Color = Color.secondary
    let cornerRadius: CGFloat = 14
    
    // haptic
    var lightFeedback: UIImpactFeedbackGenerator?
    var mediumFeedback: UIImpactFeedbackGenerator?
    var heavyFeedback: UIImpactFeedbackGenerator?
    var rigidFeedback: UIImpactFeedbackGenerator?
    var softFeedback: UIImpactFeedbackGenerator?
    
    func update(completion: SwapMethodHandler? = nil) {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "asset.list",
            "params": {
                "load_community": false
            }
        }
        """

        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Failed to convert JSON string to Data")
            completion?(.failure(.invalidData))
            return
        }
        
        Network(apiFetcher: APIFetcher()).getSwapMethods(body: jsonData) { result in
            completion?(result)
        }
    }
    
    func simulateSwap(
        offerAddress: String, askAddress: String,
        offerUnits: String, slippage: String,
        completion: SwapSimulateHandler? = nil
    ) {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "id": 4,
            "method": "dex.simulate_swap",
            "params": {
                "offer_address": "\(offerAddress)",
                "offer_units": "\(offerUnits)",
                "ask_address": "\(askAddress)",
                "slippage_tolerance": "\(slippage)",
                "referral_address": "EQBsju9UnwA_T0IdAJrt5Qfj91NWZ7Y56Y_Qm1XI_A4jyzHr"
            }
        }
        """
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Failed to convert JSON string to Data")
            completion?(.failure(.invalidData))
            return
        }
        
        print(jsonString as NSObject)
        
        Network(apiFetcher: APIFetcher()).getSwapSimulate(body: jsonData) { result in
            completion?(result)
        }
    }
    
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
    
    func updateState() {
        guard shouldCommitChange else { return }
        
        // reset
        self.swapRate = nil
        self.simutale = nil
        
        let dontHaveOfferToken = offerToken.isEmpty
        let dontHaveOfferAmount = offerAmount.isEmpty
        let dontHaveAskToken = askToken.isEmpty
        let dontHaveAskAmount = receiveAmount == 0
        let dontHaveSimulate = simutale == nil
        
        if dontHaveOfferAmount {
            status = .enterAmount
            return
        }
        
        if dontHaveOfferToken || dontHaveAskToken {
            status = .chooseToken
            return
        }
        
        if dontHaveSimulate {
            status = .loading
            
//            // mock loading detail
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
//                self.swapRate = "1 \(self.sendToken) ~= ? \(self.receiveToken)"
//                self.detail = SwapDetail.defaultInstance
//                self.status = .ready
//            })
            
            simulateSwap(
                offerAddress: self.swapableAsset.first(where: { $0.symbol?.uppercased() == self.offerToken.uppercased() })?.contractAddress ?? "",
                askAddress: self.swapableAsset.first(where: { $0.symbol?.uppercased() == self.askToken.uppercased() })?.contractAddress ?? "",
                offerUnits: "\(Int((Double(self.offerAmount) ?? 0) * 1_000_000_000))",
                slippage: "\(slippage)"
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        if let simulate = data.result {
                            self.simutale = simulate
                        }
                        
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    
                    self.status = .ready
                }
            }
            
            return
        }
        
        if !dontHaveOfferAmount &&
            !dontHaveAskToken &&
            !dontHaveAskAmount &&
            !dontHaveSimulate {
            status = .ready
            return
        }
    }
    
    func performSearch() {
        withAnimation {
            self.isSearching = !self.searchQuery.isEmpty
        }
        
        self.searchResult = self.swapableAsset.filter({ item in
            (item.symbol?.lowercased() ?? "").contains(self.searchQuery.lowercased()) ||
            (item.displayName?.lowercased() ?? "").contains(self.searchQuery.lowercased())
        })
    }
}

struct Swap: View {
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
            NavigationLink {
                SwapSlippage()
                    .environmentObject(vm)
            } label: {
                vm.layer2
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            }
        } right: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onTapGesture {
                    vm.didTapDismiss?()
                }
        }
        .frame(height: 50)
    }
    
    @ViewBuilder
    func buildTokenIcon(width: CGFloat, urlString: String?) -> some View {
        if let url = URL(string: urlString ?? "") {
            KFImage(url)
                .placeholder({
                    Image(systemName: "questionmark.circle.fill")
                        .resizable()
                        .frame(width: width, height: width, alignment: .center)
                        .clipShape(Circle())
                })
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: width, alignment: .center)
                .clipShape(Circle())
        } else {
            Image(systemName: "questionmark.circle.fill")
                .resizable()
                .frame(width: width, height: width, alignment: .center)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    func buildFromAssetView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text("Send")
                    .font(.callout)
                    .foregroundColor(vm.secondaryLabel)
                Spacer()
                
                if let asset = vm.wallet[vm.offerToken] {
                    Text("Balance: \(String(asset.balance)) \(asset.code)")
                        .font(.callout)
                        .foregroundColor(vm.secondaryLabel)
                    Text("MAX")
                        .font(.body.bold())
                        .onTapGesture {
                            vm.mediumFeedback?.impactOccurred()
                            vm.offerAmount = String(asset.balance)
                        }
                }
            }
            
            HStack(alignment: .center) {
                buildTokenButton(token: $vm.offerToken, isOfferAsset: .constant(true))
                Spacer()
                TextField("0", text: $vm.offerAmount)
                    .fixedSize(horizontal: true, vertical: false)
                    .font(.title.bold())
                    .limitLength($vm.offerAmount, to: 9)
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
                buildTokenButton(token: $vm.askToken, isOfferAsset: .constant(false))
                Spacer()
                Text(vm.simutale?.getAskUnits() ?? "0")
                    .font(.title.bold())
                    .foregroundColor(vm.mainLabel)
            }
            
            if let rate = vm.swapRate, !rate.isEmpty {
                Divider()
                HStack(alignment: .center) {
                    Text(rate)
                    Spacer()
                    ProgressView()
                }
                .font(.callout)
                .foregroundColor(vm.secondaryLabel)
                Divider()
            }
            
            vm.simutale?.buildView(mainLabel: vm.mainLabel, secondaryLabel: vm.secondaryLabel,
                                   askToken: vm.askToken, feeToken: vm.offerToken)
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
        .onTapGesture {
            vm.mediumFeedback?.impactOccurred()
            
            // swap
            let temp = vm.askToken
            vm.askToken = vm.offerToken
            vm.offerToken = temp
            
            vm.receiveAmount = 0
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
        }
        .font(.body.bold())
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(vm.layer2)
        .foregroundColor(vm.mainLabel)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
    }
    
    @ViewBuilder
    func buildTokenButton(token: Binding<String>, isOfferAsset: Binding<Bool>) -> some View {
        NavigationLink {
            SwapToken(token: token, isOfferAsset: isOfferAsset)
                .environmentObject(vm)
        } label: {
            if token.wrappedValue.isEmpty {
                Text("Choose".uppercased())
                    .font(.body.bold())
                    .foregroundColor(vm.mainLabel)
                    .padding(6)
                    .background(vm.layer3)
                    .clipShape(Capsule())
            } else {
                HStack(alignment: .center, spacing: 4) {
                    buildTokenIcon(
                        width: 24,
                        urlString: vm.swapableAsset.first(where: {
                            $0.symbol?.uppercased() == token.wrappedValue.uppercased()
                        })?.imageURL
                    )
                    Text(token.wrappedValue.uppercased())
                        .font(.body.bold())
                        .foregroundColor(vm.mainLabel)
                }
                .padding(6)
                .background(vm.layer3)
                .clipShape(Capsule())
            }
        }
    }
    
    @ViewBuilder
    func buildNavigationToConfirm() -> some View {
        NavigationLink {
            SwapConfirm()
                .environmentObject(vm)
        } label: {
            Text("Continue")
                .padding()
                .font(.body.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(vm.layer2)
                .foregroundColor(vm.mainLabel)
                .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
        }
        .simultaneousGesture(TapGesture().onEnded({ _ in
            vm.shouldCommitChange = false
            vm.mediumFeedback?.impactOccurred()
        }))
    }
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                buildHeader()
                
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 10) {
                            buildFromAssetView()
                            buildToAssetView()
                        }
                        buildSwapIcon()
                    }
                    
                    Group {
                        if case .ready = vm.status {
                            buildNavigationToConfirm()
                        } else {
                            buildSwapButton()
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .navigationBarBackButtonHidden(true)
            
            .background(vm.layer1)
            .padding()
            
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            
            .onAppear {
                vm.shouldCommitChange = true
                if vm.mediumFeedback == nil {
                    vm.initHaptic()
                }
                
                if vm.methods == nil {
                    vm.update { result in
                        DispatchQueue.main.async {
                            print(result)
                            
                            switch result {
                            case .success(let data):
                                if let method = data.result {
                                    vm.methods = method
                                    vm.swapableAsset = method.assets ?? []
                                }
                                
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
                        }
                    }
                }
            }
        }
    }
}

import Kingfisher

struct SwapToken: View {
    @Environment(\.presentationMode) var presentation
    
    @EnvironmentObject var vm: SwapVM
    @Binding var token: String
    @Binding var isOfferAsset: Bool
    
    @ViewBuilder
    func buildHeader() -> some View {
        HeaderView {
            Text("Choose Token")
                .font(.title.bold())
        } right: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onTapGesture {
                    presentation.wrappedValue.dismiss()
                }
        }
    }
    
    @ViewBuilder
    func buildSearch() -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .frame(width: 16, height: 16)
            TextField("Search", text: $vm.searchQuery)
        }
        .frame(height: 48)
        .padding(.horizontal, 12)
        .padding(.vertical, 0)
        .background(vm.layer2)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    @ViewBuilder
    func buildSuggestedToken() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggested")
                .font(.title3.bold())
            
            FlowLayout(vm.suggestedTokens, spacing: 4) { tag in
                HStack(alignment: .center, spacing: 4) {
                    buildTokenIcon(
                        width: 28, urlString: vm.swapableAsset.first(where: {
                            $0.symbol?.uppercased() ?? "" == tag.uppercased()
                        })?.imageURL
                    )
                    Text(tag.uppercased())
                }
                .foregroundColor(vm.mainLabel)
                .padding(6)
                .background(vm.layer2)
                .clipShape(Capsule(style: .continuous))
                .onTapGesture {
                    vm.mediumFeedback?.impactOccurred()
                    
                    switch isOfferAsset {
                    case false:
                        if vm.offerToken.uppercased() != tag.uppercased() {
                            token = tag.uppercased()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                                presentation.wrappedValue.dismiss()
                            })
                        }
                    case true:
                        if vm.askToken.uppercased() != tag.uppercased() {
                            token = tag.uppercased()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                                presentation.wrappedValue.dismiss()
                            })
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func buildTokenIcon(width: CGFloat, urlString: String?) -> some View {
        if let url = URL(string: urlString ?? "") {
            KFImage(url)
                .placeholder({
                    Image(systemName: "questionmark.circle.fill")
                        .resizable()
                        .frame(width: width, height: width, alignment: .center)
                        .clipShape(Circle())
                })
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: width, alignment: .center)
                .clipShape(Circle())
        } else {
            Image(systemName: "questionmark.circle.fill")
                .resizable()
                .frame(width: width, height: width, alignment: .center)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    func buildOtherToken() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Other")
                .font(.title3.bold())
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(vm.swapableAsset) { asset in
                        HStack(alignment: .center, spacing: 16) {
                            buildTokenIcon(width: 44, urlString: asset.imageURL)
                            
                            VStack(alignment: .center, spacing: 2) {
                                HStack(alignment: .center) {
                                    Text(asset.symbol ?? "?")
                                    Spacer()
                                    Text("100000")
                                }
                                .font(.body.bold())
                                .foregroundColor(vm.mainLabel)
                                
                                HStack(alignment: .center) {
                                    Text(asset.displayName ?? "?")
                                    Spacer()
                                    Text("$600")
                                }
                                .font(.callout)
                                .foregroundColor(vm.secondaryLabel)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 76)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            vm.mediumFeedback?.impactOccurred()
                            token = asset.symbol?.uppercased() ?? ""
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                                presentation.wrappedValue.dismiss()
                            })
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                    }
                }
                .background(vm.layer2)
                .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
            }
        }
    }
    
    @ViewBuilder
    func buildSearchResult() -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(vm.searchResult) { asset in
                    HStack(alignment: .center, spacing: 16) {
                        buildTokenIcon(width: 44, urlString: asset.imageURL)
                        
                        VStack(alignment: .center, spacing: 2) {
                            HStack(alignment: .center) {
                                Text(asset.symbol ?? "?")
                                Spacer()
                                Text("100000")
                            }
                            .font(.body.bold())
                            .foregroundColor(vm.mainLabel)
                            
                            HStack(alignment: .center) {
                                Text(asset.displayName ?? "?")
                                Spacer()
                                Text("$600")
                            }
                            .font(.callout)
                            .foregroundColor(vm.secondaryLabel)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 76)
                    .contentShape(Rectangle())
                    .onTapGesture {
                            vm.mediumFeedback?.impactOccurred()
                            token = (asset.symbol ?? "").uppercased()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                                presentation.wrappedValue.dismiss()
                            })
                    }
                    
                    Divider()
                        .padding(.leading, 16)
                }
            }
            .background(vm.layer2)
            .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
        }
    }
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                buildHeader()
                buildSearch()
                
                if vm.isSearching {
                    buildSearchResult()
                    Spacer()
                } else {
                    buildSuggestedToken()
                    buildOtherToken()
                    
                    Text("Close")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vm.layer2)
                        .foregroundColor(vm.mainLabel)
                        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                        .onTapGesture {
                            presentation.wrappedValue.dismiss()
                        }
                }
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

struct SwapConfirm: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: SwapVM
    
    @State var swapStatus: SwapStatus = .ready
    
    @ViewBuilder
    func buildHeader() -> some View {
        HeaderView {
            Text("Confirm Swap")
                .font(.title.bold())
        } right: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onTapGesture {
                    presentation.wrappedValue.dismiss()
                }
        }
    }
    
    @ViewBuilder
    func buildTokenIcon(width: CGFloat, urlString: String?) -> some View {
        if let url = URL(string: urlString ?? "") {
            KFImage(url)
                .placeholder({
                    Image(systemName: "questionmark.circle.fill")
                        .resizable()
                        .frame(width: width, height: width, alignment: .center)
                        .clipShape(Circle())
                })
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: width, alignment: .center)
                .clipShape(Circle())
        } else {
            Image(systemName: "questionmark.circle.fill")
                .resizable()
                .frame(width: width, height: width, alignment: .center)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    func buildFromAssetView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text("Send")
                Spacer()
                Text("? USD")
            }
            .font(.callout)
            .foregroundColor(vm.secondaryLabel)
            
            HStack(alignment: .center) {
                Button {} label: {
                    HStack(alignment: .center, spacing: 4) {
                        buildTokenIcon(
                            width: 24,
                            urlString: vm.swapableAsset.first(where: {
                                $0.symbol?.uppercased() == vm.offerToken.uppercased()
                            })?.imageURL
                        )
                        Text(vm.offerToken.uppercased())
                            .font(.body.bold())
                            .foregroundColor(vm.mainLabel)
                    }
                    .padding(6)
                    .background(vm.layer3)
                    .clipShape(Capsule())
                }
                .foregroundColor(.white)
                
                Spacer()
                
                Text(vm.offerAmount)
                    .font(.title.bold())
                    .foregroundColor(vm.mainLabel)
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
                Spacer()
                Text("? USD")
            }
            .font(.callout)
            .foregroundColor(vm.secondaryLabel)
            
            HStack(alignment: .center) {
                Button {} label: {
                    HStack(alignment: .center, spacing: 4) {
                        buildTokenIcon(
                            width: 24,
                            urlString: vm.swapableAsset.first(where: {
                                $0.symbol?.uppercased() == vm.askToken.uppercased()
                            })?.imageURL
                        )
                        Text(vm.askToken.uppercased())
                            .font(.body.bold())
                            .foregroundColor(vm.mainLabel)
                    }
                    .padding(6)
                    .background(vm.layer3)
                    .clipShape(Capsule())
                }
                .foregroundColor(.white)
                
                Spacer()
                
                Text(vm.simutale?.getAskUnits() ?? "~")
                    .font(.title.bold())
                    .foregroundColor(vm.mainLabel)
            }
            
            Divider()
            
            vm.simutale?.buildView(mainLabel: vm.mainLabel, secondaryLabel: vm.secondaryLabel,
                                   askToken: vm.askToken, feeToken: vm.offerToken)
        }
        .padding()
        .background(vm.layer2)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
    }
    
    @ViewBuilder
    func buildConfirmCancel() -> some View {
        if case .ready = swapStatus {
            HStack(alignment: .center, spacing: 16) {
                Text("Cancel")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.layer2)
                    .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                    .onTapGesture {
                        vm.mediumFeedback?.impactOccurred()
                        presentation.wrappedValue.dismiss()
                    }
                
                Text("Confirm")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.main)
                    .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                    .onTapGesture {
                        vm.mediumFeedback?.impactOccurred()
                        
                        swapStatus = .loading
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            withAnimation {
                                swapStatus = .success
                            }
                        })
                    }
            }
        }
        
        if case .loading = swapStatus {
            Text("Loading ...")
                .font(.callout.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        
        if case .success = swapStatus {
            Text("Done")
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.callout.bold())
                .foregroundColor(.green)
                .padding()
        }
    }
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                buildHeader()
                
                VStack(alignment: .leading, spacing: 10) {
                    buildFromAssetView()
                    buildToAssetView()
                }

                Spacer()
                buildConfirmCancel()
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

import CoreHaptics

struct SwapSlippage: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: SwapVM
    @State var slippage: Double = 0
    
    
    @ViewBuilder
    func textField(amount: Binding<Double>, isFocus: Binding<Bool>, asset: String) -> some View {
        let text = Binding<String>(
            get: {
//                amount.wrappedValue > 0 ?
//                    String(format: "%.3f", amount.wrappedValue) : "0"
                amount.wrappedValue.trimmedString
            },
            set: { text in
                self.slippage = Double(text) ?? 0
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
    
    @ViewBuilder
    func buildHeader() -> some View {
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
    }
    
    @ViewBuilder
    func buildExpertMode() -> some View {
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
    }
    
    @ViewBuilder
    func buildCustomSlippage() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Slippage")
                .font(.headline.bold())
            Text(LocalizedStringKey("The amount the price can change \nunfavorably before the trade reverts"))
                .font(.callout)
                .foregroundColor(vm.secondaryLabel)
        }
        
        if vm.isExpert {
            textField(amount: $slippage, isFocus: .constant(false), asset: "%")
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
    }
    
    @ViewBuilder
    func buildPredefinedSlippage() -> some View {
        HStack(alignment: .center, spacing: 16) {
            ForEach(vm.predefinedSlippage, id: \.description) { slippage in
                Text(String(format: "%.0f%%", slippage))
                    .font(.callout.bold())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(vm.layer2)
                    .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                    .onTapGesture {
                        vm.mediumFeedback?.impactOccurred()
                        self.slippage = slippage
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous)
                            .stroke(vm.main, lineWidth: self.slippage == slippage ? 2 : 0)
                    )
            }
        }
    }
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                buildHeader()
                buildCustomSlippage()
                buildPredefinedSlippage()
                buildExpertMode()
                Spacer()
            }
            
            .onAppear {
                slippage = vm.slippage
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
                    .onTapGesture {
                        vm.slippage = slippage
                        presentation.wrappedValue.dismiss()
                    }
            }
            .padding()
        }
    }
}

#Preview {
    NavigationView {
        Swap()
        
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

//struct SwapDetail {
//    
//    var priceImpact: Double?
//    var minimumReceived: Double?
//    var liquidityProviderFee: Double?
//    var blockchainFee: String?
//    var route: String?
//    var provider: String?
//    
//    var fromAsset: String?
//    var toAsset: String?
//    
//    var mainLabel: Color = Color.primary
//    var secondaryLabel: Color = Color.secondary
//    
//    static var defaultInstance: SwapDetail = .init(
//        priceImpact: 0.001,
//        minimumReceived: 6000.01,
//        liquidityProviderFee: 0.00000000001,
//        blockchainFee: "0.11 - 0.17 TON",
//        route: "TON >> USDT",
//        provider: "STON.fi",
//        fromAsset: "TON",
//        toAsset: "USDT",
//        mainLabel: Color.primary,
//        secondaryLabel: Color.secondary
//    )
//    
//    @ViewBuilder
//    func buildDetailRow(title: String, content: String, didTapInfo: (()->Void)? = nil) -> some View {
//        HStack(alignment: .center) {
//            HStack(alignment: .center, spacing: 2) {
//                Text(title)
//                if let didTapInfo {
//                    Image(systemName: "info.circle.fill")
//                }
//            }
//            .foregroundColor(secondaryLabel)
//            .onTapGesture { // for user to tap on the whole text, not just info icon
//                didTapInfo?()
//            }
//            
//            Spacer()
//            Text(content)
//                .foregroundColor(mainLabel)
//        }
//    }
//    
//    @ViewBuilder
//    func buildView() -> some View {
//        VStack(alignment: .leading, spacing: 12) {
//            if let priceImpact {
//                buildDetailRow(title: "priceImpact", content: String(priceImpact) + "%") {
//                    print("here is your code")
//                }
//            }
//            if let minimumReceived {
//                buildDetailRow(title: "minimumReceived", content: String(minimumReceived))
//            }
//            if let liquidityProviderFee {
//                buildDetailRow(title: "liquidityProviderFee", content: String(liquidityProviderFee))
//            }
//            if let blockchainFee {
//                buildDetailRow(title: "blockchainFee", content: String(blockchainFee))
//            }
//            if let route {
//                buildDetailRow(title: "route", content: String(route))
//            }
//            if let provider {
//                buildDetailRow(title: "provider", content: String(provider))
//            }
//        }
//        .font(.callout.bold())
//    }
//}


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
