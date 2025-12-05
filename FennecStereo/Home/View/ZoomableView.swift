import SwiftUI

fileprivate extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
}

struct ZoomableView<Content: View>: View {
    // MARK: - State
    @Binding var accumulatedScale: CGFloat
    @Binding var accumulatedOffset: CGSize
    @State private var gestureScale: CGFloat = 1.0
    @State private var currentTranslation: CGSize = .zero
    
    private let minScale: CGFloat = 0.25
    private let maxScale: CGFloat = 4.0
    
    let content: Content
    
    // Corrected initializer to accept the bindings and the content view
    init(accumulatedScale: Binding<CGFloat>, accumulatedOffset: Binding<CGSize>, @ViewBuilder content: () -> Content) {
        self._accumulatedScale = accumulatedScale
        self._accumulatedOffset = accumulatedOffset
        self.content = content()
    }
    
    private var effectiveScale: CGFloat {
        max(minScale, min(maxScale, accumulatedScale * gestureScale))
    }
    
    private var effectiveOffset: CGSize {
        accumulatedOffset + currentTranslation
    }
    
    private var dragAndMagnificationGesture: some Gesture {
        SimultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    currentTranslation = value.translation
                },
            MagnificationGesture()
                .onChanged { value in
                    gestureScale = value
                }
        )
        .onEnded { value in
            accumulatedScale = effectiveScale
            if let dragValue = value.first {
                accumulatedOffset = accumulatedOffset + dragValue.translation
            }
            gestureScale = 1.0
            currentTranslation = .zero
        }
    }
    
    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation(.easeInOut(duration: 0.3)) {

                    let halfZoom = maxScale / 2

                    // Case 1: currently normal → go to half zoom
                    if abs(accumulatedScale - 1.0) < 0.01 {
                        accumulatedScale = halfZoom
                    }
                    // Case 2: currently half zoom → go to max zoom
                    else if abs(accumulatedScale - halfZoom) < 0.01 {
                        accumulatedScale = maxScale
                    }
                    // Case 3: currently max (or anything else) → reset to normal
                    else {
                        accumulatedScale = 1.0
                        accumulatedOffset = .zero   // reset offset when going back to normal
                    }

                    gestureScale = 1.0
                    currentTranslation = .zero
                }
            }
    }

    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                Rectangle()
                    .fill(Color.clear)
                
                content
                    .scaleEffect(effectiveScale)
                    .offset(effectiveOffset)
                    .contentShape(Rectangle())
                    .gesture(dragAndMagnificationGesture)
                    .simultaneousGesture(doubleTapGesture)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: effectiveScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: effectiveOffset)
        }
    }
}
