//
//  WeatherView.swift
//  HistoricalWeather
//
//  Created by Tom Pusateri on 1/21/23.
//

import SwiftUI
import Charts


struct PlainGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center) {
            configuration.label
            configuration.content
        }
    }
}

struct TempFrequency: Decodable {
    var temp: Double
    let count: Int32

    var adjustedTemp: Double {
        let ms = Locale.current.measurementSystem
        if ms == .us {
            return Double(temp)
        }
        let temperature = Measurement<UnitTemperature>(value: Double(temp), unit: .fahrenheit)
        return temperature.converted(to: .celsius).value
    }
}

struct PlotRange: Decodable {
    let minXTemp: Int32
    let maxXTemp: Int32
    let maxYPercent: Int32
}

struct Reading: Decodable {
    let tempLow: Int32
    let tempHigh: Int32
    let tempMean: Int32
    let feelsLikeLow: Int32
    let feelsLikeHigh: Int32
    let feelsLikeMean: Int32
    let windSpeedLow: Int32
    let windSpeedHigh: Int32
    let windSpeedMean: Int32
    let humidityLow: Int32
    let humidityHigh: Int32
    let humidityMean: Int32
}

struct Historical: Decodable {
    let range: PlotRange
    let temps: [TempFrequency]
    let reading: Reading
}

struct WeatherView: View {
    @Environment(\.horizontalSizeClass) var hSizeClass
    @ObservedObject var meeting: Meeting

    @State var weekFormatter: DateFormatter

    init(meeting: Meeting) {
        self.meeting = meeting

        let formatter = DateFormatter()
        if Locale.current.measurementSystem == .us {
            formatter.dateFormat = "MMMM dd"
        } else {
            formatter.dateFormat = "dd MMMM"
        }
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: meeting.time_zone!)
        formatter.locale = Locale.current

