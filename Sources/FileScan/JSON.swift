import Foundation
import Files

final class JSON {
    private var path: String
    private var dictinary: [String: [File]]
    private var isVerbose: Bool
    private var totalCount: Int
    private let swiftUIKey = "swiftUI"
    
    init(path: String, dictinary: [String: [File]], isVerbose: Bool, totalCount: Int) {
        self.path = path
        self.dictinary = dictinary
        self.isVerbose = isVerbose
        self.totalCount = totalCount
    }
    
    func write() throws {
        var text: [String] = []
        text.append("|Language  |Files  |Number of steps  |Number of words  |Percentage  |")
        
        let keys = dictinary.keys.sorted()
        var totalWordsCount = 0
        var totalStepsCount = 0
        var json: [String: Any] = [:]
        keys.forEach { key in
            var dict: [String: Any] = [:]
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
            dict["files"] = value.count
            dict["number_of_steps"] = steps
            dict["number_of_words"] = words

            if key == swiftUIKey {
                let swiftTotalCount = dictinary["swift"]?.count ?? 0
                let percentage: Double = (Double(value.count) / Double(swiftTotalCount)) * 100
                let numRound = round(percentage * 10) / 10
                dict["percentage"] = numRound
            } else {
                totalWordsCount += words
                totalStepsCount += steps
                let percentage: Double = (Double(value.count) / Double(totalCount)) * 100
                let numRound = round(percentage * 10) / 10
                dict["percentage"] = numRound
            }
            json[key] = dict
        }
        
        var dict: [String: Any] = [:]
        dict["files"] = totalCount
        dict["number_of_steps"] = totalStepsCount
        dict["number_of_words"] = totalWordsCount
        dict["percentage"] = 100
        json["total"] = dict
        
        let urlPath = URL(fileURLWithPath: path)
        let path = urlPath.deletingLastPathComponent().absoluteString
        let _path = path.replacingOccurrences(of: "file://", with: "")
        let fileName = urlPath.lastPathComponent
        let outputFolder = try Folder(path: _path)
        let file = try outputFolder.createFileIfNeeded(at: fileName.replacingOccurrences(of: "file://", with: ""))
        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        let result = String(data: data, encoding: .utf8)!
        if isVerbose {
            print(result)
        }
        let oldData = try file.readAsString()
        if oldData == result {
            print("Not writing the file as content is unchanged")
        } else {
            try file.write(result)
            print("Generate Success")
        }
    }
}
