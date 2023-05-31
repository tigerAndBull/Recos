//
//  SwiftUIJsEvaluator.swift
//  Example
//
//  Created by tigerAndBull on 2021/5/26.
//  Copyright © 2021 tigerAndBull. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftUI
import CachedAsyncImage

class JsEvaluator {
    var dataSource: RecosDataSource
    var rootScope = JsScope(parentScope: nil)
    
    init(dataSource: RecosDataSource) {
        self.dataSource = dataSource
    }
    
    func getArgs(nodes: [JSON], index: Int) -> [String : Any]? {
        var result: [String : Any] = [:]
        nodes.forEach { node in
            if node["type"].int == TYPE_EXPR_ID {
                let name = node["content"]["name"].string
                result[name!] = index
            }
        }
        return result
    }
    
    func getJsValue(obj: Any?) -> Any? {
        if obj is JsVariable {
            return (obj as! JsVariable).getValue()
        } else if obj is JsMember {
            return (obj as! JsMember).obj.getMemeber(name: (obj as! JsMember).name)
        }
        return obj
    }
    
    @discardableResult
    func normalEval(functionDecl: JsFunctionDecl,
                    args: [Any]?,
                    selfValue: Any?) -> Any? {
        let frame = JsStackFrame(parentScope: (functionDecl.parentScope != nil) ? functionDecl.parentScope! : rootScope)
        
        for (index, node) in functionDecl.param.enumerated() {
            let idInfo = node["content"]
            frame.scope?.addVar(variable: JsVariable(name: idInfo["name"].string!, kind: VariableKind.VAR, value: args?[index]))
        }
        
        frame.scope?.addVar(variable: JsVariable(name: "this", kind: VariableKind.VAR, value: self))
        let body = functionDecl.body
        runNode(frame: frame, scope: frame.scope!, node: body)
        let ret = frame.returnValue
        return ret
    }
    
    func EvalWithState(functionDecl: JsFunctionDecl,
                       args: [Any]?,
                       recosObserveObject: RecosObservedObject) -> AnyView? {
        var currentStateIndex: Int = -1
        var currentCallbackIndex: Int = -1
        var currentEffectIndex: Int = -1
        let frame = JsStackFrame(parentScope: (functionDecl.parentScope != nil) ? functionDecl.parentScope! : rootScope)
        
        for (index, node) in functionDecl.param.enumerated() {
            let idInfo = node["content"]
            let variable = JsVariable(name: idInfo["name"].string!, kind: VariableKind.VAR, value: args?[index])
            frame.scope?.addVar(variable: variable)
        }
        
        var state = recosObserveObject.state
        var callBack = recosObserveObject.callBack
        var effectList = recosObserveObject.effectList
        
        frame.visitAndGetState = {(defaultValue: Any) -> [Int : Any?] in
            currentStateIndex += 1
            if state.count > currentStateIndex {
                var args: [Int : Any] = [:]
                args[currentStateIndex] = state[currentStateIndex]
                return args
            } else {
                state.append(defaultValue)
                var args: [Int : Any] = [:]
                args[currentStateIndex] = defaultValue
                return args
            }
        }
        
        frame.updateState = {(index: Int, value: Any?) -> Void in
            state[index] = value
            let needUpdateVariable = frame.scope?.getExtraVarWithHeadScope(name: "needUpdate") as? JsVariable
            var needUpdate = false
            if needUpdateVariable != nil {
                needUpdate = needUpdateVariable?.value as! Bool
            }
            recosObserveObject.updateState(value: state, needUpdate: needUpdate)
            if needUpdateVariable != nil {
                needUpdateVariable?.value = false
                frame.scope?.removeExtraVar(name: needUpdateVariable!.name)
            }
        }
        
        frame.visitAndGetCallback = {(defaultValue: JsFunctionDecl) -> JsFunctionDecl in
            currentCallbackIndex += 1
            if callBack.count > currentCallbackIndex {
                return callBack[currentCallbackIndex]
            } else {
                callBack.append(defaultValue)
                return defaultValue
            }
        }
        
        frame.checkAndRunEffect = {(defaultValue: JsFunctionDecl, deps: JsArray) -> Void in
            currentEffectIndex += 1
            if effectList.count > currentEffectIndex {
                let effect = effectList[currentEffectIndex]
                if effect.lastValueList! == deps {
                    effectList[currentEffectIndex] = JsEffect(function: defaultValue, lastValueList: deps)
                    self.normalEval(functionDecl: defaultValue, args: nil, selfValue: nil)
                }
            } else {
                effectList.append(JsEffect(function: defaultValue, lastValueList: deps))
                self.normalEval(functionDecl: defaultValue, args: nil, selfValue: nil)
            }
        }
        
        runNode(frame: frame, scope: frame.scope!, node: functionDecl.body)
        let ret = frame.returnValue
        if ret is RenderElement {
            let render = (ret as! RenderElement).Render()
            print("anwenhu 阶段 逻辑执行结束", NSDate().timeIntervalSince1970)
            return render
        }
        
        return nil
    }
    
