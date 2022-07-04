import Foundation
import Files

final class Markdown {
    private var path: String
    private var dictinary: [String: [File]]
    private var isVerbose: Bool
    private var totalCount: Int
    private let swiftUIKey = "swiftUI"
    private let decimalPoint: Int
    
    init(path: String, dictinary: [String: [File]], isVerbose: Bool, totalCount: Int, decimalPoint: Int) {
        self.path = path
        self.dictinary = dictinary
        self.isVerbose = isVerbose
        self.totalCount = totalCount
        self.decimalPoint = decimalPoint
    }
    
    func write() throws {
        var text: [String] = []
        text.append("|Language  |Files  |Number of steps  |Number of words  |Percentage  |")
        text.append("|---|---|---|---|---|")
        
        let keys = dictinary.keys.sorted()
        var totalWordsCount = 0
        var totalStepsCount = 0
        keys.forEach { key in
            let steps = dictinary[key]?.lazy.reduce(0) { result, file in
                let text = (try? file.readAsString()) ?? ""
                let lines = text.components(separatedBy: .newlines)
                return lines.count + (result ?? 0)
            } ?? 0
            
            let words = dictinary[key]?.lazy.reduce(0) { result, file in
                let textCount: Int = (try? file.readAsString().count) ?? 0
                return textCount + (result ?? 0)
            } ?? 0
            
            let value = dictinary[key] ?? []
            if key == swiftUIKey {
                let swiftTotalCount = dictinary["swift"]?.count ?? 0
                let percentage: Double = (Double(value.count) / Double(swiftTotalCount)) * 100
                if (decimalPoint > 0) {
                    let decimalNumber = NSDecimalNumber(decimal: pow(10, decimalPoint))
                    let numRound = round(percentage * decimalNumber.doubleValue) / decimalNumber.doubleValue
                    text.append("|\(key)  |\(value.count)  |\(steps) |\(words) |\(numRound)% (swiftUI / swift) |")

                } else {
                    text.append("|\(key)  |\(value.count)  |\(steps) |\(words) |\(percentage)% (swiftUI / swift) |")
                }
            } else {
                totalWordsCount += words
                totalStepsCount += steps
                let percentage: Double = (Double(value.count) / Double(totalCount)) * 100
                if (decimalPoint > 0) {
                    let decimalNumber = NSDecimalNumber(decimal: pow(10, decimalPoint))
                    let numRound = round(percentage * decimalNumber.doubleValue) / decimalNumber.doubleValue
                    text.append("|\(key)  |\(value.count)  |\(steps)  |\(words)  | \(numRound)%|")

                } else {
                    text.append("|\(key)  |\(value.count)  |\(steps)  |\(words)  | \(percentage)%|")

                }
            }
        }
        text.append("|**Total**  |**\(totalCount)** |**\(totalStepsCount)**  |**\(totalWordsCount)**  |100%  |")
        if isVerbose {
            print(text.joined(separator: "\n"))
        }
        let urlPath = URL(fileURLWithPath: path)
        let path = urlPath.deletingLastPathComponent().absoluteString
        let _path = path.replacingOccurrences(of: "file://", with: "")
        let fileName = urlPath.lastPathComponent
        let outputFolder = try Folder(path: _path)
        let file = try outputFolder.createFileIfNeeded(at: fileName.replacingOccurrences(of: "file://", with: ""))
        let result = text.joined(separator: "\n")
        let oldData = try file.readAsString()
        if oldData == result {
            print("Not writing the file as content is unchanged")
        } else {
            try file.write(result)
            print("Generate Success")
        }
    }
}
