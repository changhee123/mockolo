
//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import SourceKittenFramework


typealias ProtocolMapEntryType = (structure: Structure, file: File, models: [Model], attributes: [String])

extension File {
    func lines(starting keyword: String) -> [String] {
        let imports = lines.filter { (line: Line) -> Bool in
            return line.content.trimmingCharacters(in: CharacterSet.whitespaces).starts(with: keyword)
            }.map { (line: Line) -> String in
                return line.content
        }
        return imports
    }
}

extension String {
    static let `static` = "static"
    static let `import` = "import "
    static let `class` = "class"
    static let override = "override"
    static let mockType = "protocol"
    static let any = "Any"
    static let anyObject = "AnyObject"
    static let fatalError = "fatalError"
    static let observableVarPrefix = "Observable<"
    static let rxObservableVarPrefix = "RxSwift.Observable<"
    static let publishSubjectPrefix = "PublishSubject"
    static let observableEmpty = "Observable.empty()"
    static let subjectSuffix = "Subject"
    static let underlyingVarPrefix = "underlying"
    static let callCountSuffix = "CallCount"
    static let closureVarSuffix = "Handler"
    static let initializerPrefix = "init("
    static public let mockAnnotation = "@CreateMock"
    static public let poundIfMock = "#if MOCK"
    static public let poundEndIf = "#endif"
    static public let headerDoc = """
//  Copyright © Uber Technologies, Inc. All rights reserved.
//
//  @generated by SwiftMockGen
//  swiftlint:disable custom_rules

"""

    var capitlizeFirstLetter: String {
        return prefix(1).capitalized + dropFirst()
    }
    func shouldParse(with exclusionList: [String]? = nil) -> Bool {
        guard hasSuffix(".swift") else { return false }
        if let filtered = exclusionList?.filter ({
            return components(separatedBy: ".swift").first?.hasSuffix($0) ?? false
        }) {
            return filtered.count == 0
        }
        return false
    }
    
    var displayableComponents: [String] {
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted)
    }
    
    var displayableForType: String {
        return displayableComponents.map{$0 == UnknownVal ? "" : $0.capitlizeFirstLetter}.joined()
    }
}

extension Structure {
    func isAnnotated(with annotation: String, in content: String) -> Bool {
        return extractDocComment(content).contains(annotation)
    }
    
    func extractDocComment(_ content: String) -> String {
        let len = dictionary["key.doclength"] as? Int64 ?? 0
        let offset = dictionary["key.docoffset"] as? Int64 ?? -1
        
        return extract(offset: offset, length: len, content: content)
    }
    
    func extractAttributes(_ content: String, filterOn: String? = nil) -> [String] {
        guard let attributeDict = attributes else {
            return []
        }
        
        return attributeDict.compactMap { (attribute: [String: SourceKitRepresentable]) -> String? in
            if let attributeVal = attribute["key.attribute"] as? String {
                if let filterAttribute = filterOn, attributeVal != filterAttribute {
                    return nil
                }
                
                return extract(attribute, from: content)
            }
            return nil
        }
    }
    
    func extract(_ source: [String: SourceKitRepresentable], from content: String) -> String {
        if let offset = source[SwiftDocKey.offset.rawValue] as? Int64,
            let len = source[SwiftDocKey.length.rawValue] as? Int64 {
            
            return extract(offset: offset, length: len, content: content)
        }
        return ""
    }
}


func defaultVal(typeName: String) -> String? {
    // TODO: add more robust handling
    
    if typeName.hasSuffix("?") {
        return "nil"
    }
    
    if typeName.hasPrefix(.observableVarPrefix) || typeName.hasPrefix(.rxObservableVarPrefix) {
        return .observableEmpty
    }
    
    if (typeName.hasPrefix("[") && typeName.hasSuffix("]")) ||
        typeName.hasPrefix("Array") ||
        typeName.hasPrefix("Dictionary") {
        return "\(typeName)()"
    }
    if typeName == "Bool" {
        return "false"
    }
    if typeName == "String" ||
        typeName == "Character" {
        return "\"\""
    }
    
    if typeName == "Int" ||
        typeName == "Int8" ||
        typeName == "Int16" ||
        typeName == "Int32" ||
        typeName == "Int64" ||
        typeName == "Double" ||
        typeName == "CGFloat" ||
        typeName == "Float" {
        return "0"
    }
    return nil
}