    func runNode(frame: JsStackFrame,
                 scope: JsScope,
                 node: JSON) {
        
        if (frame.returnValue is NSNull) == false {
            return
        }
        
        switch node["type"].int {
        case TYPE_DECL_VAR_LIST:
            for (_, item):(String, JSON) in node["content"] {
                if item["type"].int == TYPE_DECL_VAR {
                    let varItem = item["content"]
                    if let kindString = varItem["kind"].string {
                        let kind = VariableKind.init(rawValue: kindString)
                        let value = parseExprValue(value: varItem["init"], frame: frame, scope: scope)
                        let initValue = getJsValue(obj: value)
                        if let nameString = varItem["name"].string {
                            let variable = JsVariable(name: nameString, kind: kind!, value: initValue)
                            if kind == VariableKind.VAR {
                                frame.scope?.addVar(variable: variable)
                            } else {
                                scope.addVar(variable: variable)
                            }
                        }
                    }
                } else if item["type"].int == TYPE_DECL_VAR_ARRAY_PATTERN {
                    let varList = item["content"]
                    let value = parseExprValue(value: varList["init"], frame: frame, scope: scope)
                    let initValue = getJsValue(obj: value)
                    if let kindString = varList["kind"].string {
                        let kind = VariableKind.init(rawValue: kindString)
                        var index = 0
                        for (_, name):(String, JSON) in item["nameList"] {
                            let variable = JsVariable(name: name.string!, kind: kind!, value: (initValue as! JsArray).get(index: index))
                            if kind == VariableKind.VAR {
                                frame.scope?.addVar(variable: variable)
                            } else {
                                scope.addVar(variable: variable)
                            }
                            index += 1
                        }
                    }
                }
            }
            break
        case TYPE_DECL_FUNC:
            scope.addFunction(functionDecl: node["content"])
            break
        case TYPE_STATEMENT_BLOCK:
            let blockScope = JsScope(parentScope: scope)
            for (_, item):(String, JSON) in node["content"] {
                runNode(frame: frame, scope: blockScope, node: item)
            }
            break
        case TYPE_STATEMENT_FOR:
            let forScope = JsScope(parentScope: scope)
            let forStatement = node["content"]
            runNode(frame: frame, scope: forScope, node: forStatement["init"])
            while getJsValue(obj: parseExprValue(value: forStatement["test"], frame: frame, scope: forScope)) as? Bool == true {
                runNode(frame: frame, scope: forScope, node: forStatement["body"])
                runNode(frame: frame, scope: forScope, node: forStatement["update"])
            }
            break
        case TYPE_EXPR_UPDATE:
            parseExprValue(value: node, frame: frame, scope: scope)
            break
        case TYPE_STATEMENT_IF:
            let ifScope = JsScope(parentScope: scope)
            let ifStatement = node["content"]
            if ifStatement["test"] != JSON.null {
                let test = ifStatement["test"]
                let obj = parseExprValue(value: test, frame: frame, scope: ifScope)
                let jsValue = getJsValue(obj: obj)
                // todo
                // if (model) {} 的逻辑解析是否符合预期
                if (test["type"].int == TYPE_EXPR_ID && ifStatement["alternate"] == JSON.null) {
                    if ((jsValue) != nil) {
                        runNode(frame: frame, scope: ifScope, node: ifStatement["consequent"])
                    }
                }
                if jsValue as? Bool == true {
                    runNode(frame: frame, scope: ifScope, node: ifStatement["consequent"])
                } else {
                    if ifStatement["alternate"] != JSON.null {
                        runNode(frame: frame, scope: ifScope, node: ifStatement["alternate"])
                    }
                }
            }
            break
        case TYPE_STATEMENT_RETURN:
            let arg = node["content"]
            frame.returnValue = getJsValue(obj: parseExprValue(value: arg, frame: frame, scope: scope))
            break
        case TYPE_STATEMENT_EXPR:
            parseExprValue(value: node["content"], frame: frame, scope: scope)
            break
        default:
            break
        }
    }
    
