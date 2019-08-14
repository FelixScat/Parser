//
//  ObjCTypeParser.swift
//  Tracer
//
//  Created by Felix on 2019/8/13.
//

import Foundation
import LLexer
import Runes

var p_ocinterface: TokenParser<Token> {
    return parser_token(.atInterface)
}

var p_ocimplement: TokenParser<Token> {
    return parser_token(.atImplementation)
}

var p_name: TokenParser<Token> {
    return parser_token(.name)
}

var string: (Token?) -> String {
    return {token in
        guard let token = token else { return "" }
        return token.text
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

