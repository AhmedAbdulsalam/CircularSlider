import Combine
import SwiftUI

final class CircularTimeSliderViewModel: ObservableObject {
  @Published var rotationStartTime: Double = 0.0
  @Published var rotationEndTime: Double = 90.0
  @Published var didEndTimeTapped: Bool = false
  @Published var didStartTimeTapped: Bool = false
  @Published var selectedDate = Date()

  let config: Config = .init(
    radius: 130.0,
    knobRadius: 20.0,
    minDurationTime: 1.0,
    countSteps: 24 * 60 / 10
  )

  // Map rotation to time based on degrees
  func mapRotationToTime(degrees: Double) -> Double {
    return (24.0 / 360.0) * degrees
  }

  var startDate: Date? {
    selectedDate.updateDateWithTime(timeString: getStartTime())
  }

  // Calculate the total duration
  var totalDuration: Double {
    let start = mapRotationToTime(degrees: rotationStartTime)
    var end = mapRotationToTime(degrees: rotationEndTime)
    if start > end {
      end += 24
    }
    return end - start
  }

  var duration: String {
    formattedDurationBetweenTimes(startTime: getStartTime(), endTime: getEndTime()) ?? getEndTime()
  }

  // Get formatted duration
  func getFormattedDuration() -> String {
    let duration = totalDuration
    let hours = Int(duration)
    var minutes = Int((duration - Double(hours)) * 60)

    // Round minutes down to the nearest 5
    while minutes % 5 != 0 {
      minutes -= 1
    }

    return hours > 0 ? "\(hours) hr \(minutes) min" : "\(minutes) min"
  }

  // Calculate connector length for drawing the arc between start and end times
  var connectorLength: Double {
    let start = rotationStartTime
    let end = rotationEndTime
    if start > end {
      return (360 - start + end) / 360.0
    }
    return (end - start) / 360.0
  }

  // Get formatted start and end times
  func getStartTime() -> String {
    return formatTimeForRotation(rotation: rotationStartTime)
  }

  func getEndTime() -> String {
    return formatTimeForRotation(rotation: rotationEndTime)
  }

  private func formatTimeForRotation(rotation: Double) -> String {
    let totalHours = mapRotationToTime(degrees: rotation)
    let hours = Int(totalHours)
    var minutes = Int((totalHours - Double(hours)) * 60)

    // Round minutes down to the nearest 5
    while minutes % 5 != 0 {
      minutes -= 1
    }

    let hourStr = hours < 10 ? "0\(hours)" : "\(hours)"
    let minuteStr = minutes < 10 ? "0\(minutes)" : "\(minutes)"
    return "\(hourStr):\(minuteStr)"
  }

  func formattedDurationBetweenTimes(startTime: String, endTime: String) -> String? {
    // Create a DateFormatter to parse the time
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm"

    // Parse the start and end time
    guard let startDateTime = timeFormatter.date(from: startTime),
          let endDateTime = timeFormatter.date(from: endTime) else {
      print("Invalid time format")
      return nil
    }

    // Calculate the duration
    var duration = endDateTime.timeIntervalSince(startDateTime)

    // If the duration is negative, adjust for the next day
    if duration < 0 {
      duration += 24 * 60 * 60
    }

    // Calculate hours, minutes, and seconds
    let hours = Int(duration / 3600)
    let minutes = Int((duration / 60).truncatingRemainder(dividingBy: 60))
    let seconds = Int(duration.truncatingRemainder(dividingBy: 60))

    // Format duration as a string HH:mm:ss
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }
}

extension Date {
  func updateDateWithTime(timeString: String) -> Date? {
    // Create a calendar and configure the time zone if needed
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone // or use any specific timezone

    // Parse the hour and minute from the time string
    let timeComponents = timeString.split(separator: ":")
    guard timeComponents.count == 2,
          let hour = Int(timeComponents[0]),
          let minute = Int(timeComponents[1])
    else {
      print("Invalid time format")
      return nil
    }

    // Extract the year, month, and day from the original date
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: self)

    // Combine the date and time components
    var newComponents = DateComponents()
    newComponents.year = dateComponents.year
    newComponents.month = dateComponents.month
    newComponents.day = dateComponents.day
    newComponents.hour = hour
    newComponents.minute = minute
    newComponents.timeZone = calendar.timeZone

    // Create the new date with updated time
    return calendar.date(from: newComponents)
  }
}


struct Config {
  let radius: CGFloat
  let knobRadius: CGFloat
  // the smallest amount of duration hours , you can configure
  let minDurationTime: CGFloat
  // 24 hours in minutes, seperated in 15 minute blocks
  let countSteps: Int

  var diameter: CGFloat {
    return radius * 2
  }

  var knobDiameter: CGFloat {
    return knobRadius * 2
  }
}
