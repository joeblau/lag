//
//  EstablishmentTypePickerView.swift
//  Lag
//
//  Created by Joe Blau on 9/13/20.
//

import SwiftUI
import ComposableArchitecture

struct EstablishmentPickerView: View {
    let store: Store<AppState, AppAction>
    @State private var pickerSetting = 0
    var types = Constants.pointsOfInterest

    var body: some View {
        WithViewStore(store) { viewStore in
            Picker(selection: viewStore.binding(get: { $0.establishmentPickerIndex }, send: { .setEstablishment($0) }),
                   label: Text("")) {
                ForEach(0 ..< types.count) { index in
                    Text(self.types[index].emoji).tag(index)
                }
            }.pickerStyle(SegmentedPickerStyle())
        }
    }
}

#if DEBUG
struct EstablishmentPickerView_Previews: PreviewProvider {
    static var previews: some View {
        EstablishmentPickerView(store: sampleAppStore)
    }
}
#endif
