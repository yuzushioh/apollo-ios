import Foundation

struct ASTSelectionSet: Codable, Equatable {
  let possibleTypes: [String]
  
  let selections: [ASTSelection]
}

struct ASTSelection: Codable, Equatable {
  enum Kind: String, Codable {
    case BooleanCondition
    case Field
    case FragmentSpread
    case TypeCondition
  }
  
  /// An argument which can be passed along with a field
  struct Argument: Codable, Equatable {
    /// The name of the argument
    let name: String
    
    /// The value of the argument - this is generally a dictionary or a string, but it's set up as a JSONValue to allow flexibility.
    let value: JSONValue
    
    /// The type of the argument
    let typeNode: ASTVariableType
  }
  
  let kind: Kind
  let responseKey: String?
  let name: String?
  let typeNode: ASTVariableType?
  
  let description: String?
  
  let isDeprecated: Bool?
  
  let args: [Argument]?
  
  let selectionSet: ASTSelectionSet?
  
  let fragmentName: String?
  let isConditional: Bool?
  
  let variableName: String?
  let inverted: Bool?
}
