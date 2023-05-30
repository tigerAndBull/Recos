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
    
    func getModel(moduleName: String) -> FunctionDecl? {
        return nil
    }
    
    func getExitModule(moduleName: String) -> FunctionDecl? {
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
    
    private var cachedBundleNodes: [String : [Node]] = [:]
    
    public func cachedParseNodes(bundleName: String, nodes: [Node]) {
        self.cachedBundleNodes[bundleName] = nodes
    }
    
    public func getParseNodes(bundleName: String) -> [Node]? {
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
        let nodes = BundleNodesManager.shared.getParseNodes(bundleName: bundleName)
        if let nodes = nodes {
            for node in nodes {
                self.dummyJsEvaluator?.runNode(frame: globalStackFrame!, scope: rootScope!, node: node)
            }
            return
        }
        
        print("anwenhu 阶段 读取bundle转string 开始", Date().timeIntervalSince1970)
        let text: String = bundleProvider.getBundleContent(bundleName: bundleName)
        print("anwenhu 阶段 读取bundle转string 结束", Date().timeIntervalSince1970)
        
        print("anwenhu 阶段 string转json 开始", Date().timeIntervalSince1970)
        if let data = text.data(using: .utf8) {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                let json = JSON(jsonObject)
                print("anwenhu 阶段 string转json 结束", Date().timeIntervalSince1970)
                var nodes = [Node]()
                for (_, item):(String, JSON) in json {
                    let node = Node(json: item)
                    if node != nil {
                        nodes.append(node!)
                    }
                }
                print("anwenhu 阶段 json转node 转换", Date().timeIntervalSince1970)
                for node in nodes {
                    self.dummyJsEvaluator?.runNode(frame: globalStackFrame!, scope: rootScope!, node: node)
                }
                BundleNodesManager.shared.cachedParseNodes(bundleName: bundleName, nodes: nodes)
                print("anwenhu 阶段 json转node 结束", Date().timeIntervalSince1970)
            } catch {
                print(String(format: "Recos can not parse the bundle named %@", bundleName))
            }
        }
    }
    
    func getModel(moduleName: String) -> FunctionDecl? {
        let function = rootScope?.getFunction(name: moduleName)
        if function != nil {
            return function
        }
        return nil
    }
    
    func getExitModule(moduleName: String) -> FunctionDecl? {
        return rootScope?.getFunction(name: moduleName)
    }
}
