//
//  BoxBinding.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 11.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import Foundation

class BoxBinding<T> {
    typealias Listener = (T) -> Void
    var listener : Listener?
    
    var value : T {
        didSet{
            //print("in didSet")
            listener?(value) //call the listener if it exists
        }
    }
    
    init(_ value : T){
        self.value = value
    }
    
    func bind(listener: Listener?){
        print("in bind func")
        self.listener = listener
        //listener?(value)
    }
    
}