        _weekFormatter = State(initialValue: formatter)
    }

    var data: [String: Historical] = [
        "114": Historical(
            range: PlotRange(minXTemp: 65, maxXTemp: 95, maxYPercent: 10),
            temps: [
            .init(temp: 80, count: 4),
            .init(temp: 79, count: 5),
            .init(temp: 78, count: 5),
            .init(temp: 77, count: 10),
            .init(temp: 81, count: 3),
            .init(temp: 82, count: 3),
            .init(temp: 84, count: 3),
            .init(temp: 86, count: 2),
            .init(temp: 87, count: 2),
            .init(temp: 89, count: 1),
            .init(temp: 85, count: 3),
            .init(temp: 83, count: 3),
            .init(temp: 75, count: 7),
            .init(temp: 74, count: 6),
            .init(temp: 73, count: 8),
            .init(temp: 72, count: 6),
            .init(temp: 71, count: 4),
            .init(temp: 76, count: 5),
            .init(temp: 88, count: 2),
            .init(temp: 70, count: 3),
            .init(temp: 68, count: 3),
            .init(temp: 67, count: 2),
            .init(temp: 66, count: 1),
            .init(temp: 69, count: 2),
            .init(temp: 65, count: 0),
            .init(temp: 91, count: 1),
            .init(temp: 90, count: 1),
            .init(temp: 92, count: 1),
            .init(temp: 93, count: 1),
            .init(temp: 94, count: 1),
            .init(temp: 95, count: 0),
            ],
            reading:
                Reading(
                    tempLow: 65,
                    tempHigh: 95,
                    tempMean: 77,
                    feelsLikeLow: 65,
                    feelsLikeHigh: 99,
                    feelsLikeMean: 79,
                    windSpeedLow: 0,
                    windSpeedHigh: 23,
                    windSpeedMean: 8,
                    humidityLow: 29,
                    humidityHigh: 100,
                    humidityMean: 73
                )
            ),
        "115": Historical(
            range: PlotRange(minXTemp: 34, maxXTemp: 62, maxYPercent: 10),
            temps: [
            .init(temp: 44, count: 4),
            .init(temp: 43, count: 3),
            .init(temp: 42, count: 2),
            .init(temp: 41, count: 2),
            .init(temp: 40, count: 2),
            .init(temp: 49, count: 8),
            .init(temp: 50, count: 8),
            .init(temp: 48, count: 9),
            .init(temp: 45, count: 4),
            .init(temp: 38, count: 2),
            .init(temp: 37, count: 1),
            .init(temp: 36, count: 1),
            .init(temp: 35, count: 1),
            .init(temp: 34, count: 0),
            .init(temp: 51, count: 5),
            .init(temp: 52, count: 4),
            .init(temp: 47, count: 5),
            .init(temp: 53, count: 8),
            .init(temp: 46, count: 6),
            .init(temp: 39, count: 1),
            .init(temp: 54, count: 6),
            .init(temp: 55, count: 8),
            .init(temp: 57, count: 2),
            .init(temp: 58, count: 2),
            .init(temp: 59, count: 1),
            .init(temp: 56, count: 4),
            .init(temp: 61, count: 0),
            .init(temp: 60, count: 1),
            .init(temp: 62, count: 0),
            ],
            reading:
                Reading(
                    tempLow: 34,
                    tempHigh: 62,
                    tempMean: 49,
                    feelsLikeLow: 52,
                    feelsLikeHigh: 62,
                    feelsLikeMean: 55,
                    windSpeedLow: 0,
                    windSpeedHigh: 0,
                    windSpeedMean: 0,
                    humidityLow: 49,
                    humidityHigh: 99,
                    humidityMean: 85
                )
            ),
        "116": Historical(
            range: PlotRange(minXTemp: 37, maxXTemp: 73, maxYPercent: 12),
            temps: [
            .init(temp: 54, count: 9),
            .init(temp: 52, count: 10),
            .init(temp: 50, count: 7),
            .init(temp: 48, count: 5),
            .init(temp: 55, count: 7),
            .init(temp: 57, count: 7),
            .init(temp: 61, count: 11),
            .init(temp: 63, count: 11),
            .init(temp: 64, count: 7),
            .init(temp: 59, count: 9),
            .init(temp: 66, count: 6),
            .init(temp: 68, count: 2),
            .init(temp: 70, count: 1),
            .init(temp: 72, count: 0),
            .init(temp: 73, count: 0),
            .init(temp: 46, count: 4),
            .init(temp: 45, count: 2),
            .init(temp: 43, count: 2),
            .init(temp: 41, count: 1),
            .init(temp: 39, count: 0),
            .init(temp: 37, count: 1),
            ],
            reading:
                Reading(
                    tempLow: 37,
                    tempHigh: 73,
                    tempMean: 57,
                    feelsLikeLow: 26,
                    feelsLikeHigh: 73,
                    feelsLikeMean: 56,
                    windSpeedLow: 0,
                    windSpeedHigh: 35,
                    windSpeedMean: 12,
                    humidityLow: 25,
                    humidityHigh: 100,
                    humidityMean: 68
                )
            ),
        "117": Historical(
            range: PlotRange(minXTemp: 53, maxXTemp: 82, maxYPercent: 12),
            temps: [
            .init(temp: 60, count: 6),
            .init(temp: 59, count: 10),
            .init(temp: 61, count: 8),
            .init(temp: 64, count: 6),
            .init(temp: 66, count: 4),
            .init(temp: 67, count: 7),
            .init(temp: 69, count: 2),
            .init(temp: 71, count: 2),
            .init(temp: 70, count: 3),
            .init(temp: 65, count: 3),
            .init(temp: 63, count: 3),
            .init(temp: 58, count: 11),
            .init(temp: 56, count: 9),
            .init(temp: 57, count: 6),
            .init(temp: 55, count: 6),
            .init(temp: 62, count: 4),
            .init(temp: 54, count: 2),
            .init(temp: 53, count: 0),
            .init(temp: 68, count: 3),
            .init(temp: 72, count: 1),
            .init(temp: 73, count: 2),
            .init(temp: 74, count: 1),
            .init(temp: 76, count: 0),
            .init(temp: 82, count: 0),
            .init(temp: 79, count: 0),
            .init(temp: 78, count: 0),
            .init(temp: 77, count: 0),
            .init(temp: 75, count: 0),
            ],
            reading:
                Reading(
                    tempLow: 53,
                    tempHigh: 82,
                    tempMean: 62,
                    feelsLikeLow: 53,
                    feelsLikeHigh: 81,
                    feelsLikeMean: 62,
                    windSpeedLow: 0,
                    windSpeedHigh: 26,
                    windSpeedMean: 12,
                    humidityLow: 36,
                    humidityHigh: 97,
                    humidityMean: 75
                )
            ),
        ]
    let columns = [
        GridItem(.adaptive(minimum: 170))
    ]

    private func tempUnits() -> String {
        if Locale.current.measurementSystem == .metric || Locale.current.measurementSystem == .uk {
            return " °C"
        }
        return " °F"
    }

    private func adjustTemp(_ value: Int32) -> Double {
        if Locale.current.measurementSystem == .metric || Locale.current.measurementSystem == .uk {
            return (Double(value) - 32.0) * 5.0 / 9.0
        }
        return Double(value)
    }

    private func adjustTempFrequencies(_ values: [TempFrequency]) -> [TempFrequency] {
        if Locale.current.measurementSystem == .metric || Locale.current.measurementSystem == .uk {
            let newValues = values.map { t in
                let newValue = (Double(t.temp) - 32.0) * 5.0 / 9.0
                return TempFrequency(temp: newValue, count:t.count)
            }
            return newValues
        }
        return values
    }

    private func adjustSpeed(_ value: Int32) -> String {
        if Locale.current.measurementSystem == .metric || Locale.current.measurementSystem == .uk {
            let kmh = Double(value) * 1.6
            return String(Int32(round(kmh))) + " km/h"
        }
        return String(value) + " mph"
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center, content: {
                if let h = data[meeting.number!] {
                    Text(meeting.city!)
                        .font(.title)
                        .bold()
                        .padding(.top)
                    Text("5-year historical data")
                        .font(.subheadline)
                    if let start = meeting.start {
                        Text("For the week of \(start, formatter: weekFormatter)")
                            .font(.subheadline)
                    }
                    GroupBox (
                        label:
                            Label("  % Time at Temperature  " + tempUnits(), systemImage: "thermometer.sun")
                                .font(.title3)
                                .padding(.bottom)
                    ) {
                        Chart {
                            let tfs = adjustTempFrequencies(h.temps)
                            ForEach(tfs, id: \.temp) { freq in
                                BarMark(
                                    x: .value("Temperature", freq.temp),
                                    y: .value("Frequency", freq.count),
                                    width: hSizeClass == .compact ? 2 : 20
                                )
                                .opacity(0.4)
                                .foregroundStyle(.green)
                            }
                        }
                        .padding(.leading, 5)
                        .chartXScale(domain: adjustTemp(h.range.minXTemp)...adjustTemp(h.range.maxXTemp))
                        .chartYScale(domain: 0...h.range.maxYPercent)
                        .frame(minWidth: 340, maxWidth: 760, minHeight: 160, maxHeight: 500, alignment: .center)
                        .padding(.bottom, 20)
                    }
                    .groupBoxStyle(PlainGroupBoxStyle())
                    .padding(.bottom, 10)
                    LazyVGrid(columns: columns) {
                        GroupBox {
                            VStack(alignment: .center) {
                                Label("Temp" + tempUnits() + ":", systemImage: "thermometer.sun")
                                    .font(.title3)
                                HStack {
                                    Text("Low:")
                                    Spacer()
                                    Text(verbatim: String(format: "%.0f", round(adjustTemp(h.reading.tempLow))))
                                }
                                HStack {
                                    Text("High:")
                                    Spacer()
                                    Text(verbatim: String(format: "%.0f", round(adjustTemp(h.reading.tempHigh))))
                                }
                                HStack {
                                    Text("Average:")
                                    Spacer()
                                    Text(verbatim: String(format: "%.0f", round(adjustTemp(h.reading.tempMean))))
                                }
                            }
                        }
                        GroupBox {
                            VStack(alignment: .center) {
                                Label("Feels Like" + tempUnits() + ":", systemImage: "thermometer.sun")
                                    .font(.title3)
                                HStack {
                                    Text("Low:")
                                    Spacer()
                                    Text(verbatim: String(format: "%.0f", round(adjustTemp(h.reading.feelsLikeLow))))
                                }
                                HStack {
                                    Text("High:")
                                    Spacer()
                                    Text(verbatim: String(format: "%.0f", round(adjustTemp(h.reading.feelsLikeHigh))))
                                }
                                HStack {
                                    Text("Average:")
                                    Spacer()
                                    Text(verbatim: String(format: "%.0f", round(adjustTemp(h.reading.feelsLikeMean))))
                                }
                            }
                        }
                        GroupBox {
                            VStack(alignment: .center) {
                                Label("Wind Speed:", systemImage: "wind")
                                    .font(.title3)
                                HStack {
                                    Text("Low:")
                                    Spacer()
                                    Text("\(adjustSpeed(h.reading.windSpeedLow))")
                                }
                                HStack {
                                    Text("High:")
                                    Spacer()
                                    Text("\(adjustSpeed(h.reading.windSpeedHigh))")
                                }
                                HStack {
                                    Text("Average:")
                                    Spacer()
                                    Text("\(adjustSpeed(h.reading.windSpeedMean))")
                                }
                            }
                        }
                        GroupBox {
                            VStack(alignment: .center) {
                                Label("Humidity:", systemImage: "humidity")
                                    .font(.title3)
                                HStack {
                                    Text("Low:")
                                    Spacer()
                                    Text("\(h.reading.humidityLow)%")
                                }
                                HStack {
                                    Text("High:")
                                    Spacer()
                                    Text("\(h.reading.humidityHigh)%")
                                }
                                HStack {
                                    Text("Average:")
                                    Spacer()
                                    Text("\(h.reading.humidityMean)%")
                                }
                            }
                        }
                    }
                    .frame(minWidth: 370, maxWidth: 760, minHeight: 0, maxHeight: 500, alignment: .center)
                } else {
                    Text("no history data")
                }
            })
        }
    }
}
