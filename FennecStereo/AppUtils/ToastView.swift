//
//  ToastView.swift
//  FennecStereo
//
//  Created by Kushkumar on 15/10/25.
//

import SwiftUI
import Combine

enum ToastPosition {
    case top
    case bottom
}

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let position: ToastPosition

    // ✅ Add Equatable conformance
    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}


class ToastManager: ObservableObject {
    @Published var toast: Toast?

    func show(message: String, position: ToastPosition = .bottom) {
        toast = Toast(message: message, position: position)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                self.toast = nil
            }
        }
    }
}

struct ToastView: View {
    let toast: Toast
    var body: some View {
        Text(toast.message)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(radius: 4)
    }
}

struct ToastModifier: ViewModifier {
    @ObservedObject var manager: ToastManager

    func body(content: Content) -> some View {
        ZStack {
            content
            if let toast = manager.toast {
                VStack {
                    if toast.position == .top {
                        ToastView(toast: toast)
                            .padding(.top, 60)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        Spacer()
                    } else {
                        Spacer()
                        ToastView(toast: toast)
                            .padding(.bottom, 60)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()  // ✅ Stops layout shifting
            }
        }
    }
}

extension View {
    func toast(manager: ToastManager) -> some View {
        self.modifier(ToastModifier(manager: manager))
    }
}
