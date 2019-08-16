import Runes

/// ParseResult
///
/// - success: someValue
/// - failure: error
public enum ParseResult<T> {
    case success(T)
    case failure(ParseError)
}


// MARK: - optional
extension Result {
    var value: Success? {
        switch self {
        case .success(let result):
            return result
        case .failure(_):
            return nil
        }
    }
    var error: Failure? {
        switch self {
        case .success(_):
            return nil
        case .failure(let error):
            return error
        }
    }
}

/// ErrorType
///
/// - notMatch: parser not match the given token
/// - unknow: unknow reason
public enum ParseError: Error {
    case notMatch
    case fileEnd
    case unknow
}


/// Parser
public struct Parser<Output, Input: Sequence> {
    
    public var parse: (Input) -> Result<(Output, Input), Error>
    
    public func run(_ input: Input) -> Output? {
        switch parse(input) {
        case .success(let (output, _)):
            return output
        case .failure(_):
//            #if DEBUG
//            print(error)
//            #endif
            return nil
        }
    }
}

extension Parser {
    
    static func just(_ result: Output) -> Parser<Output, Input> {
        return Parser(parse: { (input) -> Result<(Output, Input), Error> in
            return .success((result, input))
        })
    }
    
    func between<L, R>(_ open: Parser<L, Input>, _ close: Parser<R, Input>) -> Parser<Output, Input> {
        return open *> self <* close
    }
    
    func map<U>(_ f: @escaping (Output) -> U) -> Parser<U, Input> {
        return Parser<U, Input>(parse: { (input) -> Result<(U, Input), Error> in
            switch self.parse(input) {
            case .success(let (result, rest)):
                return .success((f(result), rest))
            case .failure(let error):
                return .failure(error)
            }
        })
    }
    
    func flatMap<U>(_ f: @escaping (Output) -> Parser<U, Input>) -> Parser<U, Input> {
        return Parser<U, Input>(parse: { (input) -> Result<(U, Input), Error> in
            switch self.parse(input) {
            case .success(let (result, rest)):
                let p = f(result)
                return p.parse(rest)
            case .failure(let error):
                return .failure(error)
            }
        })
    }
    
    func apply<U>(_ parser: Parser<(Output) -> U, Input>) -> Parser<U, Input> {
        return Parser<U, Input>(parse: { (input) -> Result<(U, Input), Error> in
            let lResult = parser.parse(input)
            guard let l = lResult.value else {
                return .failure(lResult.error ?? ParseError.unknow)
            }
            let rResult = self.parse(l.1)
            guard let r = rResult.value else {
                return .failure(rResult.error ?? ParseError.unknow)
            }
            return .success((l.0(r.0), r.1))
        })
    }
    
    func or(_ parser: Parser<Output, Input>) -> Parser<Output, Input> {
        return Parser<Output, Input>(parse: { (input) -> Result<(Output, Input), Error> in
            let result = self.parse(input)
            switch result {
            case .success(_):
                return result
            case .failure(_):
                return parser.parse(input)
            }
        })
    }
    
    func rightSequence<U>(_ parser: Parser<U, Input> ) -> Parser<U, Input> {
        return Parser<U, Input>(parse: { (input) -> Result<(U, Input), Error> in
            let lResult = self.parse(input)
            guard let l = lResult.value else {
                return .failure(lResult.error ?? ParseError.unknow)
            }
            let rResult = parser.parse(l.1)
            guard let r = rResult.value else {
                return .failure(rResult.error ?? ParseError.unknow)
            }
            return .success(r)
        })
    }
    
}

// 顺序执行保留右值
func keepRight<T, U, S>(_ l: Parser<T, S>, r: Parser<U, S>) -> Parser<U, S> {
    return Parser<U, S>(parse: { (input) -> Result<(U, S), Error> in
        let lResult = l.parse(input)
        guard let l = lResult.value else {
            return .failure(lResult.error ?? ParseError.unknow)
        }
        let rResult = r.parse(l.1)
        guard let r = rResult.value else {
            return .failure(rResult.error ?? ParseError.unknow)
        }
        return .success(r)
    })
}

// 顺序执行保留左值
func keepLeft<T, U, S>(_ l: Parser<T, S>, r: Parser<U, S>) -> Parser<T, S> {
    return Parser<T, S>(parse: { (input) -> Result<(T, S), Error> in
        let lResult = l.parse(input)
        guard let l = lResult.value else {
            return .failure(lResult.error ?? ParseError.unknow)
        }
        let rResult = r.parse(l.1)
        guard let r = rResult.value else {
            return .failure(rResult.error ?? ParseError.unknow)
        }
        return .success((l.0, r.1))
    })
}

/// 将parser传入返回为新的parser
func lazy<T, U>(_ parser: @autoclosure @escaping () -> Parser<T, U>) -> Parser<T, U> {
    return Parser<T, U> { parser().parse($0) }
}

/// Map
func <^> <T, U, S> (f: @escaping (T) -> U, c: Parser<T, S>) -> Parser<U, S> {
    return c.map(f)
}

/// apply
func <*> <T, U, S> (l: Parser<(T) -> U, S>, r: Parser<T, S>) -> Parser<U, S> {
    return r.apply(l)
}

/// alternate
func <|> <T, S> (l: Parser<T, S>, r: Parser<T, S>) -> Parser<T, S> {
    return l.or(r)
}

/// right sequence
func *> <T, U, S>(l: Parser<T, S>, r: Parser<U, S>) -> Parser<U, S> {
    return keepRight(l, r: r)
}

/// left sequence
func <* <T, U, S>(l: Parser<T, S>, r: Parser<U, S>) -> Parser<T, S> {
    return keepLeft(l, r: r)
}

extension Parser {

    
    /// 在parse成功后不消耗输入
    func lookAhead() -> Parser<Output, Input> {
        return Parser(parse: { (input) -> Result<(Output, Input), Error> in
            switch self.parse(input) {
            case .success(let (result, _)):
                return .success((result, input))
            case .failure(let error):
                return .failure(error)
            }
        })
    }
    
    /// 返回相反的parse，成功时result为nil
    func not() -> Parser<Output?, Input> {
        return Parser<Output?, Input>(parse: { (input) -> Result<(Output?, Input), Error> in
            switch self.parse(input) {
            case .success(_):
                return .failure(ParseError.unknow)
            case .failure(_):
                return .success((nil, input))
            }
        })
    }
    
    func many() -> Parser<[Output], Input> {
        return Parser<[Output], Input>(parse: { (input) -> Result<([Output], Input), Error> in
            var results = [Output]()
            var rest = input
            while true {
                switch self.parse(rest) {
                case .success(let (result, left)):
                    results.append(result)
                    rest = left
                case .failure(_):
                    return .success((results.compactMap{$0}, rest))
                }
            }
        })
    }
    
    func Least1() -> Parser<[Output], Input> {
        return Parser<[Output], Input>(parse: { (input) -> Result<([Output], Input), Error> in
            var results = [Output]()
            var rest = input
            while true {
                switch self.parse(rest) {
                case .success(let (result, left)):
                    results.append(result)
                    rest = left
                case .failure(let error):
                    if results.count == 0 {
                        return .failure(error)
                    }else {
                        return .success((results.compactMap{$0}, rest))
                    }
                }
            }
        })
    }
}