    func toJSFunctionDecl(scope: JsScope, funcJSON: JSON, type: Int) -> JsFunctionDecl {
        var params = [JSON]()
        for (_, item):(String, JSON) in funcJSON["params"] {
            params.append(item)
        }
        if type == TYPE_EXPR_ARRAY_FUNCTION {
            return JsFunctionDecl(name: "FunctionArrayExpr", param: params, body: funcJSON["body"], parentScope: scope, isRecosComponent: false)
        }
        return JsFunctionDecl(name: "FunctionExpr", param: params, body: funcJSON["body"], parentScope: scope, isRecosComponent: false)
    }
    
    @discardableResult
    func parseExprValue(value: JSON, frame: JsStackFrame, scope: JsScope) -> Any? {

        if value == JSON.null {
            return nil
        }
        
        let content = value["content"]
        let type = value["type"].int ?? 0

        if type == TYPE_LITERAL_STR {
            return content["value"].string
        }else if(type == TYPE_LITERAL_NUM) {
            let value = content["value"].int
            return value
        }else if(type == TYPE_EXPR_FUNCTION) {
            return toJSFunctionDecl(scope: scope, funcJSON: content, type: type)
        }else if(type == TYPE_EXPR_ARRAY_FUNCTION) {
            return toJSFunctionDecl(scope: scope, funcJSON: content, type: type)
        }else if(type == TYPE_EXPR_ARRAY) {
            let ret = JsArray()
            let nodeArray = content
            for (_, item):(String, JSON) in nodeArray {
                let it = getJsValue(obj: parseExprValue(value: item, frame: frame, scope: scope))
                ret.push(item: it)
            }
            return ret
        }else if(type == TYPE_EXPR_BINARY) {
            return binaryCalculate(scope: scope, binaryData: content, frame: frame)
        }else if(type == TYPE_EXPR_UNARY) {
            return unaryCalculate(scope: scope, unaryData: content, frame: frame)
        }else if(type == TYPE_EXPR_ID){
            let name = content["name"].string!
            // todo bridge切出来
            switch name {
            case "console":
                return JsConsole()
            case "Math":
                return JsMath()
            case "useState":
                let object = NativeMemberInvoker { args in
                    let statusValue = frame.visitAndGetState!(args?[0]!) as [Int : Any]
                    let index = Array(statusValue.keys)[0]
                    let array = JsArray()
                    array.push(item: statusValue[0])
                    let invoker = NativeMemberInvoker { args in
                        frame.updateState!(index, args?[0]!)
                    }
                    array.push(item: invoker)
                    return array
                }
                return object
            case "useCallback":
                var callBack : JsFunctionDecl?
                let object = NativeMemberInvoker { args in
                    callBack = frame.visitAndGetCallback!(args?[0]! as! JsFunctionDecl)
                    return callBack
                }
                return object
            case "useEffect":
                let object = NativeMemberInvoker { args in
                    let function = args?[0] as! JsFunctionDecl
                    let jsArray = args?[1] as! JsArray
                    frame.checkAndRunEffect!(function, jsArray)
                    return nil
                }
                return object
            default:

                let variable = scope.getVar(variable: name)
                if variable != nil {
                    return variable
                }
                
                if let funcJSON = scope.getFunction(name: name) {
                    return toJSFunctionDecl(scope: scope, funcJSON: funcJSON, type: type)
                }
                
                return nil
            }
        } else if(type == TYPE_EXPR_OBJECT) {
            let obj = JsObject()
            for (_, property):(String, JSON) in content {
                var key: Any?
                let keyNode = property["key"]
                if property["computed"].boolValue {
                    key = getJsValue(obj: parseExprValue(value: keyNode, frame: frame, scope: scope))
                } else {
                    let keyNodeType = keyNode["type"].int
                    if keyNodeType == TYPE_EXPR_ID {
                        let idInfo = keyNode["content"]
                        key = idInfo["name"].string
                    } else if keyNodeType == TYPE_LITERAL_STR {
                        let stringLiteral = keyNode["content"]
                        key = stringLiteral["value"].string
                    } else if keyNodeType == TYPE_LITERAL_NUM {
                        let numLiteral = keyNode["content"]
                        key = numLiteral["value"].int
                    }
                }
                let pValue = getJsValue(obj: parseExprValue(value: property["value"], frame: frame, scope: scope))
                if (key != nil) {
                    obj.setValue(variable: key as! String, value: pValue)
                }
            }
            return obj
        } else if(type == TYPE_EXPR_CALL) {
            let callExpr = content
            let callee = getJsValue(obj: parseExprValue(value: callExpr["callee"], frame: frame, scope: scope))

            var arguments = [Any?]()
            for (_, item):(String, JSON) in callExpr["arguments"] {
                arguments.append(getJsValue(obj: parseExprValue(value: item, frame: frame, scope: scope)))
            }
            
            if callee is NativeMemberInvoker {
                let invoker = callee as! NativeMemberInvoker
                return invoker.call(args: arguments)
            } else if callee is JsMember {
                let callMember = (callee as! JsMember)
                let jsMember = callMember.obj.getMemeber(name: callMember.name)
                if jsMember is NativeMemberInvoker {
                    return (jsMember as! NativeMemberInvoker).call(args: arguments)
                } else {
                    let functionDecl = jsMember as! JsFunctionDecl
                    return normalEval(functionDecl: functionDecl, args: arguments as [Any], selfValue: nil)
                }
            } else if callee is JsFunctionDecl {
                if (callee as! JsFunctionDecl).isRecosComponent {
                    return FunctionDeclRenderElement(jsEvaluator: self, functionDecl: callee as! JsFunctionDecl, args: arguments as [Any])
                } else {
                    return normalEval(functionDecl: callee as! JsFunctionDecl, args: arguments as [Any], selfValue: nil)
                }
            }
            return callee
            
        } else if(type == TYPE_EXPR_MEMBER) {
            let memberExpr = content
            let exprValue = parseExprValue(value: memberExpr["object"], frame: frame, scope: scope)
            let obj = getJsValue(obj: exprValue)
            let computed = memberExpr["computed"].boolValue
            let property = memberExpr["property"]
            if obj is MemberProvider {
                return parseMember(obj: obj as! MemberProvider, computed: computed, value: property, scope: scope, frame: frame)
            } else if obj is JsVariable {
                let object = obj as! JsVariable
                let targetArray = JsArray()
                targetArray.push(item: object)
                targetArray.memberSetter(name: "0")(object)
                return parseMember(obj: targetArray, computed: computed, value: property, scope: scope, frame: frame)
            } else if obj is Array<Any> {
                let targetArray = JsArray()
                targetArray.list = obj as! Array<Any>
//                targetArray.memberSetter(name: "0")(obj)
                return parseMember(obj: targetArray, computed: computed, value: property, scope: scope, frame: frame)
            } else if obj is [String : Any?] {
                let jsObject = JsObject()
                jsObject.fields = obj as! [String : Any?]
                jsObject.isEntryObject = true
                return parseMember(obj: jsObject, computed: computed, value: property, scope: scope, frame: frame)
            }
            return obj
        } else if(type == TYPE_EXPR_UPDATE) {
            let updateExpr = content
            let argument = updateExpr["argument"]
            let argumentName = argument["content"]
            let variable = scope.getVar(variable: argumentName["name"].string!) as! JsVariable
            let cv = variable.getValue()
            var intCV = Int(0)
            if cv is Float {
                intCV = Int(cv as! Float)
            }else {
                intCV = cv as! Int
            }
            let currentValue: Int = intCV
            var nextValue: Int = currentValue
            switch updateExpr["operator"].string {
                case "++":
                    nextValue += 1
                case "--":
                    nextValue -= 1
                default:
                    nextValue += 1
            }
            variable.updateValue(value: nextValue)
            if updateExpr["prefix"].boolValue {
                return Float(nextValue)
            } else {
                return Float(currentValue)
            }
        } else if(type == TYPE_EXPR_ASSIGN) {
            let assignExpr = content
            let rightValue = getJsValue(obj: parseExprValue(value: assignExpr["right"], frame: frame, scope: scope))
            let leftValue = parseExprValue(value: assignExpr["left"], frame: frame, scope: scope)
            if assignExpr["operator"].string == "=" {
                if leftValue is JsVariable {
                    let leftValue = leftValue as! JsVariable
                    leftValue.updateValue(value: rightValue)
                } else if leftValue is JsMember {
                    let leftMember = leftValue as! JsMember
                    (leftMember.obj.memberSetter(name: leftMember.name))(rightValue)
                }
            }
            return rightValue
        } else if(type == TYPE_EXPR_EXPRESSION) {
            let sequenceExpr = content
            let jsObject = JsObject()
            
            for (_, it):(String, JSON) in sequenceExpr["expression"] {
                let value = parseExprValue(value: it, frame: frame, scope: scope) as! JsObject
                value.fields.forEach { it in
                    jsObject.setValue(variable: it.key, value: it.value)
                }
            }
            return jsObject
        } else if(type == TYPE_JSX_ELEMENT) {
            let jsxElement = content
            var props = [String : Any?]()
            for (_, prop):(String, JSON) in jsxElement["prop"] {
                props[prop["name"].string!] = getJsValue(obj: parseExprValue(value: prop["value"], frame: frame, scope: scope))
            }
            var elementArray = [RenderElement]()
            for (_, node):(String, JSON) in jsxElement["children"] {
                switch node["type"].int {
                    case TYPE_JSX_ELEMENT:
                        elementArray.append(parseExprValue(value: node, frame: frame, scope: scope) as! RenderElement)
                        break
                    case TYPE_JSX_TEXT:
                        elementArray.append(JsxValueRenderElement(value: node["content"]))
                        break
                    default:
                        elementArray.append(JsxValueRenderElement(value: getJsValue(obj:parseExprValue(value: node, frame: frame, scope: scope))))
                }
            }
            return JsxRenderElement(jsEvaluator: self, name: jsxElement["name"].string!, props: props as [String : Any], children: elementArray)
        }
        assert(false, "can not support this type")
    }
    
