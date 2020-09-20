// ScanEstablishmentPickerView.swift
// Copyright (c) 2020 Submap

import ComposableArchitecture
import SwiftUI

struct ScanEstablishmentPickerView: View {
    let store: Store<ScanState, ScanAction>

    @State private var pickerSetting = 0
    var types = Constants.pointsOfInterest

    var body: some View {
        WithViewStore(store) { viewStore in
            Picker(selection: viewStore.binding(get: { $0.establishmentPickerIndex }, send: { .setEstablishment($0) }),
                   label: Text("")) {
                ForEach(0 ..< types.count) { index in
                    Text(self.types[index].emoji).tag(index)
                }
            }
            .disabled(viewStore.scanning != .notStarted)
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

#if DEBUG
    struct ScanEstablishmentPickerView_Previews: PreviewProvider {
        static var previews: some View {
            ScanEstablishmentPickerView(store: sampleScanStore)
        }
    }
#endif
