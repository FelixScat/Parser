//
//  ObjCTypeNode.swift
//  Tracer
//
//  Created by Felix on 2019/8/13.
//

import Foundation


/// ObjC 接口
public struct ObjCInterface {
    var name: String
}

/// ObjC 实现
public struct ObjCImplement {
    var name = ""
}

/// ObjC 方法
public struct ObjCMethod {
    /// 是否为静态方法
    var statically = false
    /// 返回类型
    var returnType = ""
    /// 参数列表
    var params: [ObjCParam] = []
}

/// ObjC 方法参数
public struct ObjCParam {
    /// 参数名
    var name: String
    /// 参数类型
    var type: String
    /// 形参名
    var formalName: String
}
