//
//  Swap.swift
//  draft
//
//  Created by davidtam on 22/05/2024.
//

import SwiftUI

struct SwapView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderView {
                Text("Swap")
                    .font(.title.bold())
            } left: {
                Spacer()
            } right: {
                Spacer()
            }

            Text("Hey")
        }
    }
}

#Preview {
//    SwapView()
    SlippageView()
}

struct SlippageView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderView {
                Text("Settings")
                    .font(.title.bold())
            } right: {
                HStack(alignment: .center) {
                    Button {} label: {
                        Image(systemName: "xmark")
                    }
                }
            }

            
        }
        .padding([.top, .horizontal])
        .navigationBarBackButtonHidden(true)
        
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }
}
