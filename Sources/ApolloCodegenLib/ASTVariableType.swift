import Foundation

/// Nestable variable type so that we can determine nullability and lists etc.
/// NOTE: This has to be a class because it contains an instance of itself recursievely
class ASTVariableType: Codable {

  /// What kind of type are we dealing with here?
  enum Kind: String, Codable, CaseIterable {
    case ListType
    case NamedType
    case Name
    case NonNullType
  }
  
  init(kind: Kind,
       value: String?,
       type: ASTVariableType?,
       name: ASTVariableType?) {
    self.kind = kind
    self.value = value
    self.type = type
    self.name = name
  }

  /// The Kind of this type
  let kind: Kind
  
  /// The name of this type
  let value: String?
  
  let name: ASTVariableType?
  
  /// Any further nested type information.
  let type: ASTVariableType?
  
  enum TypeConversionError: Error, LocalizedError {
    case nameNotPresent(forKind: Kind)
    case typeNotPresent(forKind: Kind)
    
    var errorDescription: String? {
      switch self {
      case .nameNotPresent(let kind):
        return "Type \(kind.rawValue) should have a name"
      case .typeNotPresent(let kind):
        return "Type \(kind.rawValue) should have a type"
      }
    }
  }
  
  func toSwiftType() throws -> String {
    switch self.kind {
    case .ListType:
      guard let innerType = self.type else {
        throw TypeConversionError.typeNotPresent(forKind: self.kind)
      }
      
      let innerSwiftType = try innerType.toSwiftType()
      return "[\(innerSwiftType)]?"
    case .NonNullType:
      guard let innerType = self.type else {
        throw TypeConversionError.typeNotPresent(forKind: self.kind)
      }
      
      let innerSwiftType = try innerType.toSwiftType()
      return try innerSwiftType.apollo_droppingSuffix("?")
    case .NamedType:
      guard let name = self.name else {
        throw TypeConversionError.typeNotPresent(forKind: self.kind)
      }
      
      let innerType = try name.toSwiftType()
      return "\(innerType)?"
    case .Name:
      guard let name = self.value else {
        throw TypeConversionError.nameNotPresent(forKind: self.kind)
      }
      
      return "\(name)"
    }
  }
}

// Only structs get equatable auto-conformance, so: 
extension ASTVariableType: Equatable {
  static func == (lhs: ASTVariableType, rhs: ASTVariableType) -> Bool {
    lhs.kind == rhs.kind
      && lhs.value == rhs.value
      && lhs.type == rhs.type
      && lhs.name == rhs.name
  }
}

extension ASTVariableType: CustomDebugStringConvertible {
  var debugDescription: String {
    "\n(kind: \(self.kind.rawValue), value: \(value ?? "nil"), type: \(self.type?.debugDescription ?? "nil"), name: \(self.name?.debugDescription ?? "nil")"
  }
}
