//
//  ContentView.swift
//  Recos
//
//  Created by wenhuan on 2021/7/12.
//

import Foundation
import SwiftUI
import GDPerformanceView_Swift

struct ContentView : View {
    
    var dataSource = DefaultRecosDataSource()
    var dictList: Array<[String : Any]> = []
    
    init() {
        var array: Array<[String : Any]> = []
        for index in 1...1000 {
            let rankInfo = [ "rankText": "排行榜第" + String(index), "rankUrl": "https://upload-images.jianshu.io/upload_images/5632003-7f62fae2e5b3ffbe.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" ] as [String : Any]
            let itemInfo = ["imgUrl": "https://img1.baidu.com/it/u=413643897,2296924942&fm=253&fmt=auto&app=138&f=JPEG?w=800&h=500", "itemTitle": "这是商品标题" + String(index), "itemSalesDesc": "这是销售描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述", "itemRankInfo": rankInfo ] as [String : Any]
            let relationItemInfoList = [ itemInfo ]
            let myDictionary = ["ratio": 1, "relationItemInfoList": relationItemInfoList] as [String : Any]
            array.append(myDictionary)
        }
        dictList = array
    }
    
    var body: some View {
        NavigationView {
            LazyVStack {
//                NavigationLink(destination: EvalView(bundleName: "differentHeight", moduleName: "HelloWorld")) {
//                    Text("ListView: have different style, can click")
//                }
//                NavigationLink(destination: EvalView(bundleName: "selectFriend", moduleName: "SelectFriendLoadView")) {
//                    Text("Select Friend")
//                }
//                NavigationLink(destination: TestLazyStack()) {
//                    Text("Test")
//                }
//                NavigationLink(destination: NavigationLazyView(TestView().onAppear(perform: testLog))) {
//                    Text("tk view Test")
//                }
//                NavigationLink(destination: TestLogicView().onAppear(perform: testLog)) {
//                    Text("tk logic Test")
//                }
                
                let rankInfo = [ "rankText": "排行榜第一", "rankUrl": "https://upload-images.jianshu.io/upload_images/5632003-7f62fae2e5b3ffbe.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" ] as [String : Any]
                let itemInfo = ["imgUrl": "https://img1.baidu.com/it/u=413643897,2296924942&fm=253&fmt=auto&app=138&f=JPEG?w=800&h=500", "itemTitle": "这是商品标题", "itemSalesDesc": "这是销售描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述描述", "itemRankInfo": rankInfo ] as [String : Any]
                let relationItemInfoList = [ itemInfo ]
                let myDictionary = ["ratio": 1, "relationItemInfoList": relationItemInfoList] as [String : Any]
                
                NavigationLink(destination: TestImageView()) {
                    Text("提前唤醒网络弹窗")
                }
                
                NavigationLink(destination: TestFeedCard(dictionary: myDictionary).onAppear(perform: testLog)) {
                    Text("feed card")
                }
                .simultaneousGesture(TapGesture().onEnded {
//                    print("开始时间", Date().timeIntervalSince1970)
                            })
                
                NavigationLink(destination: TestFeedCardList(dictList: self.dictList).onAppear(perform: testLog)) {
                    Text("feed card list")
                }
                .simultaneousGesture(TapGesture().onEnded {
//                    print("开始时间", Date().timeIntervalSince1970)
                            })
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text("Recos"), displayMode: .large)
        }
    }
    
    func testLog() {
        print("结束时间", Date().timeIntervalSince1970)
    }
    
}

class ParseManager {
    
    static let shared = ParseManager()
    
    private init() {}
    
    var parseMap: [String : DefaultRecosDataSource] = [:]
    
    public func parse(bundleName: String) {
        let dataSource = DefaultRecosDataSource()
        dataSource.parse(bundleName: bundleName)
        self.parseMap[bundleName] = dataSource
    }
    
    public func getDataSouce(bundleName: String) -> DefaultRecosDataSource {
        return self.parseMap[bundleName] ?? DefaultRecosDataSource()
    }
}

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}

struct TestBigView : View {

    var body: some View {
        TestView()
        TestView()
        TestView()
        TestView()
        TestView()
        TestView()
        TestView()
        TestView()
        TestView()
    }
}

struct TestView : View {
    
    var body: some View {
        EvalView(dataSource: ParseManager.shared.getDataSouce(bundleName: "viewTest"), moduleName: "Test")
        EvalView(dataSource: ParseManager.shared.getDataSouce(bundleName: "viewTest"), moduleName: "Test")
        EvalView(dataSource: ParseManager.shared.getDataSouce(bundleName: "viewTest"), moduleName: "Test")
        EvalView(dataSource: ParseManager.shared.getDataSouce(bundleName: "viewTest"), moduleName: "Test")
        EvalView(dataSource: ParseManager.shared.getDataSouce(bundleName: "viewTest"), moduleName: "Test")
        EvalView(dataSource: ParseManager.shared.getDataSouce(bundleName: "viewTest"), moduleName: "Test")
    }
}

struct TestImageView : View {
    
    var body: some View {
        AsyncImage(url: URL(string: "https://img1.baidu.com/it/u=1960110688,1786190632&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=281"))
    }
}

struct TestFeedCard : View {
    var myDictionary: [String : Any] = [:]
    
    init(dictionary: [String : Any]) {
        self.myDictionary = dictionary
    }
 
    var body: some View {
        EvalView(bundleName: "feedCard", moduleName: "feedCard", entryData: self.myDictionary)
    }
}

struct TestFeedCardList : View {
    var dictList: Array<[String : Any]> = []
    
    init(dictList: Array<[String : Any]>) {
        self.dictList = dictList
    }
 
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(0..<self.dictList.count) { index in
                    let model = self.dictList[index]
                    EvalView(bundleName: "feedCard", moduleName: "feedCard", entryData: model)
                }
            }
        }
    }
}

struct TestLazyModel {
    let title: String
    let index: Int
    let value: Float
    
    public func getText() -> String {
        var text:String = ""
        text.append(self.title)
        text.append("item ")
        text.append(String(self.index))
        text.append(" ")
        text.append(String(self.value))
        return text
    }
}

struct TestLazyStack : View {
    var data: [TestLazyModel] = []
    
    init() {
        for i in 0...20000 {
            var title: String = ""
            if i % 2 == 0 {
                title = "偶数: "
            } else {
                title = "奇数: "
            }
            let model = TestLazyModel(title: title, index: i, value: Float(0))
            self.data.append(model)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(0..<self.data.count) { index in
                    let model = self.data[index]
                    Text(model.getText()).foregroundColor(Color.red).padding(10)
                    EvalImage(url: "https://wehear-1258476243.file.myqcloud.com/hemera/cover/59d/7f2/t9_5b8a0600339149c4ea55001b0f.png", placeholder: "placeholder", width: 36, height: 36, borderRadius: 18)
                }
            }
        }
    }
}
                 
