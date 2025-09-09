// Core/Experiment/CSVWriter.swift
import Foundation

enum CSVWriter {
    static func write(lines: [String], filename: String) -> URL? {
        do {
            let dir = try FileManager.default.url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
            let url = dir.appendingPathComponent(filename)
            let text = lines.joined(separator: "\n") + "\n"
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("CSV write error: \(error.localizedDescription)")
            return nil
        }
    }
}
