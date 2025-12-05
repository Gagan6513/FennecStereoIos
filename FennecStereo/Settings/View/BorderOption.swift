//
//  BorderOption.swift
//  FennecStereo
//
//  Created by Kushkumar on 08/10/25.
//

import SwiftUI

struct BorderOption: View {
    var title: String
    @Binding var selected: String
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .frame(width: 20, height: 20)
                
                if selected == title {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                }
            }
            
            Text(title)
                .foregroundColor(.white)
                .font(.footnote)
        }
        .onTapGesture {
            AppUtils.shared.hapticEffect()
            selected = title
        }
    }
}
