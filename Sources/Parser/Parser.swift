//struct Parser {
//    var text = "Hello, World!"
//}

public enum ParseResult<T> {
    case success(T)
    case failure(ParseError)
}

public enum ParseError: Error {
    case notMatch
    case unknow
}


public struct Parser<Output, Input: Sequence> {
    
    public var parse: (Input) -> ParseResult<(Output, Input)>
    
    public func run(_ input: Input) -> Output? {
        switch parse(input) {
        case .success(let (output, _)):
            return output
        case .failure(let error):
            #if DEBUG
            print(error)
            #endif
            return nil
        }
    }
}

//extension Parser {
//    public var repeats: Parser<[Output], Input> {
//        return Parser<[Output], Input>(parse: { (inputList) -> ParseResult<([Output], Input)> in
//            var results = [Output]()
//            var list = Array(inputList)
//            
//            while list.underestimatedCount > 0 {
//                switch self.parse(inputList) {
//                case .success(let (result, rest)):
//                    results.append(result)
//                    list = Array(rest)
//                case .failure(_):
//                    list = Array(list.dropFirst())
//                    continue
//                }
//            }
//            return .success((results, list))
//        })
//    }
//}