    func parseMember(obj: MemberProvider, computed: Bool, value: JSON, scope: JsScope, frame: JsStackFrame) -> JsMember? {
        if computed {
            let result = parseExprValue(value: value, frame: frame, scope: scope)
            let name = getJsValue(obj: result)
            if name != nil {
                var string = ""
                if name is Float {
                    string = String(Int(name as! Float))
                } else if name is Int {
                    string = String(name as! Int)
                }
                return JsMember(obj: obj, name: string)
            }
        } else if value["type"].int == TYPE_EXPR_ID {
            let idInfo = value["content"]
            if let nameString = idInfo["name"].string {
                return JsMember(obj: obj, name: nameString)
            }
        }
        return nil
    }
    
    func findKeyForNestDict(name: String, dict: [String : Any?]) -> Any? {
        var result: Any? = nil;
        if dict.isEmpty {
            return result
        }
        dict.forEach { (key: String, value: Any?) in
            if name == key {
                result = value
            } else if value is Array<[String : Any?]> {
                let array = value as! Array<[String : Any?]>
                array.forEach { item in
                    result = findKeyForNestDict(name: name, dict: item)
                }
            } else if value is [String : Any?] {
                result = findKeyForNestDict(name: name, dict: value as! [String : Any?])
            }
        }
        return result
    }
    
