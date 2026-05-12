import Foundation

/// 航班详细信息
struct FlightDetails {
    let flightNumber: String          // 如 "CA123"、"MU5147"、"9C1234"
    let departureAirport: String      // 如 "北京" 或 "北京首都国际机场"
    let arrivalAirport: String        // 如 "上海"
    let departureTerminal: String?    // 如 "T1"
    let arrivalTerminal: String?      // 预计的到达航站楼
    let timeRange: String             // 如 "10:30-13:45"
}

/// 航班信息解析器
/// 
/// 支持的航班号格式（正则表达式 [A-Z0-9]+）：
/// - 两字母 + 数字：CA123、MU1234、CA5678（标准格式）
/// - 数字 + 字母 + 数字：9C1234、3U8765、8L6666（新格式）
/// - 字母 + 多位数字：MU5147、BA12345（长航班号）
/// - 纯字母：BA、CZ、FM（机场代码级别）
/// - 纯数字：123、5678（极少见但支持）
/// - 任意长度：2-6+ 字符组合
///
/// 实际示例：
/// - ✅ 乘坐CA123 北京-上海 T1 当地时间10:30-13:45 【航旅纵横】
/// - ✅ 乘坐MU5147 北京-上海 T1 当地时间10:30-13:45 【航旅纵横】
/// - ✅ 乘坐9C1234 北京-上海 T1 当地时间10:30-13:45 【航旅纵横】
/// - ✅ 乘坐3U8765 北京-成都 T2 当地时间14:00-16:30 【航旅纵横】
struct FlightParser {
    /// 航旅纵横格式的正则表达式模式
    /// 
    /// 模式说明：
    /// ^乘坐(?<flight>[A-Z0-9]+)
    ///   - 匹配开头"乘坐"和航班号（支持字母和数字组合）
    /// \\s+(?<departure>[\\p{Han}A-Za-z0-9]+)-(?<arrival>[\\p{Han}A-Za-z0-9]+?)
    ///   - 匹配出发城市和到达城市（支持中文、英文、数字）
    /// (?:\\s*(?<depTerminal>T\\d+))?
    ///   - 可选的出发航站楼（如 T1、T2、T3）
    /// \\s+当地时间(?<timeRange>\\d{2}:\\d{2}-\\d{2}:\\d{2})
    ///   - 匹配时间范围（HH:MM-HH:MM）
    /// \\s+【航旅纵横】$
    ///   - 匹配结尾"【航旅纵横】"
    private static let pattern = "^乘坐(?<flight>[A-Z0-9]+)\\s+(?<departure>[\\p{Han}A-Za-z0-9]+)-(?<arrival>[\\p{Han}A-Za-z0-9]+?)(?:\\s*(?<depTerminal>T\\d+))?\\s+当地时间(?<timeRange>\\d{2}:\\d{2}-\\d{2}:\\d{2})\\s+【航旅纵横】$"
    
    /// 解析航旅纵横格式的航班信息
    /// - Parameter eventTitle: 日历事件标题
    /// - Returns: 解析成功返回 FlightDetails，否则返回 nil
    /// 
    /// 示例：
    /// ```
    /// let title = "乘坐MU5147 北京-上海 T1 当地时间10:30-13:45 【航旅纵横】"
    /// if let details = FlightParser.parseFlightEvent(title) {
    ///     print(details.flightNumber)  // "MU5147"
    ///     print(details.departureAirport)  // "北京"
    ///     print(details.arrivalAirport)  // "上海"
    /// }
    /// ```
    static func parseFlightEvent(_ eventTitle: String) -> FlightDetails? {
        guard !eventTitle.contains("[FLIGHT]") else {
            // 已经格式化过，跳过
            return nil
        }
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.useUnicodeWordBoundaries])
            let range = NSRange(eventTitle.startIndex..., in: eventTitle)
            
            guard let match = regex.firstMatch(in: eventTitle, options: [], range: range) else {
                return nil
            }
            
            // 提取各个捕获组
            func extractGroup(_ name: String) -> String? {
                let nsRange = match.range(withName: name)
                guard nsRange.location != NSNotFound,
                      let range = Range(nsRange, in: eventTitle) else {
                    return nil
                }
                return String(eventTitle[range])
            }
            
            guard let flight = extractGroup("flight"),
                  let departure = extractGroup("departure"),
                  let arrival = extractGroup("arrival"),
                  let timeRange = extractGroup("timeRange") else {
                return nil
            }
            
            let depTerminal = extractGroup("depTerminal")
            
            return FlightDetails(
                flightNumber: flight,
                departureAirport: departure,
                arrivalAirport: arrival,
                departureTerminal: depTerminal,
                arrivalTerminal: predictArrivalTerminal(for: flight),
                timeRange: timeRange
            )
        } catch {
            return nil
        }
    }
    
    /// 预测到达航站楼（基于常见配置）
    private static func predictArrivalTerminal(for flightNumber: String) -> String? {
        // 根据航班号推断到达航站楼
        // 这是一个简化的实现，实际可能需要更复杂的规则
        if let firstChar = flightNumber.first {
            switch firstChar {
            case "C":  // 国航
                return "T3"
            case "M":  // 厦航
                return "T3"
            case "B":  // 东航
                return "T2"
            case "D":  // 南航
                return "T2"
            default:
                return "T2"
            }
        }
        return nil
    }
    
    /// 将解析结果格式化为 Flighty 兼容格式
    /// - Parameters:
    ///   - details: 解析的航班信息
    /// - Returns: 格式化后的标题字符串
    static func formatFlightTitle(from details: FlightDetails) -> String {
        let depCode = AirportDictionary.mappedCode(for: details.departureAirport)
        let arrCode = AirportDictionary.mappedCode(for: details.arrivalAirport)
        
        var title = "[FLIGHT] \(details.flightNumber) \(depCode)-\(arrCode)"
        
        if let depTerminal = details.departureTerminal {
            title += " \(depTerminal)"
        }
        
        if let arrTerminal = details.arrivalTerminal {
            title += " \(arrTerminal)"
        }
        
        title += "｜Local Time \(details.timeRange) [CTZ]"
        
        return title
    }
}
