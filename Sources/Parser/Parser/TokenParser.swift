//
//  TokenParser.swift
//  Tracer
//
//  Created by Felix on 2019/8/13.
//

import Foundation
import LLexer
import Runes
import Curry

public typealias TokenParser<T> = Parser<T, [Token]>

extension Parser where Input == [Token] {
    
    public var repeats: TokenParser<[Output]> {
        return TokenParser<[Output]>(parse: { (tokens) -> Result<([Output], [Token]), Error> in
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

public func pure<T>(_ result:T) -> TokenParser<T> {
    return TokenParser<T>.just(result)
}

public func parser_token(_ type: TokenType) -> TokenParser<Token> {
    return TokenParser(parse: { (tks) -> Result<(Token, [Token]), Error> in
        guard let token = tks.first, token.type == type else {
            return .failure(ParseError.notMatch)
        }
        return .success((token, Array(tks.dropFirst())))
    })
}


/// 返回包裹在 l & r 之前的tokens
public func tokens(enclosedBy l: TokenParser<Token>, r: TokenParser<Token>) -> TokenParser<[Token]> {
    let content = l.lookAhead() *> lazy(tokens(enclosedBy: l, r: r))
        <|> ({ [$0] }) <^> (r.not() *> p_anyToken)
    
    return curry({ [$0] + Array($1.joined()) + [$2] }) <^> l <*> content.many() <*> r
}

/// 返回包裹在 l & r 之前的tokens (去掉首尾)
func tokens(inside l: TokenParser<Token>, r: TokenParser<Token>) -> TokenParser<[Token]> {
    return tokens(enclosedBy: l, r: r).map{
        Array($0.dropFirst().dropLast())
    }
}

func => <T, U> (p: Parser<T, [Token]>, f: @escaping (T) -> U) -> Parser<U, [Token]> {
    return p.map(f)
}

infix operator => : RunesApplicativeSequencePrecedence

