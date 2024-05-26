//
//  Stake.swift
//  draft
//
//  Created by davidtam on 24/5/24.
//

import SwiftUI

typealias EmptyHandler = () -> Void

final
class StakeViewModel: ObservableObject {
    var didTapDismiss: EmptyHandler?
    let maxAmount: Double = 3.14159
    
    @Published var stakeAmount: String = "0" // more convenience than double when process floating input
    @Published var stakeAsset: String = "TON"
    @Published var rate: Double = 6.1
    @Published var currency: String = "USD"
    
    let maxInputLength: Int = 13
    
    @Published var stakingDetail: [String: String] = [
        "Wallet": "😳 Main",
        "Recipient": "Tonstakers",
        "APY": "~5%",
        "Fee": "~0,01 TON"
    ]
    
    @Published var selectedStaking: String = ""
    @Published var liquidStakingOptions: [String] = [
        "Ton Staker",
        "Bemo",
        "Whaled liquid Pool"
    ]
    
    @Published var otherStakingOptions: [String] = [
        "TON Whales",
        "TON Normonators",
    ]
    
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
    let alertLabel: Color = Color.red
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
}

struct Stake: View {
    @StateObject var vm: StakeViewModel = StakeViewModel()
    
    @State var availableAmount: Double = 0
    
