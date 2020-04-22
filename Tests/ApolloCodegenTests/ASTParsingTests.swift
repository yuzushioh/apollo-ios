//
//  ASTParsingTests.swift
//  ApolloCodegenTests
//
//  Created by Ellen Shapiro on 2/26/20.
//  Copyright © 2020 Apollo GraphQL. All rights reserved.
//

import XCTest
@testable import ApolloCodegenLib

class ASTParsingTests: XCTestCase {
  
  lazy var starWarsJSONURL: URL = {
    let sourceRoot = CodegenTestHelper.sourceRootURL()
    let starWarsJSONURL = sourceRoot
      .appendingPathComponent("Sources")
      .appendingPathComponent("StarWarsAPI")
      .appendingPathComponent("API.json")
    
    return starWarsJSONURL
  }()

  
  private func loadAST(from url: URL,
                       file: StaticString = #file,
                       line: UInt = #line) throws -> ASTOutput {
    try ASTOutput.load(from: url, decoder: JSONDecoder())
  }
  
  func testLoadingStarWarsJSON() throws {
    do {
      let output = try loadAST(from: starWarsJSONURL)
      XCTAssertEqual(output.operations.count, 36)
      XCTAssertEqual(output.fragments.count, 15)
      XCTAssertEqual(output.typesUsed.count, 3)
    } catch {
      CodegenTestHelper.handleFileLoadError(error)
    }
  }
  
  func testParsingASTTypes() throws {
    let output: ASTOutput
    do {
      output = try loadAST(from: starWarsJSONURL)
    } catch {
      CodegenTestHelper.handleFileLoadError(error)
      return
    }
    
    let types = output.typesUsed
    
    // Check top-level properties of the types
    XCTAssertEqual(types.map { $0.name }, [
      "Episode",
      "ReviewInput",
      "ColorInput",
    ])
    
    XCTAssertEqual(types.map { $0.kind }, [
      .EnumType,
      .InputObjectType,
      .InputObjectType
    ])
    
    XCTAssertEqual(types.map { $0.description }, [
      "The episodes in the Star Wars trilogy",
      "The input object sent when someone is creating a new review",
      "The input object sent when passing in a color",
    ])
    
    // Check the enum type
    let enumType = types[0]
    XCTAssertNil(enumType.fields)
    let enumValues = try XCTUnwrap(enumType.values, "Episode should have values")
    
    XCTAssertEqual(enumValues.map { $0.name }, [
      "NEWHOPE",
      "EMPIRE",
      "JEDI",
    ])
    
    XCTAssertEqual(enumValues.map { $0.description }, [
      "Star Wars Episode IV: A New Hope, released in 1977.",
      "Star Wars Episode V: The Empire Strikes Back, released in 1980.",
      "Star Wars Episode VI: Return of the Jedi, released in 1983.",
    ])
    
    XCTAssertEqual(enumValues.map { $0.isDeprecated }, [
      false,
      false,
      false,
    ])
    
    /// Check input object with descriptions
    let reviewInput = types[1]
    XCTAssertNil(reviewInput.values)
    let reviewFields = try XCTUnwrap(reviewInput.fields, "Review should have fields!")
    
    XCTAssertEqual(reviewFields.map { $0.name }, [
      "stars",
      "commentary",
      "favorite_color",
    ])
    
    XCTAssertEqual(reviewFields.map { $0.type }, [
      .nonNullNamed("Int"),
      .named("String"),
      .named("ColorInput"),
    ])
    
    XCTAssertEqual(reviewFields.map { $0.description }, [
      "0-5 stars",
      "Comment about the movie, optional",
      "Favorite color, optional"
    ])
    
    /// Check input object without descriptions
    let colorInput = types[2]
    XCTAssertNil(colorInput.values)
    let colorSelections = try XCTUnwrap(colorInput.fields, "Color input should have fields!")
    
    XCTAssertEqual(colorSelections.map { $0.name }, [
      "red",
      "green",
      "blue",
    ])
    
    XCTAssertEqual(colorSelections.map { $0.type }, [
      .nonNullNamed("Int"),
      .nonNullNamed("Int"),
      .nonNullNamed("Int"),
    ])
    
    XCTAssertEqual(colorSelections.map { $0.description }, [
      nil,
      nil,
      nil,
    ])
  }
  
