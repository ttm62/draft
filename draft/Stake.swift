//
//  Stake.swift
//  draft
//
//  Created by davidtam on 24/5/24.
//

import SwiftUI

final
class StakeViewModel: ObservableObject {
    
    @Published var asset: String = "TON"
    @Published var amount: String = ""
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
    
    let main: Color = Color.blue
    let layer1: Color = Color(UIColor.secondarySystemBackground)
    let layer2: Color = Color(UIColor.secondarySystemFill)
    let layer3: Color = Color(UIColor.secondaryLabel)
    let mainLabel: Color = Color.primary
    let secondaryLabel: Color = Color.secondary
    
    let cornerRadius: CGFloat = 10
    
    func performStakeChange() {
        
    }
}

struct Stake: View {
    @StateObject var vm: StakeViewModel = StakeViewModel()
    
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
        }
    }
    
    @ViewBuilder
    func buildInput() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            
            VStack(alignment: .center, spacing: 6) {
                textField()
                    .frame(height: 50)
                
                VStack(alignment: .center, spacing: 12) {
                    Text("6000.01 USD")
                        .padding(8)
                        .font(.body)
                        .foregroundColor(vm.secondaryLabel)
                        .overlay(
                            Capsule()
                                .stroke(Color.secondary, lineWidth: 1)
                        )
                }
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
                
                Spacer()
                
//                Text("Insufficient balance")
//                    .font(.body)
//                    .foregroundColor(.red)
                
                Text("Available: 100,000.01 TON")
                    .font(.body)
                    .foregroundColor(vm.secondaryLabel)
            }
        }
        .padding(.bottom, 16)
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
    func textField() -> some View {
        HStack(alignment: .center, spacing: 4) {
            DynamicFontSizeTextField(text: $vm.amount, maxLength: 15)
                .fixedSize(horizontal: true, vertical: false)
                .keyboardType(.decimalPad)
                .foregroundColor(Color.white)
                .multilineTextAlignment(.center)

            Button {} label: {
                Text(vm.asset)
                    .font(.system(size: DynamicFontSizeTextField.dynamicSize(vm.amount), weight: .bold, design: .default))
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
        ZStack {
            vm.layer1.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                buildHeader()
                buildInput()
                buildStakeOption()
                
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