    @ViewBuilder
    func buildHeader() -> some View {
        HeaderView {
            Text("Stake")
                .font(.title3.bold())
        } left: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
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
    func buildAvailableAsset() -> some View {
        if let stakeAmount = Double(vm.stakeAmount), vm.maxAmount - stakeAmount >= 0 {
            let available = (vm.maxAmount - stakeAmount).trimmedString
            Text("Available \(available) \(vm.stakeAsset)")
                .font(.body)
                .foregroundColor(vm.secondaryLabel)
        } else {
            Text("Insufficient balance")
                .font(.body)
                .foregroundColor(vm.alertLabel)
        }
    }
    
    @ViewBuilder
    func buildStakeValue() -> some View {
        Group {
            if let stakeAmount = Double(vm.stakeAmount.prefix(vm.maxInputLength)) {
                Text("\((stakeAmount*vm.rate).trimmedString) \(vm.currency.uppercased())")
            } else {
                Text("0 \(vm.currency.uppercased())")
            }
        }
        .padding(8)
        .font(.body)
        .foregroundColor(vm.secondaryLabel)
        .overlay(
            Capsule()
                .stroke(Color.secondary, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    func buildInput() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            
            VStack(alignment: .center, spacing: 6) {
                textField()
                    .frame(height: 50)
                
                buildStakeValue()
            }
            .frame(height: 188)
            .padding()
            .frame(maxWidth: .infinity)
            .background(vm.layer2)
            .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
            
            HStack {
                Text("MAX")
                    .font(.footnote.bold())
                    .padding(10)
                    .background(vm.layer2)
                    .clipShape(Capsule())
                    .onTapGesture {
                        vm.mediumFeedback?.impactOccurred()
                        vm.stakeAmount = vm.maxAmount.description
                    }
                
                Spacer()
                buildAvailableAsset()
            }
        }
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    func textField() -> some View {
        HStack(alignment: .center, spacing: 4) {
            DynamicSizeInputField(text: $vm.stakeAmount, maxLength: vm.maxInputLength)
                .fixedSize(horizontal: true, vertical: false)
                .keyboardType(.decimalPad)
                .foregroundColor(Color.white)
                .multilineTextAlignment(.center)

            Button {} label: {
                Text(vm.stakeAsset)
                    .font(.system(size: DynamicSizeInputField.dynamicSize(vm.stakeAmount.description), weight: .bold, design: .default))
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
    
    @ViewBuilder
    func buildStakeOption() -> some View {
        NavigationLink {
            StakeOption()
                .environmentObject(vm)
        } label: {
            HStack(alignment: .center, spacing: 16) {
                vm.layer2.frame(width: 44, height: 44)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("Tonstaker")
                            .font(.headline.bold())
                            .foregroundColor(vm.mainLabel)
                        
                        Text("MAX APY")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .padding(4)
                            .foregroundColor(Color.green)
                            .background(Color.green.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text("APY ~ 5%")
                        Text("-")
                        Text("? TON")
                    }
                    .font(.caption)
                    .foregroundColor(vm.secondaryLabel)
                }
                
                Spacer()
                
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(vm.secondaryLabel)
            }
            .padding(14)
            .background(vm.layer2)
            .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
        }
    }
    
    @ViewBuilder
    func buildContinueButton() -> some View {
        if let stakeAmount = Double(vm.stakeAmount), stakeAmount > 0 && vm.maxAmount - stakeAmount >= 0 {
            NavigationLink {
                StakeConfirm()
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
                buildHeader()
                buildInput()
                buildStakeOption()
                
                Spacer()
            }
            
            .onAppear {
                availableAmount = vm.maxAmount
                
                if vm.mediumFeedback == nil {
                    vm.initHaptic()
                }
            }
            
            .navigationBarBackButtonHidden(true)
            .padding()
            
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            
            VStack {
                Spacer()
                buildContinueButton()
            }
            .padding()
        }
    }
}

struct StakeOption: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: StakeViewModel
    
    @ViewBuilder
    func buildHeader() -> some View {
        HeaderView {
            Text("Options")
                .font(.title3.bold())
        } left: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onTapGesture {
                    presentation.wrappedValue.dismiss()
                }
        } right: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    func buildLiquidRow(asset: String, tag: String?) -> some View {
        HStack(alignment: .center, spacing: 16) {
            NavigationLink {
                StakeProvider(
                    provider: .constant(asset),
                    infoDict: .constant(["APY":"~5%", "Minimal deposit":"1 TON"]),
                    didTapChoose: { asset in
                        vm.selectedStaking = asset
                    }
                )
                .environmentObject(StakeViewModel())
            } label: {
                vm.layer2.frame(width: 44, height: 44)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(asset)
                            .font(.headline.bold())
                            .foregroundColor(vm.mainLabel)
                        
                        if let tag {
                            Text(tag)
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .padding(4)
                                .foregroundColor(Color.green)
                                .background(Color.green.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text("APY ~ 5%")
                        Text("-")
                        Text("? TON")
                    }
                    .font(.caption)
                    .foregroundColor(vm.secondaryLabel)
                }
            }
            
            Spacer()
            
            Group {
                if asset == vm.selectedStaking {
                    vm.main.frame(width: 18, height: 18)
                } else {
                    vm.layer3.frame(width: 18, height: 18)
                }
            }
            .clipShape(Circle())
            .onTapGesture {
                vm.selectedStaking = asset
            }
        }
    }
    
    @ViewBuilder 
    func buildLiquidStaking() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Liquid Staking")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                ForEach(vm.liquidStakingOptions, id: \.description) { item in
                    buildLiquidRow(asset: item, tag: item == vm.liquidStakingOptions.first! ? "MAX APY" : nil)
                        .padding(16)
                    
                    Divider()
                }
            }
            .background(vm.layer2)
            .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
        }
    }
    
    @ViewBuilder
    func buildOtherRow(asset: String, tag: String?) -> some View {
        NavigationLink {
            StakeProviderList(provider: .constant(asset))
                .environmentObject(vm)
        } label: {
            HStack(alignment: .center, spacing: 16) {
                vm.layer2.frame(width: 44, height: 44)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(asset)
                            .foregroundColor(vm.mainLabel)
                            .font(.headline.bold())
                        
                        if let tag {
                            Text(tag)
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .padding(4)
                                .foregroundColor(Color.green)
                                .background(Color.green.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text("APY ~ 5%")
                        Text("-")
                        Text("? TON")
                    }
                    .font(.caption)
                    .foregroundColor(vm.secondaryLabel)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(vm.secondaryLabel)
            }
        }
    }
    
    @ViewBuilder 
    func buildOtherOptions() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Others")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                ForEach(vm.otherStakingOptions, id: \.description) { item in
                    buildOtherRow(asset: item, tag: item == vm.liquidStakingOptions.first! ? "MAX APY" : nil)
                        .padding(16)
                    
                    Divider()
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        buildLiquidStaking()
                        buildOtherOptions()
                    }
                }
                
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

