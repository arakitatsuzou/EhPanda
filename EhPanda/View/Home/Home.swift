//
//  Home.swift
//  EhPanda
//
//  Created by 荒木辰造 on R 3/01/20.
//  Copied from https://kavsoft.dev/SwiftUI_2.0/Twitter_Menu/
//

import SwiftUI

struct Home: View, StoreAccessor {
    @EnvironmentObject var store: Store
    @Environment(\.colorScheme) private var colorScheme

    // SlideMenu
    @State private var direction: Direction = .none
    @State private var offset = -Defaults.FrameSize.slideMenuWidth
    @State private var width = Defaults.FrameSize.slideMenuWidth

    // AppLock
    @State private var blurRadius: CGFloat = 0

    var body: some View {
        ZStack {
            ZStack {
                HomeView()
                    .offset(x: offset + width)
                SlideMenu(offset: $offset)
                    .offset(x: offset)
                    .background(
                        Color.black.opacity(opacity)
                            .edgesIgnoringSafeArea(.vertical)
                            .onTapGesture {
                                performTransition(-width)
                            }
                    )
            }
            .blur(radius: blurRadius)
            .allowsHitTesting(isAppUnlocked)
            AuthView(blurRadius: $blurRadius)
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    withAnimation(Animation.linear(duration: 0.2)) {
                        switch direction {
                        case .none:
                            let isToLeft = value.translation.width < 0
                            direction = isToLeft ? .toLeft : .toRight
                        case .toLeft:
                            if offset > -width {
                                offset = min(value.translation.width, 0)
                            }
                        case .toRight:
                            if offset < 0, value.startLocation.x < 20 {
                                offset = max(-width + value.translation.width, -width)
                            }
                        }
                        updateSlideMenuState(isClosed: offset == -width)
                    }
                }
                .onEnded { value in
                    let perdictedWidth = value.predictedEndTranslation.width
                    if perdictedWidth > width / 2 || -offset < width / 2 {
                        performTransition(0)
                    }
                    if perdictedWidth < -width / 2 || -offset > width / 2 {
                        performTransition(-width)
                    }
                    direction = .none
                },
            including: gestureMask
        )
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.didBecomeActiveNotification
            )
        ) { _ in
            onWidthChange()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIDevice.orientationDidChangeNotification
            )
        ) { _ in
            if isPortrait || isLandscape {
                onWidthChange()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSNotification.Name("SlideMenuShouldClose")
            )
        ) { _ in
            onReceiveSlideMenuShouldCloseNotification()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSNotification.Name("BypassSNIFilteringDidChange")
            )
        ) { _ in
            toggleDomainFronting()
        }
    }
}

private extension Home {
    enum Direction {
        case none
        case toLeft
        case toRight
    }

    var gestureMask: GestureMask {
        viewControllersCount == 1 ? .all : .none
    }

    var opacity: Double {
        let scale = colorScheme == .light ? 0.2 : 0.5
        return Double((width + offset) / width) * scale
    }
    func onWidthChange() {
        if isPad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if width != Defaults.FrameSize.slideMenuWidth {
                    withAnimation {
                        offset = -Defaults.FrameSize.slideMenuWidth
                        width = Defaults.FrameSize.slideMenuWidth
                    }
                }
                postAppWidthDidChangeNotification()
            }
        }
    }
    func onReceiveSlideMenuShouldCloseNotification() {
        performTransition(-width)
    }
    func toggleDomainFronting() {
        if setting?.bypassSNIFiltering == true {
            URLProtocol.registerClass(DFURLProtocol.self)
            URLProtocol.registerWebview(scheme: "https")
        } else {
            URLProtocol.unregisterClass(DFURLProtocol.self)
            URLProtocol.unregisterWebview(scheme: "https")
        }
    }

    func performTransition(_ offset: CGFloat) {
        withAnimation(Animation.default) {
            self.offset = offset
        }
        updateSlideMenuState(isClosed: offset == -width)
    }

    func updateSlideMenuState(isClosed: Bool) {
        if isSlideMenuClosed != isClosed {
            store.dispatch(.updateIsSlideMenuClosed(isClosed: isClosed))
        }
    }
}
