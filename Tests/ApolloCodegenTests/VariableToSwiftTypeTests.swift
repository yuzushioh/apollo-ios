//
//  VariableToSwiftTypeTests.swift
//  ApolloCodegenTests
//
//  Created by Ellen Shapiro on 2/29/20.
//  Copyright © 2020 Apollo GraphQL. All rights reserved.
//

import XCTest
@testable import ApolloCodegenLib

class VariableToSwiftTypeTests: XCTestCase {
  
  func testNullableNameType() throws {
    let json: [String: Any?] = [
      "kind": "NamedType",
      "name": [
        "kind": "Name",
        "value": "Episode",
      ]
    ]
    
    let variable = try ASTVariableType(dictionary: json)
    XCTAssertEqual(variable.kind, .NamedType)
    XCTAssertNil(variable.value)
    
    let innerType = try XCTUnwrap(variable.name)
    XCTAssertEqual(innerType.kind, .Name)
    XCTAssertEqual(innerType.value, "Episode")
    XCTAssertNil(innerType.type)
    
    XCTAssertEqual(try variable.toSwiftType(), "Episode?")
  }
  
  func testNonNullNameType() throws {
    let json: [String: Any?] = [
      "kind": "NonNullType",
      "type": [
        "kind": "NamedType",
        "name": [
          "kind": "Name",
          "value": "Episode",
        ]
      ]
    ]
    
    let variable = try ASTVariableType(dictionary: json)
    XCTAssertEqual(variable.kind, .NonNullType)
    XCTAssertNil(variable.value)
    
    let ofOuterType = try XCTUnwrap(variable.type)
    XCTAssertEqual(ofOuterType.kind, .NamedType)
    XCTAssertNil(ofOuterType.value)
    
    let ofInnerType = try XCTUnwrap(ofOuterType.name)
    XCTAssertEqual(ofInnerType.kind, .Name)
    XCTAssertEqual(ofInnerType.value, "Episode")
    XCTAssertNil(ofInnerType.type)
    
    XCTAssertEqual(try variable.toSwiftType(), "Episode")
  }
  
  func testNullableListOfNullableItems() throws {
    let json: [String: Any?] = [
      "kind": "ListType",
      "type": [
        "kind": "NamedType",
        "name": [
          "kind": "Name",
          "value": "Character",
        ]
      ]
    ]
    
    let variable = try ASTVariableType(dictionary: json)
    XCTAssertEqual(variable.kind, .ListType)
    XCTAssertNil(variable.value)
    
    let outerType = try XCTUnwrap(variable.type)
    XCTAssertEqual(outerType.kind, .NamedType)
    XCTAssertNil(outerType.value)
    
    let innerType = try XCTUnwrap(outerType.name)
    XCTAssertEqual(innerType.value, "Character")
    XCTAssertNil(innerType.type)

    XCTAssertEqual(try variable.toSwiftType(), "[Character?]?")
  }
  
  func testNullableListOfNonNullItems() throws {
    let json: [String: Any?] = [
      "kind": "ListType",
        "type": [
        "kind": "NonNullType",
        "type": [
          "kind": "NamedType",
          "name": [
            "kind": "Name",
            "value": "Character",
          ]
        ]
      ]
    ]
    
    let variable = try ASTVariableType(dictionary: json)
    XCTAssertEqual(variable.kind, .ListType)
    XCTAssertNil(variable.value)
    
    let ofFirstType = try XCTUnwrap(variable.type)
    XCTAssertEqual(ofFirstType.kind, .NonNullType)
    XCTAssertNil(ofFirstType.value)
    
    let ofSecondType = try XCTUnwrap(ofFirstType.type)
    XCTAssertEqual(ofSecondType.kind, .NamedType)
    XCTAssertNil(ofSecondType.value)
    
    let ofThirdType = try XCTUnwrap(ofSecondType.name)
    XCTAssertEqual(ofThirdType.kind, .Name)
    XCTAssertEqual(ofThirdType.value, "Character")
    XCTAssertNil(ofThirdType.type)

    XCTAssertEqual(try variable.toSwiftType(), "[Character]?")
  }
  
  func testNonNullListOfNullableItems() throws {
    let json: [String: Any?] = [
      "kind": "NonNullType",
      "type": [
        "kind": "ListType",
        "type": [
          "kind": "NamedType",
          "name": [
            "kind": "Name",
            "value": "Character",
          ]
        ]
      ]
    ]
    
    let variable = try ASTVariableType(dictionary: json)
    XCTAssertEqual(variable.kind, .NonNullType)
    XCTAssertNil(variable.value)
    
    let ofFirstType = try XCTUnwrap(variable.type)
    XCTAssertEqual(ofFirstType.kind, .ListType)
    XCTAssertNil(ofFirstType.value)
    
    let ofSecondType = try XCTUnwrap(ofFirstType.type)
    XCTAssertEqual(ofSecondType.kind, .NamedType)
    XCTAssertNil(ofSecondType.value)
    
    let ofThirdType = try XCTUnwrap(ofSecondType.name)
    XCTAssertEqual(ofThirdType.kind, .Name)
    XCTAssertEqual(ofThirdType.value, "Character")
    XCTAssertNil(ofThirdType.type)
    
    XCTAssertEqual(try variable.toSwiftType(), "[Character?]")
  }
  
  func testNonNullListOfNonNullItems() throws {
    let json: [String: Any?] = [
      "kind": "NonNullType",
      "type": [
        "kind": "ListType",
        "type": [
          "kind": "NonNullType",
          "type": [
            "kind": "NamedType",
            "name": [
              "kind": "Name",
              "value": "Character",
            ]
          ]
        ]
      ]
    ]
    
    let variable = try ASTVariableType(dictionary: json)
    XCTAssertEqual(variable.kind, .NonNullType)
    XCTAssertNil(variable.value)
    
    let ofFirstType = try XCTUnwrap(variable.type)
    XCTAssertEqual(ofFirstType.kind, .ListType)
    XCTAssertNil(ofFirstType.value)
    
    let ofSecondType = try XCTUnwrap(ofFirstType.type)
    XCTAssertEqual(ofSecondType.kind, .NonNullType)
    XCTAssertNil(ofSecondType.value)
    
    let ofThirdType = try XCTUnwrap(ofSecondType.type)
    XCTAssertEqual(ofThirdType.kind, .NamedType)
    XCTAssertNil(ofThirdType.value)
    
    let ofFourthType = try XCTUnwrap(ofThirdType.name)
    XCTAssertEqual(ofFourthType.kind, .Name)
    XCTAssertEqual(ofFourthType.value, "Character")
    XCTAssertNil(ofFourthType.type)
    
    XCTAssertEqual(try variable.toSwiftType(), "[Character]")
  }
}
