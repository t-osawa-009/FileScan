import Foundation
import Commander
import Files

let main = command(
    Option<String?>("sourcePath", default: nil, description: "parse file paths"),
    Option<String?>("output_path", default: nil, description: "out put files"),
    Option<String?>("ignore_paths", default: nil, description: "ignore files"),
    Option<String?>("ignore_extension", default: nil, description: "ignore extension"),
    Option<String>("verbose", default: "false", description: "Display the log"),
    Option<Int>("decimal_point", default: 2, description: "Number of decimal places for%"),
    Option<String?>("join", default: nil, description: "Merging the results of multiple paths")
) { sourcePath, output_path, ignore_paths, ignore_extension, verbose, decimal_point, join_path in
    let startDate = Date()
    let isVerbose = verbose.lowercased() == "true"
    var ignorePaths: [String] = []
    if let ignore_paths = ignore_paths {
        ignorePaths = ignore_paths.split(separator: ",").map({ String($0) })
    }
    
    var ignore_extensions: [String] = []
    if let ignore_extension = ignore_extension {
        ignore_extensions = ignore_extension.split(separator: ",").map({ String($0) })
    }
    
    var files: [File] = []
    if let sourcePath = sourcePath {
        do {
            files.append(contentsOf: try findFiles(sourcePath: sourcePath, ignore_paths: ignorePaths, ignore_extensions: ignore_extensions))
        } catch {
            print(error.localizedDescription)
        }
    }
    
    if let join_path = join_path {
        let join_paths = join_path.split(separator: ",").map({ String($0) })
        join_paths.forEach { path in
            do {
                files.append(contentsOf: try findFiles(sourcePath: path, ignore_paths: ignorePaths, ignore_extensions: ignore_extensions))
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
                                    totalCount: files.count,
                                    decimalPoint: decimal_point)
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
                            totalCount: files.count,
                            decimalPoint: decimal_point)
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
                          totalCount: files.count,
                          decimalPoint: decimal_point)
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

func findFiles(sourcePath: String, ignore_paths: [String], ignore_extensions: [String]) throws -> [File] {
    let folder = try Folder(path: sourcePath)
    var files = find(folder: folder)
    files.append(contentsOf: folder.files)
    ignore_paths.forEach { path in
        files = files.lazy.filter { !$0.path.contains(path)}
    }
    
    ignore_extensions.forEach { ex in
        files = files.lazy.filter {
            if let fileExtension = $0.extension {
                return fileExtension.contains(ex)
            } else {
                return false
            }
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
