//
//  TokenParser.swift
//  Tracer
//
//  Created by Felix on 2019/8/13.
//

import Foundation
import LLexer
import Runes

public typealias TokenParser<T> = Parser<T, [Token]>

extension Parser where Input == [Token] {
    
    public var repeats: TokenParser<[Output]> {
        return TokenParser<[Output]>(parse: { (tokens) -> ParseResult<([Output], [Token])> in
            var results = [Output]()
            var list = tokens
            while list.count > 0 {
                switch self.parse(list) {
                case .success(let (token, rest)):
                    results.append(token)
                    list = rest
                case .failure(_):
                    //                    #if DEBUG
                    //                    print(error)
                    //                    #endif
                    list = Array(list.dropFirst())
                    continue
                }
            }
            return .success((results, list))
        })
    }
}

public func parser_token(_ type: TokenType) -> TokenParser<Token> {
    return TokenParser(parse: { (tks) -> ParseResult<(Token, [Token])> in
        guard let token = tks.first, token.type == type else {
            return .failure(.notMatch)
        }
        return .success((token, Array(tks.dropFirst())))
    })
}

func => <T, U> (p: Parser<T, [Token]>, f: @escaping (T) -> U) -> Parser<U, [Token]> {
    return p.map(f)
}

infix operator => : RunesApplicativeSequencePrecedence

