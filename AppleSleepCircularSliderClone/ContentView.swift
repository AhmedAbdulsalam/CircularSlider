//
//  ContentView.swift
//  AppleSleepCircularSliderClone
//
//  Created by Ahmed Hamad on 19/11/24.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    CircularTimeSlider(viewModel: .init())
  }
}

#Preview {
    ContentView()
}
