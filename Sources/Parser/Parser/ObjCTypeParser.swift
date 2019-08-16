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


/// @interface
var p_ocinterface: TokenParser<Token> {
    return parser_token(.atInterface)
}

/// @implement
var p_ocimplement: TokenParser<Token> {
    return parser_token(.atImplementation)
}

/// @implement
var p_ocproperty: TokenParser<Token> {
    return parser_token(.atProperty)
}


/// @end
var p_ocEnd: TokenParser<Token> {
    return parser_token(.atEnd)
}

/// *
var p_name: TokenParser<Token> {
    return parser_token(.name)
}

/// :
var p_colon: TokenParser<Token> {
    return parser_token(.colon)
}

/// ;
var p_semicolon: TokenParser<Token> {
    return parser_token(.semicolon)
}

/// -
var p_minus: TokenParser<Token> {
    return parser_token(.minus)
}

/// +
var p_plus: TokenParser<Token> {
    return parser_token(.plus)
}

/// (
var p_openParen: TokenParser<Token> {
    return parser_token(.openParen)
}

/// )
var p_closeParen: TokenParser<Token> {
    return parser_token(.closeParen)
}

/// {
var p_openBrace: TokenParser<Token> {
    return parser_token(.openBrace)
}

/// }
var p_closeBrace: TokenParser<Token> {
    return parser_token(.closeBrace)
}

/// [
var p_openBracket: TokenParser<Token> {
    return parser_token(.openBracket)
}

/// ]
var p_closeBracket: TokenParser<Token> {
    return parser_token(.closeBracket)
}

/// <
var p_less: TokenParser<Token> {
    return parser_token(.less)
}

/// >
var p_greater: TokenParser<Token> {
    return parser_token(.greater)
}

/// 匹配任意包在括号、尖括号h之间的token
var p_enclosed:TokenParser<[Token]> {
    return tokens(enclosedBy: p_openBrace, r: p_closeBrace)
        <|> tokens(enclosedBy: p_openBracket, r: p_closeBracket)
        <|> tokens(enclosedBy: p_openParen, r: p_closeParen)
        <|> tokens(enclosedBy: p_less, r: p_greater)
}


/// 任意token
var p_anyToken: TokenParser<Token> {
    return Parser(parse: { (input) -> Result<(Token, [Token]), Error> in
        guard let result = input.first else {
            return .failure(ParseError.fileEnd)
        }
        return .success((result, Array(input.dropFirst())))
    })
}

/// option token to string
var string: (Token?) -> String {
    return {token in
        guard let token = token else { return "" }
        return token.text
    }
}

/// join
public func joined(by str: String) -> ([Token]) -> String {
    return {  tokens in
        return tokens.map { $0.text }.joined(separator: str)
    }
}

/// parser for ObjCInterface
public var parser_OCInterface: TokenParser<[ObjCInterface]> {
    
    let parser = curry(ObjCInterface.init)
        <^> p_ocinterface *> p_name => string
        <*> tokens(until: p_ocEnd).map{
            parser_OCProperty.repeats.run($0) ?? []
    }
    
    return parser.repeats
}

/// parser for ObjCImplement
public var parser_OCImplement: TokenParser<ObjCImplement> {
    
    let parser = curry(ObjCImplement.init)
        <^> p_ocimplement *> p_name => string
        <*> tokens(until: p_ocEnd).map {
            parser_OCMethodDefine.repeats.run($0) ?? []}
    
    return parser
}

/// parser for judge whether a method is static
public var parser_OCMethodStatically: TokenParser<Bool> {
    
    return p_minus *> pure(false) <|> p_plus *> pure(true)
}

/// parser for ObjCMethod return type
public var parser_OCMethodReturns: TokenParser<String> {
    return tokens(inside: p_openParen, r: p_closeParen) => joined(by: " ")
}

/// parser for parameters in ObjC method
public var parser_OCMethodParam: TokenParser<ObjCParam> {
    return curry(ObjCParam.init)
        <^> p_name <* p_colon => string
        <*> parser_OCMethodReturns
        <*> p_name => string
}

/// ⬆️ + s
public var parser_OCMethodParamList: TokenParser<[ObjCParam]> {
    return parser_OCMethodParam.Least1() <|> curry({[ObjCParam(name: $0.text, type: "", formalName: "")]}) <^> p_name
}

/// parser for ObjC method body
public var parser_OCMethodBody: TokenParser<[Token]> {
    return tokens(inside: p_openBrace, r: p_closeBrace)
}

/// parser for ObjC method definition
public var parser_OCMethodDefine: TokenParser<ObjCMethod> {
    
    let parser = curry(ObjCMethod.init)
        <^> parser_OCMethodStatically
        <*> parser_OCMethodReturns
        <*> parser_OCMethodParamList
        <*> ( {
            parser_OCInvokes.run($0) ?? []
            
            } <^> parser_OCMethodBody)
    return parser
}

/// parser for ObjC method Invoker
public var parser_OCInvoker: TokenParser<ObjCInvoker> {
    
    let toOtherInvoker: (ObjCInvoke) -> ObjCInvoker = { .otherInvoke($0) }
    let toVariable: (Token) -> ObjCInvoker = { .variable($0.text) }
    
    return lazy(parser_OCInvoke) => toOtherInvoker
        <|> p_name => toVariable
}

/// parser for ObjC method invokes parameters
public var parser_OCInvokeParams: TokenParser<[ObjCInvokeParam]> {
    /// 解析方法调用中参数的具体内容
    var paramBody: TokenParser<[ObjCInvoke]> {
        return {lazy(parser_OCInvoke).repeats.run($0) ?? []} <^> openTokens(until: p_closeBracket <|> p_name *> p_colon)
    }
    var param: TokenParser<ObjCInvokeParam> {
        return curry(ObjCInvokeParam.init)
            <^> (curry({ "\($0.text)\($1.text)" })
            <^> p_name <*> p_colon)
            <*> paramBody
    }
    let paramList = param.Least1() <|> { [ObjCInvokeParam(name: $0.text, invokes: [])] } <^> p_name
    return paramList
}


/// 解析方法调用 [xxx yyy:zzz aaa:[bbb ccc]]
public var parser_OCInvoke: TokenParser<ObjCInvoke> {
    let invoke = curry(ObjCInvoke.init)
        <^> parser_OCInvoker
        <*> parser_OCInvokeParams
    return invoke.between(p_openBracket, p_closeBracket)
}

/// ⬆️ + s
public var parser_OCInvokes: TokenParser<[ObjCInvoke]> {
    return parser_OCInvoke.repeats.map({ (invokes) -> [ObjCInvoke] in
        var results = invokes
        invokes.forEach{
            results.append(contentsOf: $0.params.reduce([]){
                $0 + $1.invokes
            })
        }
        return results
    })
}

public var parser_OCProperty: TokenParser<ObjCProperty> {
    
    let pt = curry(ObjCProperty.init)
        <^> p_ocproperty *> tokens(inside: p_openParen, r: p_closeParen) => joined(by: " ")
        <*> p_name => string
        <*> p_name => string <* tokens(until: p_semicolon)
        //        <*> tokens(until: p_semicolon)
    return pt
}