    func unaryCalculate(scope: JsScope, unaryData: JSON, frame: JsStackFrame) -> Any? {
        switch unaryData["operator"].string {
        case "!":
            let obj = parseExprValue(value: unaryData["argument"], frame: frame, scope: scope)
            return ((getJsValue(obj: obj) != nil) != true)
        default:
            return nil
        }
    }
    
    func binaryCalculate(scope: JsScope, binaryData: JSON, frame: JsStackFrame) -> Any? {
        var leftValue = getJsValue(obj: parseExprValue(value: binaryData["left"], frame: frame, scope: scope))
        var rightValue: Any?
        if binaryData["right"] != JSON.null {
            rightValue = getJsValue(obj: parseExprValue(value: binaryData["right"], frame: frame, scope: scope))
        }
        let operatorString = binaryData["operator"].string!
        switch operatorString {
        case "+":
            if leftValue is String && rightValue is String {
                return (leftValue as! String) + (rightValue as! String)
            } else if leftValue is String {
                if rightValue == nil {
                    return (leftValue as! String)
                }
                if rightValue is Int {
                    return (leftValue as! String) + String(rightValue as! Int)
                }
                return (leftValue as! String) + String(rightValue as! Float)
            } else if rightValue is String {
                if leftValue == nil {
                    return (rightValue as! String)
                }
                if leftValue is Int {
                    return String(leftValue as! Int) + (rightValue as! String)
                }
                return String(leftValue as! Float) + (rightValue as! String)
            } else {
                if leftValue is Int {
                    let value = Float((leftValue as! Int)) + (rightValue as! Float)
                    return value
                }
                let value = (leftValue as! Float) + (rightValue as! Float)
                return value
            }
        case "-":
            if leftValue is Int && rightValue is Int {
                return (leftValue as! Int) - (rightValue as! Int)
            }
            if leftValue is Float && rightValue is Int {
                return leftValue as! Float - Float((rightValue as! Int))
            }
            if leftValue is Int && rightValue is Float {
                return Float((leftValue as! Int)) - (rightValue as! Float)
            }
            return (leftValue as! Float) - (rightValue as! Float)
        case "*":
            if (leftValue == nil) {
                return 0
            }
            if leftValue is Int && rightValue is Int {
                return (leftValue as! Int) * (rightValue as! Int)
            }
            if leftValue is Float && rightValue is Int {
                return leftValue as! Float * Float((rightValue as! Int))
            }
            if leftValue is Int && rightValue is Float {
                return Float((leftValue as! Int)) * (rightValue as! Float)
            }
            return (leftValue as! Float) * (rightValue as! Float)
        case "/":
            if rightValue == nil {
                assert(false, "nan")
            }
            if leftValue is Int && rightValue is Int {
                return (leftValue as! Int) / (rightValue as! Int)
            }
            if leftValue is Float && rightValue is Int {
                return leftValue as! Float / Float((rightValue as! Int))
            }
            if leftValue is Int && rightValue is Float {
                return Float((leftValue as! Int)) / (rightValue as! Float)
            }
            return (leftValue as! Float) / (rightValue as! Float)
        case "%":
            var left: Int = 0
            var right: Int = 0
            var result: Int = 0
            if leftValue is Float {
                left = Int((leftValue as! Float))
            }else {
                left = (leftValue as! Int)
            }
            if rightValue is Float {
                right = Int((rightValue as! Float))
            }else {
                right = (rightValue as! Int)
            }
            result = left % right
            return result
        case ">":
            if leftValue is String && (rightValue is Int) {
                if leftValue != nil {
                    return true
                }
                return false
            }
            if leftValue is Float && rightValue is Float {
                return (leftValue as! Float) > (rightValue as! Float)
            }
            if leftValue is Float && rightValue is Int {
                return (leftValue as! Float) > Float((rightValue as! Int))
            }
            if leftValue is Int && rightValue is Int {
                return (leftValue as! Int) > (rightValue as! Int)
            }
            return Float(leftValue as! Int) > (rightValue as! Float)
        case ">=":
            return (leftValue as! Float) >= (rightValue as! Float)
        case "<":
            if leftValue == nil {
                leftValue = 0
            }
            if leftValue is Float && rightValue is Float {
                return (leftValue as! Float) < (rightValue as! Float)
            }
            if leftValue is Float && rightValue is Int {
                return (leftValue as! Float) < Float((rightValue as! Int))
            }
            if leftValue is Int && rightValue is Int {
                return (leftValue as! Int) < (rightValue as! Int)
            }
            return Float(leftValue as! Int) < (rightValue as! Float)
        case "<=":
            if leftValue == nil {
                leftValue = 0
            }
            if leftValue is Float && rightValue is Float {
                return (leftValue as! Float) <= (rightValue as! Float)
            }
            if leftValue is Float && rightValue is Int {
                return (leftValue as! Float) <= Float((rightValue as! Int))
            }
            if leftValue is Int && rightValue is Float {
                return Float((leftValue as! Int)) <= (rightValue as! Float)
            }
            if leftValue is Int && rightValue is Int {
                return (leftValue as! Int) <= (rightValue as! Int)
            }
            return Float(leftValue as! Int) <= (rightValue as! Float)
        case "==":
            if leftValue == nil && rightValue == nil {
                print("命中========")
                return false
            }
            if let _ = leftValue,
               rightValue == nil {
                return false
            }
            if leftValue is Int && rightValue is Float {
                return (leftValue as! Int) == Int(rightValue as! Float)
            }
            if leftValue is Int && rightValue is Int {
                return (leftValue as! Int) == (rightValue as! Int)
            }
            if leftValue is Float && rightValue is Int {
                return Int((leftValue as! Float)) == (rightValue as! Int)
            }
            return (leftValue as! Float) == (rightValue as! Float)
        case "===":
            if leftValue is String && rightValue is String {
                return leftValue as! String == rightValue as! String
            }
            if leftValue is Int && rightValue is Float {
                return (leftValue as! Int) == Int(rightValue as! Float)
            }
            if leftValue is Int && rightValue is Int {
                return (leftValue as! Int) == (rightValue as! Int)
            }
            if leftValue is Float && rightValue is Int {
                return Int((leftValue as! Float)) == (rightValue as! Int)
            }
            return (leftValue as! Float) == (rightValue as! Float)
        case "!=":
            if rightValue == nil  {
                if leftValue != nil {
                    return true
                } else {
                    return false
                }
            }
            return (leftValue as! Float) != (rightValue as! Float)
        case "&&":
            return (leftValue as! Bool) && (rightValue as! Bool)
        case "||":
            return (leftValue as! Bool) || (rightValue as! Bool)
            // todo 其他表达式
//        case "&":
//            if leftValue is Int && rightValue is Float {
//                return (leftValue as! Int) & Int(rightValue as! Float)
//            }
//            if leftValue is Int && rightValue is Int {
//                return (leftValue as! Int) & (rightValue as! Int)
//            }
//            if leftValue is Float && rightValue is Int {
//                return Int((leftValue as! Float)) & (rightValue as! Int)
//            }
//            return (leftValue as! Float) & (rightValue as! Float)
////            return leftUsed & rightUsed
//            return 0
//        case "|":
//            return (leftValue as! Bool) | (rightValue as! Bool)
//        case "^":
////            return leftUsed ^ rightUsed
//            return 0
        default:
            assert(false, "not support" + operatorString)
        }
    }
    
