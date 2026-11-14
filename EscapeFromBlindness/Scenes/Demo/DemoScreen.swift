//
//  DemoScreen.swift
//  EscapeFromBlindness
//
//  Created by Michael Martinez on 30/10/2024.
//  Copyright © 2024 michael-martinez. All rights reserved.
//

import SwiftUI
import InjectHotReload

struct DemoScreen: View {
  @ObserveInjection var inject

      var body: some View {
          VStack {
            Text(
              "Hello world"
            )
          }
          .enableInjection()
      }
}

#Preview {
  DemoScreen()
}