struct StakeProviderList: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: StakeViewModel
    
    @Binding var provider: String
    
    @ViewBuilder
    func buildHeader() -> some View {
        HeaderView {
            Text(provider)
                .font(.title3.bold())
        } left: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onTapGesture {
                    presentation.wrappedValue.dismiss()
                }
        } right: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    func buildLiquidRow(asset: String, tag: String?) -> some View {
        HStack(alignment: .center, spacing: 16) {
            NavigationLink {
                StakeProvider(
                    provider: .constant(asset),
                    infoDict: .constant(["APY":"~5%", "Minimal deposit":"1 TON"]),
                    didTapChoose: { asset in
                        vm.selectedStaking = asset
                    }
                )
                .environmentObject(StakeViewModel())
            } label: {
                vm.layer2.frame(width: 44, height: 44)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(asset)
                            .font(.headline.bold())
                            .foregroundColor(vm.mainLabel)
                        
                        if let tag {
                            Text(tag)
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .padding(4)
                                .foregroundColor(Color.green)
                                .background(Color.green.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text("APY ~ 5%")
                        Text("-")
                        Text("? TON")
                    }
                    .font(.caption)
                    .foregroundColor(vm.secondaryLabel)
                }
            }
            
            Spacer()
            
            Group {
                if asset == vm.selectedStaking {
                    vm.main.frame(width: 18, height: 18)
                } else {
                    vm.layer3.frame(width: 18, height: 18)
                }
            }
            .clipShape(Circle())
            .onTapGesture {
                vm.selectedStaking = asset
            }
        }
    }
    
    @ViewBuilder
    func buildLiquidStaking() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Liquid Staking")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                ForEach(vm.liquidStakingOptions, id: \.description) { item in
                    buildLiquidRow(asset: item, tag: item == vm.liquidStakingOptions.first! ? "MAX APY" : nil)
                        .padding(16)
                    
                    Divider()
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        buildLiquidStaking()
                    }
                }
                
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

struct StakeProvider: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: StakeViewModel
    
    @Binding var provider: String
    @Binding var infoDict: [String: String]
    @State var links: [String] = [
        "tonstakers.com",
        "google.com",
        "bit.ly"
    ]
    
    var didTapChoose: ((String) -> Void)?
    
    @ViewBuilder
    func buildHeader() -> some View {
        HeaderView {
            Text(provider)
                .font(.title3.bold())
        } left: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onTapGesture {
                    presentation.wrappedValue.dismiss()
                }
        } right: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    func buildAPYDetail() -> some View {
        VStack(spacing: 12) {
            ForEach(infoDict.sorted(by: >), id: \.key) { key, value in
                HStack {
                    Text(key)
                        .font(.callout)
                        .foregroundColor(vm.secondaryLabel)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.callout.bold())
                        .foregroundColor(vm.mainLabel)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(vm.layer2)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
    }
    
    @ViewBuilder
    func buildLinks() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Links")
                .font(.title3.bold())
            
            FlowLayout(links, spacing: 4) { tag in
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
//                    asset = tag.uppercased()
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
//                        presentation.wrappedValue.dismiss()
//                    })
                    
                    print(tag)
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                buildHeader()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 14) {
                            buildAPYDetail()
                            VStack {
                                Text("Staking is based on smart contracts by third parties. Tonkeeper is not responsible for staking experience.")
                                    .font(.caption)
                                    .foregroundColor(vm.secondaryLabel)
                            }
                        }
                        
                        buildLinks()
                    }
                }
                
                Spacer()
            }
            .navigationBarBackButtonHidden(true)
            
            .background(vm.layer1)
            .padding([.top, .horizontal])
            
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            
            VStack {
                Spacer()
                Text("Choose")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.main)
                    .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
                    .onTapGesture {
                        presentation.wrappedValue.dismiss()
                        didTapChoose?(provider)
                    }
            }
            .padding()
        }
    }
}