    func toDictionary(string: String) -> [String : Any] {
        var result = [String : Any]()
        guard !string.isEmpty else { return result }
        
        guard let dataSelf = string.data(using: .utf8) else {
            return result
        }
        
        if let dic = try? JSONSerialization.jsonObject(with: dataSelf,
                           options: .mutableContainers) as? [String : Any] {
            result = dic
        }
        return result
    }
}

struct EvalImage : View {
    @State private var remoteImage : UIImage? = nil
    
    var url: String
    var placeholder: String
    var width: CGFloat = 0
    var height: CGFloat = 0
    var borderRadius: CGFloat = 0
    
    init(url: String, placeholder: String) {
        self.url = url
        self.placeholder = placeholder
    }
    
    init(url: String, placeholder: String, width: CGFloat, height: CGFloat) {
        self.url = url
        self.placeholder = placeholder
        self.width = width
        self.height = height
    }
    
    init(url: String, placeholder: String, width: CGFloat, height: CGFloat, borderRadius: CGFloat) {
        self.url = url
        self.placeholder = placeholder
        self.width = width
        self.height = height
        self.borderRadius = borderRadius
    }
    
    var body: some View {
        CachedAsyncImage(url: URL(string: self.url)).frame(width: self.width, height: self.height)
            .scaledToFill()
            .cornerRadius(self.borderRadius)
    }
}
    
