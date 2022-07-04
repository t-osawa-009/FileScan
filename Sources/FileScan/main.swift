import Foundation
import Commander
import Files

let main = command(
    Option<String?>("sourcePath", default: nil, description: "parse file paths"),
    Option<String?>("output_path", default: nil, description: "out put files"),
    Option<String?>("ignore_paths", default: nil, description: "ignore files"),
    Option<String>("verbose", default: "false", description: "Display the log"),
    Option<String?>("join", default: nil, description: "Merging the results of multiple paths")
) { sourcePath, output_path, ignore_paths, verbose, join_path in
    let startDate = Date()
    let isVerbose = verbose.lowercased() == "true"
    var files: [File] = []
    if let sourcePath = sourcePath {
        do {
            files.append(contentsOf: try findFiles(sourcePath: sourcePath, ignore_paths: ignore_paths))
        } catch {
            print(error.localizedDescription)
        }
    }
    
    if let join_path = join_path {
        let join_paths = join_path.split(separator: ",").map({ String($0) })
        join_paths.forEach { path in
            do {
                files.append(contentsOf: try findFiles(sourcePath: path, ignore_paths: ignore_paths))
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    let swiftUIKey = "swiftUI"
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
        
        if let value = try? file.readAsString(),
           value.contains("import SwiftUI"),
           value.contains("var body: some View {") {
            if var value = dic[swiftUIKey] {
                value.append(file)
                dic[swiftUIKey] = value
            } else {
                dic[swiftUIKey] = [file]
            }
        }
    }
    if let output_path = output_path {
        if output_path.contains(".md") {
            let markdown = Markdown(path: output_path,
                                    dictinary: dic,
                                    isVerbose: isVerbose,
                                    totalCount: files.count)
            do {
                try markdown.write()
            } catch {
                print(error.localizedDescription)
            }
        }
        
        if output_path.contains(".json") {
            let json = JSON(path: output_path,
                            dictinary: dic,
                            isVerbose: isVerbose,
                            totalCount: files.count)
            do {
                try json.write()
            } catch {
                print(error.localizedDescription)
            }
        }
        
        if output_path.contains(".csv") {
            let csv = CSV(path: output_path,
                          dictinary: dic,
                          isVerbose: isVerbose,
                          totalCount: files.count)
            do {
                try csv.write()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    let endDate = Date()
    if isVerbose {
        print("Total time: \(endDate.timeIntervalSince(startDate))")
    }
}

func findFiles(sourcePath: String, ignore_paths: String?) throws -> [File] {
    let folder = try Folder(path: sourcePath)
    var files = find(folder: folder)
    files.append(contentsOf: folder.files)
    if let ignore_paths = ignore_paths {
        let ignorePaths = ignore_paths.split(separator: ",")
        ignorePaths.forEach { path in
            files = files.lazy.filter { !$0.path.contains(path)}
        }
    }
    
    return files
}

func find(folder: Folder) -> [File] {
    var files: [File] = []
    // empty check
    if folder.subfolders.first == nil {
        files.append(contentsOf: folder.files)
    } else {
        folder.subfolders.forEach { folder in
            files.append(contentsOf: folder.files)
            if folder.subfolders.first != nil {
                files.append(contentsOf: find(folder: folder))
            }
        }
    }
    
    return files
}

main.run()
