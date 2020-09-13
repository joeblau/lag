//
//  FastController.swift
//  Lag
//
//  Created by Joe Blau on 9/12/20.
//

import Foundation
import WebKit
import ComposableArchitecture
import Combine

private let source = """
var speedTarget = document.querySelector('#speed-value');
var uploadTarget = document.querySelector('#upload-value');

var observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {

        if (mutation.target.id == "speed-value") {

            if (mutation.attributeName == "class") {
            window.webkit.messageHandlers.notification.postMessage({ type: "down-done", value: "", units: "" });
            } else {
                let units = document.querySelector("#speed-units").innerText
                let value = mutation.addedNodes.item(0).data
                window.webkit.messageHandlers.notification.postMessage({ type: "down", value: value, units: units });
            }
        }

        if (mutation.target.id == "upload-value") {
            if (mutation.attributeName == "class") {
                window.webkit.messageHandlers.notification.postMessage({ type: "up-done", value: "", units: "" });
            } else {
                let units = document.querySelector("#upload-units").innerText
                let value = mutation.addedNodes.item(0).data
                window.webkit.messageHandlers.notification.postMessage({ type: "up", value: value, units: units });
            }
        }
    });
});

var config = { attributes: true, childList: true, characterData: true }

observer.observe(speedTarget, config);
observer.observe(uploadTarget, config);
"""

public struct FastManager {
    
    public enum Action: Equatable {
        case didReceive(message: WKScriptMessage)
    }
    
    var create: (AnyHashable) -> Effect<Action, Never> = { _ in _unimplemented("create") }
    
    var destroy: (AnyHashable) -> Effect<Never, Never> = { _ in _unimplemented("destroy") }
    
    var startTest: (AnyHashable) -> Effect<Never, Never> = { _ in _unimplemented("startTest") }
    
    public func create(id: AnyHashable, queue: DispatchQueue? = nil, options: [String : Any]? = nil) -> Effect<Action, Never> {
        self.create(id)
    }
    
    public func destroy(id: AnyHashable) -> Effect<Never, Never> {
        self.destroy(id)
    }
    
    public func startTest(id: AnyHashable) -> Effect<Never, Never> {
        self.startTest(id)
    }
}

// MARK: - Implementation

extension FastManager {
    
    public static let live: FastManager = { () -> FastManager in
        var manager = FastManager()
        
        manager.create = { id in
            Effect.run { subscriber in
                let delegate = FastManagerDelegate(subscriber)
                let userContent = WKUserContentController()
                let config = WKWebViewConfiguration()
                let userScript = WKUserScript(source: source,
                                              injectionTime: .atDocumentEnd,
                                              forMainFrameOnly: true)
                userContent.addUserScript(userScript)
                userContent.add(delegate,
                                name: "notification")
                
                config.userContentController = userContent
                let webview = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100),
                                        configuration: config)
                
                dependencies[id] = Dependencies(delegate: delegate,
                                                userContent: userContent,
                                                config: config,
                                                webView: webview,
                                                subscriber: subscriber)
                return AnyCancellable {
                    dependencies[id] = nil
                }
            }
        }
        
        manager.destroy = { id in
            .fireAndForget {
                dependencies[id]?.subscriber.send(completion: .finished)
                dependencies[id] = nil
            }
        }
        
        manager.startTest = { id in
            .fireAndForget {
                dependencies[id]?.webView.load(URLRequest(url: URL(string: "https://fast.com")!))
            }
        }
        return manager
    }()
}

// MARK: - Dependencies

private struct Dependencies {
    let delegate: FastManagerDelegate
    let userContent: WKUserContentController
    let config: WKWebViewConfiguration
    let webView: WKWebView
    let subscriber: Effect<FastManager.Action, Never>.Subscriber
}

private var dependencies: [AnyHashable: Dependencies] = [:]

// MARK: - Delegate

private class FastManagerDelegate: NSObject, WKScriptMessageHandler {
    let subscriber: Effect<FastManager.Action, Never>.Subscriber
    
    init(_ subscriber: Effect<FastManager.Action, Never>.Subscriber) {
        self.subscriber = subscriber
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        subscriber.send(.didReceive(message: message))
    }
}

// MARK: - Mock

extension FastManager {
    public static func mock() -> Self { Self() }
}

// MARK: - Unimplemented

public func _unimplemented(
    _ function: StaticString, file: StaticString = #file, line: UInt = #line
) -> Never {
    fatalError(
        """
    `\(function)` was called but is not implemented. Be sure to provide an implementation for
    this endpoint when creating the mock.
    """,
        file: file,
        line: line
    )
}
