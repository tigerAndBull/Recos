//
//  DefaultRecosDataSource.swift
//  Example
//
//  Created by tigerAndBull on 2021/6/12.
//  Copyright © 2021 tigerAndBull. All rights reserved.
//

import Foundation
import SwiftyJSON

class DummyRecosDataSource: RecosDataSource {
    func parse(bundleName: String) {
    }
    
    func getModel(moduleName: String) -> [String : Any]? {
        return nil
    }
    
    func getExitModule(moduleName: String) -> [String : Any]? {
        return nil
    }
    
    var scope: JsScope?
    init(scope: JsScope?) {
        self.scope = scope
    }
}

class BundleNodesManager {
    
    static let shared = BundleNodesManager()
    
    private init() {}
    
    private var cachedBundleNodes: [String : [[String : Any]]] = [:]
    
    public func cachedParseNodes(bundleName: String, nodes: [[String : Any]]) {
        self.cachedBundleNodes[bundleName] = nodes
    }
    
    public func getParseNodes(bundleName: String) -> [[String : Any]]? {
        return self.cachedBundleNodes[bundleName]
    }
}

class DefaultRecosDataSource: RecosDataSource {
    private var waitingChannel: NSMutableDictionary? = nil
    private var loadedBundle: [String]?
    private var bundleProvider: BundleProvider
    private var dummyJsEvaluator: JsEvaluator?
    private var globalStackFrame: JsStackFrame?
    var rootScope: JsScope?
    
    private var cachedBundleNodes: [String : Any] = [:]
    
    init() {
        self.waitingChannel = NSMutableDictionary()
        self.loadedBundle = []
        self.bundleProvider = AssetBundleProvider.init()
        self.globalStackFrame = JsStackFrame(parentScope: nil)
        self.dummyJsEvaluator = JsEvaluator(dataSource: DummyRecosDataSource(scope: globalStackFrame?.scope))
        self.rootScope = self.globalStackFrame?.scope
    }
    
    func parse(bundleName: String) {
//        let nodes = BundleNodesManager.shared.getParseNodes(bundleName: bundleName)
//        if let nodes = nodes {
//            for node in nodes {
//                self.dummyJsEvaluator?.runNode(frame: globalStackFrame!, scope: rootScope!, node: node)
//            }
//            return
//        }
        var startDate = Date().timeIntervalSince1970
        var endDate = 0.0
        print("anwenhu 阶段 读取bundle转string 开始", startDate)
        let text: String = bundleProvider.getBundleContent(bundleName: bundleName)
        endDate = Date().timeIntervalSince1970
        print("anwenhu 阶段 读取bundle转string 结束", endDate, endDate - startDate)
        
        startDate = endDate
        print("anwenhu 阶段 string转json 开始", startDate)
        if let data = text.data(using: .utf8) {
            do {
                let jsons = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                endDate = Date().timeIntervalSince1970
                print("anwenhu 阶段 string转json 结束", endDate, endDate - startDate)
                for json in jsons as! [[String : Any]] {
                    self.dummyJsEvaluator?.runNode(frame: globalStackFrame!, scope: rootScope!, node: json)
                }
//                BundleNodesManager.shared.cachedParseNodes(bundleName: bundleName, nodes: jsons)
                startDate = endDate
                endDate = Date().timeIntervalSince1970
                print("anwenhu 阶段 runNode 结束", endDate, endDate - startDate)
            } catch {
                print(String(format: "Recos can not parse the bundle named %@", bundleName))
            }
        }
    }
    
    func getModel(moduleName: String) -> [String : Any]? {
        let function = rootScope?.getFunction(name: moduleName)
        if function != nil {
            return function
        }
        return nil
    }
    
    func getExitModule(moduleName: String) -> [String : Any]? {
        return rootScope?.getFunction(name: moduleName)
    }
}
