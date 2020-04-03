//
//  MiscellaneousFunctions.swift
//  EngagementSDK
//

func editInPlace<T>(_ value: inout T, editBlock: (inout T) -> Void) {
    editBlock(&value)
}
