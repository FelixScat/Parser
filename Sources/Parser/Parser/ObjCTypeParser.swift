//
//  ObjCTypeParser.swift
//  Tracer
//
//  Created by Felix on 2019/8/13.
//

import Foundation
import LLexer
import Runes
import Curry

var p_ocinterface: TokenParser<Token> {
    return parser_token(.atInterface)
}

var p_ocimplement: TokenParser<Token> {
    return parser_token(.atImplementation)
}

var p_name: TokenParser<Token> {
    return parser_token(.name)
}

var p_colon: TokenParser<Token> {
    return parser_token(.colon)
}

var p_minus: TokenParser<Token> {
    return parser_token(.minus)
}

var p_plus: TokenParser<Token> {
    return parser_token(.plus)
}

var p_openParen: TokenParser<Token> {
    return parser_token(.openParen)
}

var p_closeParen: TokenParser<Token> {
    return parser_token(.closeParen)
}

var p_anyToken: TokenParser<Token> {
    return Parser(parse: { (input) -> Result<(Token, [Token]), Error> in
        guard let result = input.first else {
            return .failure(ParseError.fileEnd)
        }
        return .success((result, Array(input.dropFirst())))
    })
}

var string: (Token?) -> String {
    return {token in
        guard let token = token else { return "" }
        return token.text
    }
}

public func joined(by str: String) -> ([Token]) -> String {
    return {  tokens in
        return tokens.map { $0.text }.joined(separator: str)
    }
}


public var parser_OCInterface: TokenParser<[ObjCInterface]> {
    
    let parser = ObjCInterface.init
        <^> p_ocinterface
        *> p_name
        => string
    
    return parser.repeats
}

public var parser_OCImplement: TokenParser<[ObjCImplement]> {
    
    let parser = ObjCImplement.init
        <^> p_ocimplement
        *> p_name
        => string
    
    return parser.repeats
}

public var parser_OCMethodStatically: TokenParser<Bool> {
    
    return p_minus *> pure(false) <|> p_plus *> pure(true)
}

public var parser_OCMethodReturns: TokenParser<String> {
    return tokens(inside: p_openParen, r: p_closeParen) => joined(by: " ")
}

public var parser_OCMethodParam: TokenParser<ObjCParam> {
    return curry(ObjCParam.init)
        <^> p_name <* p_colon => string
        <*> parser_OCMethodReturns
        <*> p_name => string
}

public var parser_OCMethodParamList: TokenParser<[ObjCParam]> {
    return parser_OCMethodParam.Least1() <|> curry({[ObjCParam(name: $0.text, type: "", formalName: "")]}) <^> p_name
}

public var parser_OCMethodDefine: TokenParser<ObjCMethod> {
    
    let parser = curry(ObjCMethod.init)
        <^> parser_OCMethodStatically
        <*> parser_OCMethodReturns
        <*> parser_OCMethodParamList
    return parser
}

extension Parser {
    
}
