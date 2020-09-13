//
//  ContentView.swift
//  Latency
//
//  Created by Joe Blau on 9/11/20.
//

import SwiftUI
import ComposableArchitecture

struct SearchView: View {
    let store: Store<AppState, AppAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView {
                VStack {
                    HStack {
                        TextField("Search ...", text: viewStore.binding(get: { $0.queryString }, send: { .updateQuery($0) } ))
                            .padding(7)
                            .padding(.horizontal, 25)
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(8)
                            .overlay(
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 8)
                                    if viewStore.isEditing {
                                        Button(action: {
                                            viewStore.send(.clearQuery)
                                        }) {
                                            Image(systemName: "multiply.circle.fill")
                                                .foregroundColor(.gray)
                                                .padding(.trailing, 8)
                                        }
                                    }
                                }
                            )
                            .padding(.horizontal, 10)
                            .onTapGesture {
                                viewStore.send(.setIsEditing(true))
                            }

                        if viewStore.isEditing {
                            Button(action: {
                                viewStore.send(.clearQuery)
                            }) {
                                Text("Cancel")
                            }
                            .padding(.trailing, 10)
                            .transition(.move(edge: .trailing))
                            .animation(.default)
                        }
                    }
                    List(viewStore.queryResults, id: \.self) { result in
                        HStack {
                            Text(result.address)
                            Spacer()
                            VStack {
                                Spacer()
                                HStack {
                                    Image(systemName: "arrow.up")
                                    Text("\(result.upload)")
                                }
                                Spacer()
                                HStack {
                                    Image(systemName: "arrow.down")
                                    Text("\(result.download)")
                                }
                                Spacer()
                            }
                            .font(.system(.subheadline, design: .monospaced))
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                .navigationBarTitle("Search")
                .navigationBarItems(trailing:
                                        Button(action: {
                                            viewStore.send(.presentScanner)
                                        }, label: {
                                            Text("Scan")
                                                .padding()
                                        })
                )
                .sheet(isPresented: viewStore.binding(get: { $0.showScanner }, send: .dismissScanner ), content: {
                    ScanView(store: store)
                })
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(store: sampleAppStore)
    }
}
#endif