struct EvalView : View {
    var functionDecl: JsFunctionDecl?
    @State var args: [Any]?
    @State var evaluator: JsEvaluator
    @ObservedObject var recosObserve = RecosObservedObject()
    
    init(bundleName: String, moduleName: String, entryData: [String: Any]? = nil) {
        let defaultRecosDataSource = DefaultRecosDataSource.init()
        defaultRecosDataSource.parse(bundleName: bundleName)
        let function = defaultRecosDataSource.getModel(moduleName: moduleName)
        let jsEvaluator = JsEvaluator(dataSource: defaultRecosDataSource)
        self.evaluator = jsEvaluator
        self.functionDecl = self.toJsFunctionDeclForEntryFunc(scope: defaultRecosDataSource.rootScope, funcJSON: function!, data: entryData)
    }
    
    init(dataSource: DefaultRecosDataSource, moduleName: String) {
        let function = dataSource.getModel(moduleName: moduleName)
        let jsEvaluator = JsEvaluator(dataSource: dataSource)
        self.evaluator = jsEvaluator
        self.functionDecl = self.toJsFunctionDecl(scope: dataSource.rootScope, funcJSON: function!)
    }
    
    init(functionDecl: JsFunctionDecl, args: [Any]?, evaluator: JsEvaluator) {
        self.functionDecl = functionDecl
        self.args = args
        self.evaluator = evaluator
    }
    
