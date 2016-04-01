//
//  RotatableFileDestination.swift
//  SwiftyBeaver
//
//  Created by Tetsuro Higuchi on 4/1/16.
//  Copyright © 2016 wistail. All rights reserved.
//

import Foundation

public class RotatableFileDestination: FileDestination {
    public var maxNumberOfBackupFiles: Int = 10
    public var maxSizeOfFile: UInt = 1024 * 800
    
    public var logFiles: [NSURL] {
        let filePath = logFileURL.path!

        let backupPaths:[NSURL] = (0..<maxNumberOfBackupFiles).map {
            NSURL(fileURLWithPath: filePath.stringByAppendingFormat(".%d", $0))
        }
        
        return ([logFileURL] + backupPaths).filter {
            fileManager.fileExistsAtPath($0.path!)
        }
    }
    
    public override func send(
        level: SwiftyBeaver.Level,
        msg: String,
        thread: String,
        path: String,
        function: String,
        line: Int) -> String? {
        
        let formattedString = super.send(level, msg: msg, thread: thread, path: path, function: function, line: line)
        do {
            if try shouldRotate(logFileURL.path!) {
                try rotate(logFileURL.path!)
            }
        } catch let error {
            print("some error was occured when SwiftyBeaver rotate file. \(error)")
        }
        return formattedString
    }
    
    private func shouldRotate(filepath: String) throws -> Bool {
        guard maxNumberOfBackupFiles > 0 else { return false }
        
        let attributes = try fileManager.attributesOfItemAtPath(filepath)
        if let size = attributes[NSFileSize] as? NSNumber {
            return maxSizeOfFile < size.unsignedIntegerValue
        }
        return false
    }
    
    private func rotate(filepath: String) throws {
        try unshiftBackupFiles(filepath)
        
        if let fileHandle = fileHandle {
            fileHandle.closeFile()
            self.fileHandle = nil
        }
        
        let targetPath = filepath.stringByAppendingString(".0")
        try fileManager.moveItemAtPath(filepath, toPath: targetPath)
    }
    
    private func unshiftBackupFiles(filepath: String) throws {
        for i in (0..<maxNumberOfBackupFiles).reverse() {
            let sourcePath = filepath.stringByAppendingFormat(".%d", i)
            let targetPath = filepath.stringByAppendingFormat(".%d", i + 1)
            
            guard fileManager.fileExistsAtPath(sourcePath) else { continue }
            
            if i + 1 < maxNumberOfBackupFiles {
                if fileManager.fileExistsAtPath(targetPath) {
                    try fileManager.removeItemAtPath(targetPath)
                }
                try fileManager.moveItemAtPath(sourcePath, toPath: targetPath)
            } else {
                try fileManager.removeItemAtPath(sourcePath)
            }
        }
    }
}