  func testParsingOperationWithMutation() throws {
    let output: ASTOutput
    do {
      output = try loadAST(from: starWarsJSONURL)
    } catch {
      CodegenTestHelper.handleFileLoadError(error)
      return
    }
    
    let createAwesomeReviewMutation = try XCTUnwrap(output.operations.first(where: { $0.operationName == "CreateAwesomeReview" }))
    
    XCTAssertTrue(createAwesomeReviewMutation.filePath.hasPrefix("file:///"))
    XCTAssertTrue(createAwesomeReviewMutation.filePath.hasSuffix("/Sources/StarWarsAPI/CreateReviewForEpisode.graphql"))
    XCTAssertEqual(createAwesomeReviewMutation.operationType, .mutation)
    XCTAssertEqual(createAwesomeReviewMutation.rootType, "Mutation")
    
    XCTAssertEqual(createAwesomeReviewMutation.source, """
mutation CreateAwesomeReview {\n  createReview(episode: JEDI, review: {stars: 10, commentary: \"This is awesome!\"}) {\n    __typename\n    stars\n    commentary\n  }\n}
""")
//    XCTAssertEqual(createAwesomeReviewMutation.sourceWithFragments, """
//mutation CreateAwesomeReview {\n  createReview(episode: JEDI, review: {stars: 10, commentary: \"This is awesome!\"}) {\n    __typename\n    stars\n    commentary\n  }\n}
//""")
    
//    XCTAssertEqual(createAwesomeReviewMutation.operationId, "4a1250de93ebcb5cad5870acf15001112bf27bb963e8709555b5ff67a1405374")
    XCTAssertTrue(createAwesomeReviewMutation.variables.isEmpty)
    
    XCTAssertEqual(createAwesomeReviewMutation.selectionSet.selections.count, 1)
    let outerSelection = try XCTUnwrap(createAwesomeReviewMutation.selectionSet.selections.first)
    
    XCTAssertEqual(outerSelection.responseKey, "createReview")
    XCTAssertEqual(outerSelection.name, "createReview")
    XCTAssertEqual(outerSelection.typeNode, .named("Review"))
    
    let isDeprecated = try XCTUnwrap(outerSelection.isDeprecated)
    XCTAssertFalse(isDeprecated)
    XCTAssertNil(outerSelection.isConditional)
    
    let arguments = try XCTUnwrap(outerSelection.args)
    
    XCTAssertEqual(arguments.map { $0.name }, [
      "episode",
      "review",
    ])
    
    XCTAssertEqual(arguments.map { $0.value }, [
      .string("JEDI"),
      .dictionary([
        "stars": .int(10),
        "commentary": .string("This is awesome!"),
      ])
    ])
    
    XCTAssertEqual(arguments.map { $0.typeNode }, [
      .named("Episode"),
      .nonNullNamed("ReviewInput")
    ])
    
    
    let innerSelections = try XCTUnwrap(outerSelection.selectionSet?.selections)
    XCTAssertEqual(innerSelections.map { $0.responseKey }, [
      "__typename",
      "stars",
      "commentary",
      
    ])
    
    XCTAssertEqual(innerSelections.map { $0.name }, [
      "__typename",
      "stars",
      "commentary",
    ])
    
    XCTAssertEqual(innerSelections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      .nonNullNamed("Int"),
      .named("String"),
    ])
    
    XCTAssertEqual(innerSelections.map { $0.isConditional }, [
      nil,
      nil,
      nil,
    ])
    
    XCTAssertEqual(innerSelections.map { $0.description }, [
      nil,
      "The number of stars this review gave, 1-5",
      "Comment about the movie",
    ])
    
