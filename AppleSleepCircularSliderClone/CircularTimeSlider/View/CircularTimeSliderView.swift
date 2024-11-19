import SwiftUI

struct CircularTimeSlider: View {
  @StateObject var viewModel = CircularTimeSliderViewModel()
  private var config: Config {
    viewModel.config
  }
  
  var inActiveCircleColor: Color = Color.gray
  var activeCircleColor: Color = Color.orange
  var textSecondaryColor: Color = Color.gray
  var textPrimaryColor: Color = Color.cyan
  var textTertiaryColor: Color = Color.orange
  var body: some View {
    ZStack {
      Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
      VStack(spacing: 32) {
        ZStack {
          Circle()
            .stroke(inActiveCircleColor, lineWidth: config.knobDiameter)
            .frame(width: config.diameter, height: config.diameter)
          Circle()
            .trim(from: 0, to: viewModel.connectorLength)
            .stroke(activeCircleColor, lineWidth: config.knobDiameter)
            .frame(width: config.diameter, height: config.diameter)
            .rotationEffect(Angle(degrees: viewModel.rotationStartTime - 90))

          ForEach((1 ... config.countSteps).reversed(), id: \.self) { i in
            RoundedRectangle(cornerRadius: 5)
              .frame(width: 3, height: config.knobRadius * 0.9)
              .foregroundColor(.black.opacity(0.3))
              .offset(y: config.radius)
              .rotationEffect(
                Angle(degrees: 360 / Double(config.countSteps) * Double(i))
              )
          }

          ForEach(1 ... (24 * 4), id: \.self) { i in
            RoundedRectangle(cornerRadius: 5)
              .frame(width: 2, height: i % 4 != 0 ? 4 : 8)
              .foregroundColor(textSecondaryColor)
              .offset(y: config.radius - (i % 4 != 0 ? 40 : 42))
              .rotationEffect(
                Angle(degrees: 360 / (24 * 4) * Double(i))
              )
          }

          ForEach(1 ... 24, id: \.self) { hour in
            ZStack {
              Text(String(getHourStringByInt(hour)))
                .fontWeight(.semibold)
                .font(.caption)
                .foregroundColor(textSecondaryColor)
                .rotationEffect(Angle(degrees: -(360.0 / 24 * Double(hour))))
            }
            .offset(y: -(config.radius - 65))
            .rotationEffect(Angle(degrees: 360.0 / 24 * Double(hour)))
            .gesture(
              DragGesture(minimumDistance: 0)
                .onChanged { action in
                  let angle = calcAngle(x: action.location.x, y: action.location.y)
                  let deltaRotation = angle - viewModel.rotationStartTime
                  viewModel.rotationStartTime += deltaRotation
                  viewModel.rotationEndTime += deltaRotation
                }
            )
          }

          // Knob - start Time
          getKnob(
            icon: Image(systemName: "clock"),
            iconRotation: -viewModel.rotationStartTime,
            isTapped: viewModel.didStartTimeTapped,
            rotate: false
          )
          .rotationEffect(Angle(degrees: viewModel.rotationStartTime))
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { action in
                let angle = calcAngle(x: action.location.x, y: action.location.y)
                viewModel.rotationStartTime = angle
              }
          )

          // Knob - EndTime
          getKnob(
            icon: Image(systemName: "flag"),
            iconRotation: -viewModel.rotationEndTime,
            isTapped: viewModel.didEndTimeTapped,
            rotate: true
          )
          .rotationEffect(Angle(degrees: viewModel.rotationEndTime))
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { action in
                let angle = calcAngle(x: action.location.x, y: action.location.y)
                viewModel.rotationEndTime = angle
              }
          )
        }
        VStack {
          Text(String(viewModel.getFormattedDuration()))
            .fontWeight(.bold)
            .font(.title2)
            .foregroundStyle(textPrimaryColor)

          HStack {
            VStack(spacing: 4) {
              Text("Start time".uppercased())
                .fontWeight(.semibold)
                .font(.caption)
                .foregroundStyle(textTertiaryColor)
              Text(viewModel.getStartTime())
                .font(.title3)
                .foregroundStyle(textPrimaryColor)
            }
            Spacer()
            VStack(spacing: 4) {
              Text("End time".uppercased())
                .fontWeight(.semibold)
                .font(.caption)
                .foregroundStyle(textTertiaryColor)
              Text(viewModel.getEndTime())
                .font(.title3)
                .foregroundStyle(textPrimaryColor)
            }
          }
          .padding(.horizontal)
          .padding(.top)
        }
      }
    }
    .onChange(of: viewModel.duration) {
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
  }

  func getHourStringByInt(_ i: Int) -> String {
    if i == 24 {
      return "0"
    }

    if i % 2 == 0 {
      return String(i)
    }

    return ""
  }

  func getKnob(icon: Image, iconRotation: Double, isTapped: Bool, rotate: Bool) -> some View {
    return ZStack {
      Circle()
        .trim(from: 0.25, to: 0.75)
        .foregroundColor(activeCircleColor)
        .rotationEffect(Angle(degrees: rotate ? 180 : 0))
      Circle()
        .foregroundColor(activeCircleColor)
        .padding(4)
      icon
        .foregroundColor(.white)
        .font(.system(size: config.knobRadius / 1.6))
        .bold()
        .rotationEffect(Angle(degrees: iconRotation))
    }
    .frame(width: config.knobDiameter, height: config.knobDiameter)
    .offset(y: -config.radius)
  }

  enum ChangeType {
    case STARTTIME
    case ENDTIME
    case CONNECTOR
  }

  func calcAngle(x: CGFloat, y: CGFloat) -> Double {
    let vector = CGVector(dx: x, dy: y)

    var angle = (atan2(
      vector.dy - config.knobRadius, vector.dx - config.knobRadius
    ) + .pi / 2) / .pi * 180

    if angle < 0 {
      angle += 360
    }

    return angle
  }

  func change(_ action: DragGesture.Value, _ type: ChangeType) {
    let angle = calcAngle(x: action.location.x, y: action.location.y)
    let minDistance = 20.0

    switch type {
    case ChangeType.STARTTIME:
      if viewModel.rotationEndTime - angle >= minDistance {
        viewModel.rotationStartTime = angle
      } else {
        viewModel.rotationEndTime = viewModel.rotationStartTime + minDistance
      }
    case ChangeType.ENDTIME:
      if angle - viewModel.rotationStartTime >= minDistance {
        viewModel.rotationEndTime = angle
      } else {
        viewModel.rotationStartTime = viewModel.rotationEndTime - minDistance
      }
    case .CONNECTOR:
      break
    }
  }
}

#Preview {
  CircularTimeSlider(viewModel: .init())
}
