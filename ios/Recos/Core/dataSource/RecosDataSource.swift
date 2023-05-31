//
//  RecosDataSource.swift
//  Example
//
//  Created by tigerAndBull on 2021/6/8.
//  Copyright © 2021 tigerAndBull. All rights reserved.
//

import Foundation
import SwiftyJSON

public protocol RecosDataSource {
    func parse(bundleName: String) -> Void
    func getModel(moduleName: String) -> [String : Any]?
    func getExitModule(moduleName: String) -> [String : Any]?
}
