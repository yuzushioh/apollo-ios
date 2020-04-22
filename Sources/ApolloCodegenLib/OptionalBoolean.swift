import Foundation

extension Optional where Wrapped == Bool {
  
  var apollo_boolValue: Bool {
    switch self {
    case .none:
      return false
    case .some(let actual):
      return actual
    }
  }
}

extension Optional {
  enum UnwrapError: Error {
    case unexpectedNil
  }
  
  func apollo_unwrap() throws -> Wrapped {
    switch self {
    case .none:
      throw UnwrapError.unexpectedNil
    case .some(let wrapped):
      return wrapped
    }
  }
}
