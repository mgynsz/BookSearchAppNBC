//
//  Numeric.swift
//  TicketKing
//
//  Created by David Jang on 4/22/24.
//

import Foundation

// Int -> String
extension Numeric {
    var formattedWithSeparator: String {
        return Formatter.withSeparator.string(for: self) ?? ""
    }
}
