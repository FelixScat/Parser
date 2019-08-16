//
//  ObjCTypeNode.swift
//  Tracer
//
//  Created by Felix on 2019/8/13.
//

import Foundation

public struct ObjCProperty {
    public var decorate: String?
    public var type = ""
//    public var isObjectType = false
    public var propertyName = ""
}

/// ObjC 接口
public struct ObjCInterface {
    public var name: String
    public var properties: [ObjCProperty] = []
}

/// ObjC 实现
public struct ObjCImplement {
    public var name = ""
    public var methods: [ObjCMethod] = []
}

/// ObjC 方法
public struct ObjCMethod {
    /// 是否为静态方法
    public var statically = false
    /// 返回类型
    public var returnType = ""
    /// 参数列表
    public var params: [ObjCParam] = []
    /// 方法体中的方法调用
    public var invokes: [ObjCInvoke] = []
}

/// ObjC 方法参数
public struct ObjCParam {
    /// 参数名
    public var name: String
    /// 参数类型
    public var type: String
    /// 形参名
    public var formalName: String
}

/// 方法调用者
public indirect enum ObjCInvoker {
    case variable(String)
    case otherInvoke(ObjCInvoke)
}

/// 方法调用的参数
public struct ObjCInvokeParam {
    /// 参数名
    public var name: String
    /// 参数中的其他方法调用
    public var invokes: [ObjCInvoke]
}

/// 方法调用
public struct ObjCInvoke {
    public var invoker: ObjCInvoker
    public var params: [ObjCInvokeParam]
}






