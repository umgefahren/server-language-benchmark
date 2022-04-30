//
//  MicrosecondPrecisionDateFormatter.swift
//  BenchmarkServer
//
//  Created by Josef Zoller on 13.04.22.
//

import Foundation


public final class MicrosecondPrecisionDateFormatter: DateFormatter {
    override public init() {
        super.init()
        self.locale = Locale(identifier: "en_US_POSIX")
        self.timeZone = TimeZone(secondsFromGMT: 0)
        self.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func string(from date: Date) -> String {
        let components = calendar.dateComponents([Calendar.Component.nanosecond], from: date)

        let nanosecondsInMicrosecond = 1000.0
        let microseconds = Int((Double(components.nanosecond!) / nanosecondsInMicrosecond).rounded(.toNearestOrEven))
        
        // Subtract nanoseconds from date to ensure string(from: Date) doesn't attempt faulty rounding.
        let updatedDate = calendar.date(byAdding: .nanosecond, value: -(components.nanosecond!), to: date)!
        let dateTimeString = super.string(from: updatedDate)
        
        let string = String(format: "%@.%06ldZ", dateTimeString, microseconds)

        return string
    }
    
    override public func date(from string: String) -> Date? {
        fatalError("Not implemented!")
    }
}