struct StakeConfirm: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var vm: StakeViewModel
    
    @ViewBuilder
    func buildHeader() -> some View {
        HeaderView {
            EmptyView()
        } left: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onTapGesture {
                    presentation.wrappedValue.dismiss()
                }
        } right: {
            vm.layer2
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder 
    func buildStakingPreview() -> some View {
        VStack(alignment: .center, spacing: 16) {
            vm.layer2
                .frame(width: 92, height: 92)
                .clipShape(Circle())
            
            VStack(alignment: .center, spacing: 4) {
                Text("Deposit / Unstake")
                    .font(.callout)
                    .foregroundColor(vm.secondaryLabel)
                
                HStack(alignment: .center) {
                    Text("1000,01")
                    Text("TON")
                }
                .font(.title3.bold())
                .foregroundColor(vm.mainLabel)
                
                Text("$6010")
                    .font(.callout)
                    .foregroundColor(vm.secondaryLabel)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder func buildStakingDetail() -> some View {
        VStack(spacing: 12) {
            ForEach(vm.stakingDetail.sorted(by: >), id: \.key) { key, value in
                HStack {
                    Text(key)
                        .font(.callout.bold())
                        .foregroundColor(vm.secondaryLabel)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.callout.bold())
                        .foregroundColor(vm.mainLabel)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
            }
        }
        .padding()
        .background(vm.layer2)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
    }
    
    var body: some View {
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                buildHeader()
                ScrollView {
                    buildStakingPreview()
                    buildStakingDetail()
                }
                Spacer()
            }
            .navigationBarBackButtonHidden(true)
            
            .background(vm.layer1)
            .padding([.top, .horizontal])
            
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            
            VStack {
                Spacer()
                Text("Confirm")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.main)
                    .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius, style: .continuous))
            }
            .padding()
        }
    }
}

//#Preview {
//    NavigationView {
//        StakeConfirm()
//            .environmentObject(StakeViewModel())
//    }
//}
//
//#Preview {
//    NavigationView {
//        StakeProvider(provider: .constant("Tonkeeper Queue #1"), infoDict: .constant(["APY":"~5%", "Minimal deposit":"1 TON"]))
//            .environmentObject(StakeViewModel())
//    }
//}
//
//#Preview {
//    NavigationView {
//        StakeOption()
//            .environmentObject(StakeViewModel())
//    }
//}

#Preview {
    NavigationView {
        Stake()
    }
}

//#Preview {
//    Demo()
//}

extension String {
    func process() -> String {
        guard let systemSeparator = Locale.current.decimalSeparator else {
            return "0"
        }
        
        var chunks: [String] = self.components(separatedBy: systemSeparator)
        
        let integralPart: String = chunks.first ?? "0"
        chunks.removeFirst()
        let fractionalPart: String = chunks.joined(separator: "")
        
        if fractionalPart.isEmpty {
            return integralPart
        } else {
            let result = "\(integralPart)\(systemSeparator)\(fractionalPart)"
            return result
        }
    }
}

extension Double {
    var trimmedString: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 9
        return formatter.string(for: self) ?? ""
    }
}

struct Demo: View {
    @State var amount: String = "0"
    
    var body: some View {
        VStack {
            Spacer()
            Text((Double(amount.process()) ?? 0).trimmedString)
                .font(.title3)
            DynamicSizeInputField(text: $amount, maxLength: 13)
                .border(.red, width: 1)
                .font(.system(size: DynamicSizeInputField.dynamicSize(amount.description), weight: .semibold, design: .rounded))
                .frame(height: 100)
                .keyboardType(.decimalPad)
            Spacer()
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }
}

struct DynamicSizeInputField: UIViewRepresentable {
    @Binding var text: String
    var maxLength: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.text = text
        textField.font = UIFont.systemFont(ofSize: DynamicSizeInputField.dynamicSize(text), weight: .bold)
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
        
        uiView.text = String(text.prefix(maxLength))
        uiView.font = UIFont.systemFont(ofSize: DynamicSizeInputField.dynamicSize(text))
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
        var parent: DynamicSizeInputField

        init(parent: DynamicSizeInputField) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            let newText = textField.text ?? ""
            if newText.count > parent.maxLength {
                textField.text = String(newText.prefix(parent.maxLength))
            }
            parent.text = (Double(newText.process()) ?? 0).trimmedString
            textField.font = UIFont.systemFont(ofSize: DynamicSizeInputField.dynamicSize(parent.text))
        }
    }
}