    XCTAssertEqual(innerSelections.map { $0.isDeprecated }, [
      nil,
      false,
      false,
    ])
  }
  
  func testParsingOperationWithQueryAndInputAndNestedTypes() throws {
    let output: ASTOutput
    do {
      output = try loadAST(from: starWarsJSONURL)
    } catch {
      CodegenTestHelper.handleFileLoadError(error)
      return
    }
    
    let heroAndFriendsNamesQuery = try XCTUnwrap(output.operations.first(where: { $0.operationName == "HeroAndFriendsNames" }))
    XCTAssertTrue(heroAndFriendsNamesQuery.filePath.hasPrefix("file:///"))
    XCTAssertTrue(heroAndFriendsNamesQuery.filePath.hasSuffix("/Sources/StarWarsAPI/HeroAndFriendsNames.graphql"))
    XCTAssertEqual(heroAndFriendsNamesQuery.operationType, .query)
    XCTAssertEqual(heroAndFriendsNamesQuery.rootType, "Query")
    
    XCTAssertEqual(heroAndFriendsNamesQuery.source, """
query HeroAndFriendsNames($episode: Episode) {\n  hero(episode: $episode) {\n    __typename\n    name\n    friends {\n      __typename\n      name\n    }\n  }\n}
""")
    
//    XCTAssertEqual(heroAndFriendsNamesQuery.sourceWithFragments, """
//query HeroAndFriendsNames($episode: Episode) {\n  hero(episode: $episode) {\n    __typename\n    name\n    friends {\n      __typename\n      name\n    }\n  }\n}
//""")
//    XCTAssertEqual(heroAndFriendsNamesQuery.operationId, "fe3f21394eb861aa515c4d582e645469045793c9cbbeca4b5d4ce4d7dd617556")
    
    XCTAssertEqual(heroAndFriendsNamesQuery.variables.count, 1)
    let variable = heroAndFriendsNamesQuery.variables[0]
    
    XCTAssertEqual(variable.name, "episode")
    XCTAssertEqual(variable.typeNode, .named("Episode"))
    
    let outerSelection = heroAndFriendsNamesQuery.selectionSet.selections[0]
    
    XCTAssertEqual(outerSelection.responseKey, "hero")
    XCTAssertEqual(outerSelection.name, "hero")
    XCTAssertEqual(outerSelection.typeNode, .named("Character"))
    XCTAssertNil(outerSelection.isConditional)
    
    let isDeprecated = try XCTUnwrap(outerSelection.isDeprecated)
    XCTAssertFalse(isDeprecated)
    
    let arguments = try XCTUnwrap(outerSelection.args)
    XCTAssertEqual(arguments.count, 1)
    let argument = arguments[0]
    
    XCTAssertEqual(argument.name, "episode")
    XCTAssertEqual(argument.value, .dictionary([
      "kind": .string("Variable"),
      "variableName": .string("episode"),
    ]))
    XCTAssertEqual(argument.typeNode, .named("Episode"))
    
    let firstLevelSelections = try XCTUnwrap(outerSelection.selectionSet?.selections)
    
    XCTAssertEqual(firstLevelSelections.map { $0.responseKey }, [
      "__typename",
      "name",
      "friends",
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.name }, [
      "__typename",
      "name",
      "friends",
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      .nonNullNamed("String"),
      .list(of: .named("Character")),
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.isConditional }, [
      nil,
      nil,
      nil,
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.description }, [
      nil,
      "The name of the character",
      "The friends of the character, or an empty list if they have none",
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.isDeprecated }, [
      nil,
      false,
      false
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.selectionSet?.selections.count } , [
      nil,
      nil,
      2
    ])
    
    let secondLevelSelections = try XCTUnwrap(firstLevelSelections[2].selectionSet?.selections)
    
    XCTAssertEqual(secondLevelSelections.map { $0.responseKey }, [
      "__typename",
      "name"
    ])
    
    XCTAssertEqual(secondLevelSelections.map { $0.name }, [
      "__typename",
      "name"
    ])
    
    XCTAssertEqual(secondLevelSelections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      .nonNullNamed("String"),
    ])
    
    XCTAssertEqual(secondLevelSelections.map { $0.isConditional }, [
      nil,
      nil,
    ])
    
    XCTAssertEqual(secondLevelSelections.map { $0.description }, [
      nil,
      "The name of the character",
    ])
    
    XCTAssertEqual(secondLevelSelections.map { $0.isDeprecated }, [
      nil,
      false,
    ])
    
    XCTAssertEqual(secondLevelSelections.map { $0.selectionSet?.selections.count }, [
      nil,
      nil,
    ])
  }
  
  func testParsingOperationWithQueryAndFragment() throws {
    let output: ASTOutput
    do {
      output = try loadAST(from: starWarsJSONURL)
    } catch {
      CodegenTestHelper.handleFileLoadError(error)
      return
    }
    
    let heroAndFriendsNamesWithFragmentQuery = try XCTUnwrap(output.operations.first(where: { $0.operationName == "HeroAndFriendsNamesWithFragment" }))
    
    XCTAssertTrue(heroAndFriendsNamesWithFragmentQuery.filePath.hasPrefix("file:///"))
    XCTAssertTrue(heroAndFriendsNamesWithFragmentQuery.filePath.hasSuffix("/Sources/StarWarsAPI/HeroAndFriendsNames.graphql"))
    XCTAssertEqual(heroAndFriendsNamesWithFragmentQuery.operationType, .query)
    XCTAssertEqual(heroAndFriendsNamesWithFragmentQuery.rootType, "Query")
    
    XCTAssertEqual(heroAndFriendsNamesWithFragmentQuery.source, """
query HeroAndFriendsNamesWithFragment($episode: Episode) {\n  hero(episode: $episode) {\n    __typename\n    name\n    ...FriendsNames\n  }\n}
""")
    
//    XCTAssertEqual(heroAndFriendsNamesWithFragmentQuery.sourceWithFragments, """
//query HeroAndFriendsNamesWithFragment($episode: Episode) {\n  hero(episode: $episode) {\n    __typename\n    name\n    ...FriendsNames\n  }\n}\nfragment FriendsNames on Character {\n  __typename\n  friends {\n    __typename\n    name\n  }\n}
//""")
    
//    XCTAssertEqual(heroAndFriendsNamesWithFragmentQuery.operationId, "1d3ad903dad146ff9d7aa09813fc01becd017489bfc1af8ffd178498730a5a26")
    
    XCTAssertEqual(heroAndFriendsNamesWithFragmentQuery.variables.count, 1)
    let variable = heroAndFriendsNamesWithFragmentQuery.variables[0]
    
    XCTAssertEqual(variable.name, "episode")
    XCTAssertEqual(variable.typeNode, .named("Episode"))
    
    XCTAssertEqual(heroAndFriendsNamesWithFragmentQuery.selectionSet.possibleTypes, [
      "Query"
    ])
    
    XCTAssertEqual(heroAndFriendsNamesWithFragmentQuery.selectionSet.selections.count, 1)
    let outerSelection = try XCTUnwrap(heroAndFriendsNamesWithFragmentQuery.selectionSet.selections.first)
    
    XCTAssertEqual(outerSelection.kind, .Field)
    XCTAssertEqual(outerSelection.responseKey, "hero")
    XCTAssertEqual(outerSelection.name, "hero")
    XCTAssertEqual(outerSelection.typeNode, .named("Character"))
    XCTAssertFalse(outerSelection.isConditional.apollo_boolValue)
    let isDeprecated = try XCTUnwrap(outerSelection.isDeprecated)
    XCTAssertFalse(isDeprecated)
    XCTAssertNil(outerSelection.isConditional)
    
    let arguments = try XCTUnwrap(outerSelection.args)
    XCTAssertEqual(arguments.count, 1)
    let argument = try XCTUnwrap(arguments.first)
    
    XCTAssertEqual(argument.name, "episode")
    XCTAssertEqual(argument.value, .dictionary([
      "kind": .string("Variable"),
      "variableName": .string("episode")
    ]))
    XCTAssertEqual(argument.typeNode, .named("Episode"))
    
    let firstLevelSelections = try XCTUnwrap(outerSelection.selectionSet?.selections)
    
    XCTAssertEqual(firstLevelSelections.map { $0.kind }, [
      .Field,
      .Field,
      .FragmentSpread,
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.responseKey }, [
      "__typename",
      "name",
      nil
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.name }, [
      "__typename",
      "name",
      nil
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      .nonNullNamed("String"),
      nil
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.isConditional }, [
      nil,
      nil,
      false
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.description }, [
      nil,
      "The name of the character",
      nil,
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.isDeprecated }, [
      nil,
      false,
      nil,
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.args?.count }, [
      nil,
      nil,
      nil,
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.selectionSet?.selections.count }, [
      nil,
      nil,
      2,
    ])
    
    XCTAssertEqual(firstLevelSelections.map { $0.selectionSet?.possibleTypes }, [
      nil,
      nil,
      [ "Human", "Droid" ]
    ])
    let outerFragmentSelections = try XCTUnwrap(firstLevelSelections[2].selectionSet?.selections)
    
    XCTAssertEqual(outerFragmentSelections.map { $0.kind }, [
      .Field,
      .Field,
    ])
    
    XCTAssertEqual(outerFragmentSelections.map { $0.responseKey }, [
      "__typename",
      "friends",
    ])
    
    XCTAssertEqual(outerFragmentSelections.map { $0.name }, [
      "__typename",
      "friends",
    ])
    
    XCTAssertEqual(outerFragmentSelections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      .list(of: .named("Character")),
    ])
    
    XCTAssertEqual(outerFragmentSelections.map { $0.isConditional }, [
      nil,
      nil,
    ])
    
    XCTAssertEqual(outerFragmentSelections.map { $0.description }, [
      nil,
      "The friends of the character, or an empty list if they have none"
    ])
    
    XCTAssertEqual(outerFragmentSelections.map { $0.isDeprecated }, [
      nil,
      false
    ])
    
    XCTAssertEqual(outerFragmentSelections.map { $0.args?.count }, [
      nil,
      nil,
    ])
    
    XCTAssertEqual(outerFragmentSelections.map { $0.selectionSet?.selections.count }, [
      nil,
      2,
    ])
    
    XCTAssertEqual(outerFragmentSelections.map { $0.selectionSet?.possibleTypes }, [
      nil,
      [ "Human", "Droid" ]
    ])
    
    let innerFragmentSelections = try XCTUnwrap(outerFragmentSelections[1].selectionSet?.selections)
    
    XCTAssertEqual(innerFragmentSelections.map { $0.kind }, [
      .Field,
      .Field,
    ])
    
    XCTAssertEqual(innerFragmentSelections.map { $0.name }, [
      "__typename",
      "name"
    ])
    
    XCTAssertEqual(innerFragmentSelections.map { $0.responseKey }, [
      "__typename",
      "name"
    ])
    
    XCTAssertEqual(innerFragmentSelections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      .nonNullNamed("String")
    ])
    
    XCTAssertEqual(innerFragmentSelections.map { $0.description }, [
      nil,
      "The name of the character",
    ])
    
    XCTAssertEqual(innerFragmentSelections.map { $0.isDeprecated }, [
      nil,
      false
    ])
  }
  
  func testParsingQueryWithInlineFragments() throws {
    let output: ASTOutput
    do {
      output = try loadAST(from: starWarsJSONURL)
    } catch {
      CodegenTestHelper.handleFileLoadError(error)
      return
    }
  
    let heroDetailsQuery = try XCTUnwrap(output.operations.first(where: { $0.operationName == "HeroDetails" }))
  
    XCTAssertTrue(heroDetailsQuery.filePath.hasPrefix("file:///"))
    XCTAssertTrue(heroDetailsQuery.filePath.hasSuffix("/Sources/StarWarsAPI/HeroDetails.graphql"))
    XCTAssertEqual(heroDetailsQuery.operationType, .query)
    XCTAssertEqual(heroDetailsQuery.rootType, "Query")
    
    XCTAssertEqual(heroDetailsQuery.source, """
query HeroDetails($episode: Episode) {\n  hero(episode: $episode) {\n    __typename\n    name\n    ... on Human {\n      height\n    }\n    ... on Droid {\n      primaryFunction\n    }\n  }\n}
""")
    
//    XCTAssertEqual(heroDetailsQuery.sourceWithFragments, """
//query HeroDetails($episode: Episode) {\n  hero(episode: $episode) {\n    __typename\n    name\n    ... on Human {\n      height\n    }\n    ... on Droid {\n      primaryFunction\n    }\n  }\n}
//""")
//
//    XCTAssertEqual(heroDetailsQuery.operationId, "2b67111fd3a1c6b2ac7d1ef7764e5cefa41d3f4218e1d60cb67c22feafbd43ec")
    
    XCTAssertEqual(heroDetailsQuery.variables.count, 1)
    let variable = try XCTUnwrap(heroDetailsQuery.variables.first)
    XCTAssertEqual(variable.name, "episode")
    XCTAssertEqual(variable.typeNode, .named("Episode"))
    
    XCTAssertEqual(heroDetailsQuery.selectionSet.possibleTypes, [
      "Query"
    ])
    XCTAssertEqual(heroDetailsQuery.selectionSet.selections.count, 1)
    let outerSelection = try XCTUnwrap(heroDetailsQuery.selectionSet.selections.first)
    
    XCTAssertEqual(outerSelection.kind, .Field)
    XCTAssertEqual(outerSelection.responseKey, "hero")
    XCTAssertEqual(outerSelection.name, "hero")
    XCTAssertEqual(outerSelection.typeNode, .named("Character"))
    XCTAssertFalse(outerSelection.isConditional.apollo_boolValue)
    
    let isDeprecated = try XCTUnwrap(outerSelection.isDeprecated)
    XCTAssertFalse(isDeprecated)
    
    XCTAssertEqual(outerSelection.args?.count, 1)
    let argument = try XCTUnwrap(outerSelection.args?.first)
    XCTAssertEqual(argument.name, "episode")
    XCTAssertEqual(argument.value, .dictionary([
      "kind": .string("Variable"),
      "variableName": .string("episode"),
    ]))
    XCTAssertEqual(argument.typeNode, .named("Episode"))

    XCTAssertEqual(outerSelection.selectionSet?.possibleTypes, [
      "Human",
      "Droid"
    ])

    let innerSelections = try XCTUnwrap(outerSelection.selectionSet?.selections)
    
    XCTAssertEqual(innerSelections.map { $0.kind }, [
      .Field,
      .Field,
      .TypeCondition,
      .TypeCondition,
    ])
    
    XCTAssertEqual(innerSelections.map { $0.responseKey }, [
      "__typename",
      "name",
      nil,
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.name }, [
      "__typename",
      "name",
      nil,
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      .nonNullNamed("String"),
      .named("Human"),
      .named("Droid"),
    ])
    
    XCTAssertEqual(innerSelections.map { $0.isConditional }, [
      nil,
      nil,
      nil,
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.description }, [
      nil,
      "The name of the character",
      nil,
      nil,
      
    ])
    
    XCTAssertEqual(innerSelections.map { $0.isDeprecated }, [
      nil,
      false,
      nil,
      nil,
    ])
    
    XCTAssertEqual(innerSelections.map { $0.selectionSet?.possibleTypes }, [
      nil,
      nil,
      ["Human"],
      ["Droid"]
    ])
    
    XCTAssertEqual(innerSelections.map { $0.selectionSet?.selections.count }, [
      nil,
      nil,
      1,
      1
    ])
    
    let humanSelection = try XCTUnwrap(innerSelections[2].selectionSet?.selections.first)
    
    XCTAssertEqual(humanSelection.kind, .Field)
    XCTAssertEqual(humanSelection.responseKey, "height")
    XCTAssertEqual(humanSelection.name, "height")
    XCTAssertEqual(humanSelection.typeNode, .named("Float"))
    XCTAssertEqual(humanSelection.description, "Height in the preferred unit, default is meters")
    
    let humanDeprecated = try XCTUnwrap(humanSelection.isDeprecated)
    XCTAssertFalse(humanDeprecated)
    
    let droidSelection = try XCTUnwrap(innerSelections[3].selectionSet?.selections.first)
    
    XCTAssertEqual(droidSelection.kind, .Field)
    XCTAssertEqual(droidSelection.responseKey, "primaryFunction")
    XCTAssertEqual(droidSelection.name, "primaryFunction")
    XCTAssertEqual(droidSelection.typeNode, .named("String"))
    XCTAssertEqual(droidSelection.description, "This droid's primary function")
    
    let droidDeprecated = try XCTUnwrap(droidSelection.isDeprecated)
    XCTAssertFalse(droidDeprecated)
  }
  
  func testParsingQueryWithAliasesAndPassedInRawValue() throws {
    let output: ASTOutput
    do {
      output = try loadAST(from: starWarsJSONURL)
    } catch {
      CodegenTestHelper.handleFileLoadError(error)
      return
    }
    
    let twoHeroesQuery = try XCTUnwrap(output.operations.first(where: { $0.operationName == "TwoHeroes" }))
    
    XCTAssertTrue(twoHeroesQuery.filePath.hasPrefix("file:///"))
    XCTAssertTrue(twoHeroesQuery.filePath
      .hasSuffix("/Sources/StarWarsAPI/TwoHeroes.graphql"))
    XCTAssertEqual(twoHeroesQuery.operationType, .query)
    XCTAssertEqual(twoHeroesQuery.rootType, "Query")
    XCTAssertTrue(twoHeroesQuery.variables.isEmpty)
    XCTAssertEqual(twoHeroesQuery.source, """
query TwoHeroes {\n  r2: hero {\n    __typename\n    name\n  }\n  luke: hero(episode: EMPIRE) {\n    __typename\n    name\n  }\n}
""")
    
//    XCTAssertEqual(twoHeroesQuery.sourceWithFragments, """
//query TwoHeroes {\n  r2: hero {\n    __typename\n    name\n  }\n  luke: hero(episode: EMPIRE) {\n    __typename\n    name\n  }\n}
//""")
    
//    XCTAssertEqual(twoHeroesQuery.operationId, "b868fa9c48f19b8151c08c09f46831e3b9cd09f5c617d328647de785244b52bb")
    
    let outerSelections = twoHeroesQuery.selectionSet.selections
    
    XCTAssertEqual(outerSelections.map { $0.responseKey }, [
      "r2",
      "luke",
    ])
    
    XCTAssertEqual(outerSelections.map { $0.name }, [
      "hero",
      "hero",
    ])
    
    XCTAssertEqual(outerSelections.map { $0.typeNode }, [
      .named("Character"),
      .named("Character"),
    ])
    
    XCTAssertEqual(outerSelections.map { $0.isConditional }, [
      nil,
      nil,
    ])
    
    XCTAssertEqual(outerSelections.map { $0.isDeprecated }, [
      false,
      false,
    ])
    
    XCTAssertEqual(outerSelections.map { $0.args?.count }, [
      nil,
      1,
    ])
    
    XCTAssertEqual(outerSelections.map { $0.selectionSet?.selections.count }, [
      2,
      2,
    ])
    
    let lukeArgs = try XCTUnwrap(outerSelections[1].args)
    XCTAssertEqual(lukeArgs.count, 1)
    let lukeArg = lukeArgs[0]
    
    XCTAssertEqual(lukeArg.name, "episode")
    XCTAssertEqual(lukeArg.value, .string("EMPIRE"))
    XCTAssertEqual(lukeArg.typeNode, .named("Episode"))
    
    let r2Selections = try XCTUnwrap(outerSelections[0].selectionSet?.selections)
    XCTAssertEqual(r2Selections.map { $0.responseKey }, [
      "__typename",
      "name"
    ])
    
    XCTAssertEqual(r2Selections.map { $0.name }, [
      "__typename",
      "name"
    ])
    
    XCTAssertEqual(r2Selections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      .nonNullNamed("String"),
    ])
    
    XCTAssertEqual(r2Selections.map { $0.isConditional }, [
      nil,
      nil,
    ])
    
    XCTAssertEqual(r2Selections.map { $0.isDeprecated }, [
      nil,
      false,
    ])
    
    XCTAssertEqual(r2Selections.map { $0.description }, [
      nil,
      "The name of the character"
    ])
    
    let lukeSelections = try XCTUnwrap(outerSelections[1].selectionSet?.selections)
    XCTAssertEqual(lukeSelections.map { $0.responseKey }, [
      "__typename",
      "name"
    ])
    
    XCTAssertEqual(lukeSelections.map { $0.name }, [
      "__typename",
      "name"
    ])
    
    XCTAssertEqual(lukeSelections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      .nonNullNamed("String"),
    ])
    
    XCTAssertEqual(lukeSelections.map { $0.isConditional }, [
      nil,
      nil,
    ])
    
    XCTAssertEqual(lukeSelections.map { $0.isDeprecated }, [
      nil,
      false,
    ])
    
    XCTAssertEqual(lukeSelections.map { $0.description }, [
      nil,
      "The name of the character"
    ])
  }
  
  func testParsingQueryWithConditionalInclusion() throws {
    let output: ASTOutput
    do {
      output = try loadAST(from: starWarsJSONURL)
    } catch {
      CodegenTestHelper.handleFileLoadError(error)
      return
    }
    
    let heroNameConditionalInclusionQuery = try XCTUnwrap(output.operations.first(where: { $0.operationName == "HeroNameConditionalInclusion" }))
    
    XCTAssertTrue(heroNameConditionalInclusionQuery.filePath.hasPrefix("file:///"))
    XCTAssertTrue(heroNameConditionalInclusionQuery.filePath
      .hasSuffix("/Sources/StarWarsAPI/HeroConditional.graphql"))
    XCTAssertEqual(heroNameConditionalInclusionQuery.operationType, .query)
    XCTAssertEqual(heroNameConditionalInclusionQuery.rootType, "Query")
    
    XCTAssertEqual(heroNameConditionalInclusionQuery.source, """
query HeroNameConditionalInclusion($includeName: Boolean!) {\n  hero {\n    __typename\n    name @include(if: $includeName)\n  }\n}
""")
    
//    XCTAssertEqual(heroNameConditionalInclusionQuery.sourceWithFragments, """
//query HeroNameConditionalInclusion($includeName: Boolean!) {\n  hero {\n    __typename\n    name @include(if: $includeName)\n  }\n}
//""")
    
//    XCTAssertEqual(heroNameConditionalInclusionQuery.operationId, "338081aea3acc83d04af0741ecf0da1ec2ee8e6468a88383476b681015905ef8")
    
    
    XCTAssertEqual(heroNameConditionalInclusionQuery.variables.count, 1)
    let variable = heroNameConditionalInclusionQuery.variables[0]
    
    XCTAssertEqual(variable.name, "includeName")
    XCTAssertEqual(variable.typeNode, .nonNullNamed("Boolean"))
    
    XCTAssertEqual(heroNameConditionalInclusionQuery.selectionSet.selections.count, 1)
    let outerSelection = heroNameConditionalInclusionQuery.selectionSet.selections[0]
    
    XCTAssertEqual(outerSelection.responseKey, "hero")
    XCTAssertEqual(outerSelection.name, "hero")
    XCTAssertEqual(outerSelection.typeNode, .named("Character"))
    XCTAssertNil(outerSelection.isConditional)
    
    let isDeprecated = try XCTUnwrap(outerSelection.isDeprecated)
    XCTAssertFalse(isDeprecated)
    
    XCTAssertEqual(outerSelection.selectionSet?.possibleTypes, [
      "Human",
      "Droid"
    ])

    let innerSelections = try XCTUnwrap(outerSelection.selectionSet?.selections)
    XCTAssertEqual(innerSelections.count, 2)
    
    XCTAssertEqual(innerSelections.map { $0.kind }, [
      .Field,
      .BooleanCondition
    ])
    
    XCTAssertEqual(innerSelections.map { $0.responseKey }, [
      "__typename",
       nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.name }, [
      "__typename",
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.variableName }, [
      nil,
      "includeName"
    ])
    
    XCTAssertEqual(innerSelections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.isConditional }, [
      nil,
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.isDeprecated }, [
      nil,
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.inverted }, [
      nil,
      false
    ])
    
    XCTAssertEqual(innerSelections.map { $0.selectionSet?.selections.count }, [
      nil,
      1
    ])
    
    XCTAssertEqual(innerSelections.map { $0.selectionSet?.possibleTypes }, [
      nil,
      [ "Human", "Droid" ]
    ])
    
    let secondLevelSelection = try XCTUnwrap(innerSelections[1].selectionSet?.selections.first)
    
    XCTAssertEqual(secondLevelSelection.kind, .Field)
    XCTAssertEqual(secondLevelSelection.responseKey, "name")
    XCTAssertEqual(secondLevelSelection.name, "name")
    XCTAssertEqual(secondLevelSelection.description, "The name of the character")
    XCTAssertEqual(secondLevelSelection.typeNode, .nonNullNamed("String"))
    
    let secondLevelDeprecated = try XCTUnwrap(secondLevelSelection.isDeprecated)
    XCTAssertFalse(secondLevelDeprecated)
  }
  
  func testParsingQueryWithConditionalExclusion() throws {
    let output: ASTOutput
    do {
      output = try loadAST(from: starWarsJSONURL)
    } catch {
      CodegenTestHelper.handleFileLoadError(error)
      return
    }
    
    let heroNameConditionalExclusionQuery = try XCTUnwrap(output.operations.first(where: { $0.operationName == "HeroNameConditionalExclusion" }))
    
    XCTAssertTrue(heroNameConditionalExclusionQuery.filePath.hasPrefix("file:///"))
    XCTAssertTrue(heroNameConditionalExclusionQuery.filePath
      .hasSuffix("/Sources/StarWarsAPI/HeroConditional.graphql"))
    XCTAssertEqual(heroNameConditionalExclusionQuery.operationType, .query)
    XCTAssertEqual(heroNameConditionalExclusionQuery.rootType, "Query")
    
    XCTAssertEqual(heroNameConditionalExclusionQuery.source, """
query HeroNameConditionalExclusion($skipName: Boolean!) {\n  hero {\n    __typename\n    name @skip(if: $skipName)\n  }\n}
""")
//    XCTAssertEqual(heroNameConditionalExclusionQuery.sourceWithFragments, """
//query HeroNameConditionalExclusion($skipName: Boolean!) {\n  hero {\n    __typename\n    name @skip(if: $skipName)\n  }\n}
//""")
    
//    XCTAssertEqual(heroNameConditionalExclusionQuery.operationId,  "3dd42259adf2d0598e89e0279bee2c128a7913f02b1da6aa43f3b5def6a8a1f8")
    
    XCTAssertEqual(heroNameConditionalExclusionQuery.variables.count, 1)
    let variable = try XCTUnwrap(heroNameConditionalExclusionQuery.variables.first)
    
    XCTAssertEqual(variable.name, "skipName")
    XCTAssertEqual(variable.typeNode, .nonNullNamed("Boolean"))
    
    XCTAssertEqual(heroNameConditionalExclusionQuery.selectionSet.possibleTypes, [
      "Query"
    ])
    XCTAssertEqual(heroNameConditionalExclusionQuery.selectionSet.selections.count, 1)
    let outerSelection = try XCTUnwrap(heroNameConditionalExclusionQuery.selectionSet.selections.first)
    
    XCTAssertEqual(outerSelection.kind, .Field)
    XCTAssertEqual(outerSelection.responseKey, "hero")
    XCTAssertEqual(outerSelection.name, "hero")
    XCTAssertEqual(outerSelection.typeNode, .named("Character"))
    XCTAssertFalse(outerSelection.isConditional.apollo_boolValue)
    
    let isDeprecated = try XCTUnwrap(outerSelection.isDeprecated)
    XCTAssertFalse(isDeprecated)
    
    let innerSelections = try XCTUnwrap(outerSelection.selectionSet?.selections)
    XCTAssertEqual(innerSelections.count, 2)
    
    XCTAssertEqual(innerSelections.map { $0.kind }, [
      .Field,
      .BooleanCondition
    ])
    
    XCTAssertEqual(innerSelections.map { $0.responseKey }, [
      "__typename",
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.name }, [
      "__typename",
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.isConditional }, [
      nil,
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.inverted }, [
      nil,
      true
    ])
    
    XCTAssertEqual(innerSelections.map { $0.isDeprecated }, [
      nil,
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.variableName }, [
      nil,
      "skipName"
    ])
    
    XCTAssertEqual(innerSelections.map { $0.selectionSet?.possibleTypes }, [
      nil,
      ["Human", "Droid"]
    ])
    
    XCTAssertEqual(innerSelections.map { $0.selectionSet?.selections.count }, [
      nil,
      1
    ])
    
    let booleanSelection = try XCTUnwrap(innerSelections[1].selectionSet?.selections.first)
    
    XCTAssertEqual(booleanSelection.kind, .Field)
    XCTAssertEqual(booleanSelection.responseKey, "name")
    XCTAssertEqual(booleanSelection.name, "name")
    XCTAssertEqual(booleanSelection.typeNode, .nonNullNamed("String"))
    XCTAssertEqual(booleanSelection.description, "The name of the character")
    
    let booleanDeprecated = try XCTUnwrap(booleanSelection.isDeprecated)
    XCTAssertFalse(booleanDeprecated)
  }
  
  func testParsingQueryWithConditionalFragmentInclusion() throws {
    let output: ASTOutput
    do {
      output = try loadAST(from: starWarsJSONURL)
    } catch {
      CodegenTestHelper.handleFileLoadError(error)
      return
    }
    
    let heroDetailsFragmentConditionalInclusionQuery = try XCTUnwrap(output.operations.first(where: { $0.operationName == "HeroDetailsFragmentConditionalInclusion" }))
    
    XCTAssertTrue(heroDetailsFragmentConditionalInclusionQuery.filePath.hasPrefix("file:///"))
    XCTAssertTrue(heroDetailsFragmentConditionalInclusionQuery.filePath
      .hasSuffix("/Sources/StarWarsAPI/HeroConditional.graphql"))
    XCTAssertEqual(heroDetailsFragmentConditionalInclusionQuery.operationType, .query)
    XCTAssertEqual(heroDetailsFragmentConditionalInclusionQuery.rootType, "Query")
    
    XCTAssertEqual(heroDetailsFragmentConditionalInclusionQuery.source, """
query HeroDetailsFragmentConditionalInclusion($includeDetails: Boolean!) {\n  hero {\n    __typename\n    ...HeroDetails @include(if: $includeDetails)\n  }\n}
""")
    
//    XCTAssertEqual(heroDetailsFragmentConditionalInclusionQuery.sourceWithFragments, """
//query HeroDetailsFragmentConditionalInclusion($includeDetails: Boolean!) {\n  hero {\n    __typename\n    ...HeroDetails @include(if: $includeDetails)\n  }\n}\nfragment HeroDetails on Character {\n  __typename\n  name\n  ... on Human {\n    height\n  }\n  ... on Droid {\n    primaryFunction\n  }\n}
//""")
    
//    XCTAssertEqual(heroDetailsFragmentConditionalInclusionQuery.operationId, "b31aec7d977249e185922e4cc90318fd2c7197631470904bf937b0626de54b4f")
    
    XCTAssertEqual(heroDetailsFragmentConditionalInclusionQuery.variables.count, 1)
    let variable = try XCTUnwrap(heroDetailsFragmentConditionalInclusionQuery.variables.first)
    
    XCTAssertEqual(variable.name, "includeDetails")
    XCTAssertEqual(variable.typeNode, .nonNullNamed("Boolean"))
    
    XCTAssertEqual(heroDetailsFragmentConditionalInclusionQuery.selectionSet.possibleTypes, [
      "Query"
    ])
    
    XCTAssertEqual(heroDetailsFragmentConditionalInclusionQuery.selectionSet.selections.count, 1)
    let outerSelection = try XCTUnwrap(heroDetailsFragmentConditionalInclusionQuery.selectionSet.selections.first)
    
    XCTAssertEqual(outerSelection.kind, .Field)
    XCTAssertEqual(outerSelection.responseKey, "hero")
    XCTAssertEqual(outerSelection.name, "hero")
    XCTAssertEqual(outerSelection.typeNode, .named("Character"))
    XCTAssertFalse(outerSelection.isConditional.apollo_boolValue)
    
    let isDeprecated = try XCTUnwrap(outerSelection.isDeprecated)
    XCTAssertFalse(isDeprecated)
    
    let innerSelections = try XCTUnwrap(outerSelection.selectionSet?.selections)
    XCTAssertEqual(innerSelections.count, 2)
    
    XCTAssertEqual(innerSelections.map { $0.kind }, [
      .Field,
      .BooleanCondition
    ])
    
    XCTAssertEqual(innerSelections.map { $0.responseKey }, [
      "__typename",
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.name }, [
      "__typename",
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.isConditional }, [
      nil,
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.description }, [
      nil,
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.isDeprecated }, [
      nil,
      nil
    ])
    
    XCTAssertEqual(innerSelections.map { $0.variableName }, [
      nil,
      "includeDetails"
    ])
    
    XCTAssertEqual(innerSelections.map { $0.inverted }, [
      nil,
      false
    ])
    
    XCTAssertEqual(innerSelections.map { $0.selectionSet?.selections.count }, [
      nil,
      1
    ])
    
    XCTAssertEqual(innerSelections.map { $0.selectionSet?.possibleTypes }, [
      nil,
      ["Human", "Droid"]
    ])
    
    let fragmentSelection = try XCTUnwrap(innerSelections[1].selectionSet?.selections.first)
    
    XCTAssertEqual(fragmentSelection.kind, .FragmentSpread)
    XCTAssertEqual(fragmentSelection.fragmentName, "HeroDetails")
    let fragmentConditional = try XCTUnwrap(fragmentSelection.isConditional)
    XCTAssertFalse(fragmentConditional)
    
    XCTAssertEqual(fragmentSelection.selectionSet?.possibleTypes, [
      "Human",
      "Droid",
    ])
    
    let spreadSelections = try XCTUnwrap(fragmentSelection.selectionSet?.selections)
    XCTAssertEqual(spreadSelections.count, 4)
    
    XCTAssertEqual(spreadSelections.map { $0.kind }, [
      .Field,
      .Field,
      .TypeCondition,
      .TypeCondition,
    ])
    
    XCTAssertEqual(spreadSelections.map { $0.typeNode }, [
      .nonNullNamed("String"),
      .nonNullNamed("String"),
      .named("Human"),
      .named("Droid"),
    ])
    
    XCTAssertEqual(spreadSelections.map { $0.responseKey }, [
      "__typename",
      "name",
      nil,
      nil,
    ])
    
    XCTAssertEqual(spreadSelections.map { $0.name }, [
      "__typename",
      "name",
      nil,
      nil,
    ])
    
    XCTAssertEqual(spreadSelections.map { $0.description }, [
      nil,
      "The name of the character",
      nil,
      nil
    ])
    
    XCTAssertEqual(spreadSelections.map { $0.isDeprecated }, [
      nil,
      false,
      nil,
      nil,
    ])
    
    XCTAssertEqual(spreadSelections.map { $0.selectionSet?.possibleTypes }, [
      nil,
      nil,
      ["Human"],
      ["Droid"],
    ])
    
    XCTAssertEqual(spreadSelections.map { $0.selectionSet?.selections.count }, [
      nil,
      nil,
      1,
      1,
    ])
    
    let humanSelection = try XCTUnwrap(spreadSelections[2].selectionSet?.selections.first)
    
    XCTAssertEqual(humanSelection.kind, .Field)
    XCTAssertEqual(humanSelection.responseKey, "height")
    XCTAssertEqual(humanSelection.name, "height")
    XCTAssertEqual(humanSelection.typeNode, .named("Float"))
    XCTAssertEqual(humanSelection.description, "Height in the preferred unit, default is meters")
    XCTAssertNil(humanSelection.selectionSet)
    XCTAssertNil(humanSelection.isConditional)
    
    let humanDeprecated = try XCTUnwrap(humanSelection.isDeprecated)
    XCTAssertFalse(humanDeprecated)
    
    let droidSelection = try XCTUnwrap(spreadSelections[3].selectionSet?.selections.first)
    
    XCTAssertEqual(droidSelection.kind, .Field)
    XCTAssertEqual(droidSelection.responseKey, "primaryFunction")
    XCTAssertEqual(droidSelection.name, "primaryFunction")
    XCTAssertEqual(droidSelection.typeNode, .named("String"))
    XCTAssertNil(humanSelection.selectionSet)
    XCTAssertNil(humanSelection.isConditional)
    
    let droidDeprecated = try XCTUnwrap(droidSelection.isDeprecated)
    XCTAssertFalse(droidDeprecated)
  }
}
