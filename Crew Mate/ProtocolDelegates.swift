//
//  ProtocolDelegates.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/12/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import Foundation


//Equipment Delegate
protocol EquipmentDelegate {
    func equimentDelegate(boat: Equipment?, oar: Equipment?)
}

//New Member Delegate
protocol NewMemberDelegate {
    func newMember(member: CrewMember)
}
