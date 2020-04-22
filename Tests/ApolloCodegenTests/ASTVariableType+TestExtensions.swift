//
//  ASTVariableType+TestExtensions.swift
//  ApolloCodegenTests
//
//  Created by Ellen Shapiro on 4/21/20.
//  Copyright © 2020 Apollo GraphQL. All rights reserved.
//

import Foundation
@testable import ApolloCodegenLib

// TODO: Delete these when TypeUsed gets ASTVariableType
extension String {
  
  static func named(_ name: String) -> String {
    return name
  }
  
  static func nonNullNamed(_ name: String) -> String {
    return "\(name)!"
  }
  
  static func swiftNamed(_ name: String) -> String {
    return "\(name)?"
  }
  
  static func swiftNonNullNamed(_ name: String) -> String {
    return name
  }
}

extension ASTVariableType {
  
  static func named(_ name: String) -> ASTVariableType {
    let nameType = ASTVariableType(kind: .Name,
                                   value: name,
                                   type: nil,
                                   name: nil)
    return ASTVariableType(kind: .NamedType,
                           value: nil,
                           type: nil,
                           name: nameType)
  }
    
  static func nonNullNamed(_ name: String) -> ASTVariableType {
    return ASTVariableType(kind: .NonNullType,
                           value: nil,
                           type: .named(name),
                           name: nil)
  }
  
  static func list(of type: ASTVariableType) -> ASTVariableType {
    return ASTVariableType(kind: .ListType,
                           value: nil,
                           type: type,
                           name: nil)
  }
  
  static func nonNullList(of type: ASTVariableType) -> ASTVariableType {
    return ASTVariableType(kind: .NonNullType,
                           value: nil,
                           type: .list(of: type),
                           name: nil)
  }
}
