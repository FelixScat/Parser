//
//  TokenParser.swift
//  Tracer
//
//  Created by Felix on 2019/8/13.
//

import Foundation
import LLexer

public typealias TokenParser<T> = Parser<T, [Token]>

extension Parser where Input == [Token] {
    
    public var repeats: TokenParser<[Output]> {
        return TokenParser<Output>(parse: { (tokens) -> ParseResult<([Output], [Token])> in
            var results = [Output]()
            var list = tokens
            while list
        })
    }
}

public func tokenParser(_ type: TokenType) -> TokenParser<Token> {
    return TokenParser(parse: { (tks) -> ParseResult<(Token, [Token])> in
        guard let token = tks.first, token.type == type else {
            return .failure(.notMatch)
        }
        return .success((token, Array(tks.dropFirst())))
    })
}