    func toJsFunctionDecl(scope: JsScope? = nil, funcJSON: JSON) -> JsFunctionDecl {
        var params = [JSON]()
        for (_, item):(String, JSON) in funcJSON["param"] {
            params.append(item)
        }
        return JsFunctionDecl(name: funcJSON["name"].string!, param: params, body: funcJSON["body"], parentScope: scope, isRecosComponent: false)
    }
    
    func toJsFunctionDeclForEntryFunc(scope: JsScope? = nil, funcJSON: JSON, data: [String : Any]? = nil) -> JsFunctionDecl {
        var params = [JSON]()
        for (_, item):(String, JSON) in funcJSON["param"] {
            params.append(item)
        }
        if params.count > 0 {
            let node = params[0]
            if node["type"].int == TYPE_EXPR_ID {
                let content = node["content"]
                // todo 赋值
                let object = JsObject()
                object.isEntryObject = true
                data?.forEach({ (key: String, value: Any) in
                    object.setValue(variable: key, value: value)
                })
                scope?.addVar(variable: JsVariable(name: content["name"].string!, kind: VariableKind.VAR, value: object))
            }
        }
        return JsFunctionDecl(name: funcJSON["name"].string!, param: params, body: funcJSON["body"], parentScope: scope, isRecosComponent: true)
    }
    
    var body : some View {
        if functionDecl != nil {
            evaluator.EvalWithState(functionDecl: functionDecl!, args: args, recosObserveObject: recosObserve)
        }
    }
}

class RecosObservedObject : ObservableObject {
    @Published var state: [Any?] = []
    @Published var callBack: [JsFunctionDecl] = []
    @Published var effectList: [JsEffect] = []
    
    func removeAllState() -> Void {
        self.state.removeAll()
    }
        
    func updateState(value: [Any?], needUpdate: Bool) -> Void {
        if self.state.count == 0 {
            self.state = value
        }
        if needUpdate {
            self.state = value
        }
    }
    
    func updateState(value: [Any?]) -> Void {
        self.state = value
    }
    
    func updateStateItem(index: Int, value: Any?) -> Void {
        self.state[index] = value
    }
}
