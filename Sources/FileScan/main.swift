import Foundation
import Commander
import Files

let main = command(
    Option<String>("sourcePath", default: ".", description: "parse file paths"),
    Option<String?>("output_path", default: nil, description: "out put files"),
    Option<String?>("ignore_paths", default: nil, description: "ignore files"),
    Option<String>("verbose", default: "false", description: "Display the log")
) { sourcePath, output_path, ignore_paths, verbose in
    let isVerbose = verbose.lowercased() == "true"
    do {
        let folder = try Folder(path: sourcePath)
        var files = find(folder: folder)
        files.append(contentsOf: folder.files)
        if let ignore_paths = ignore_paths {
            let ignorePaths = ignore_paths.split(separator: ",")
            ignorePaths.forEach { path in
                files = files.filter { !$0.path.contains(path)}
            }
        }
        
        var text: [String] = []
        text.append("|Language  |files  |code  |percentage  |")
        text.append("|---|---|---|---|")
        var dic: [String: [File]] = [:]
        files.forEach { file in
            guard let extensionValue = file.extension else {
                return
            }
            if var value = dic[extensionValue] {
                value.append(file)
                dic[extensionValue] = value
            } else {
                dic[extensionValue] = [file]
            }
        }
        let keys = dic.keys.sorted()
        let totalCount = files.count
        keys.forEach { key in
            let code = dic[key]?.reduce(0) { result, file in
                return (try? file.readAsString().count) ?? 0 + result
            } ?? 0
            let value = dic[key] ?? []
            let percentage: Double = (Double(value.count) / Double(totalCount)) * 100
            let numRound = round(percentage * 10) / 10
            text.append("|\(key)  |\(value.count)  | \(code) | \(numRound)%|")
        }
        text.append("")
        text.append("total number of files: \(totalCount)")
        if isVerbose {
            print(text.joined(separator: "\n"))
        }
        if let outputPath = output_path {
            let urlPath = URL(fileURLWithPath: outputPath)
            let path = urlPath.deletingLastPathComponent().absoluteString
            let _path = path.replacingOccurrences(of: "file://", with: "")
            let fileName = urlPath.lastPathComponent
            do {
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
            } catch {
                print(error.localizedDescription)
            }
        }
    } catch {
        print(error.localizedDescription)
    }
}

func find(folder: Folder) -> [File] {
    var files: [File] = []
    if folder.subfolders.count() == 0 {
        files.append(contentsOf: folder.files)
    } else {
        folder.subfolders.forEach { folder in
            files.append(contentsOf: folder.files)
            if folder.subfolders.count() > 0 {
                files.append(contentsOf: find(folder: folder))
            }
        }
    }
    
    return files
}

func funcTime(_ log: String, action: () -> Void) {
    let startDate = Date()
    action()
    let endDate = Date()
    print("\(log) \(endDate.timeIntervalSince(startDate))")
}

main.run()
