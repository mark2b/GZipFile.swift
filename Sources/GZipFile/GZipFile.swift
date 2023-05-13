import Compression
import Foundation
import zlib

public struct GZipFile {

    public func compress() throws {
        let fm = FileManager.default
        let sourceFileHandle = try FileHandle(forReadingFrom: sourceFileURL)
        if fm.fileExists(atPath: destinationFileURL.relativePath) {
            try fm.removeItem(at: destinationFileURL)
        }
        fm.createFile(atPath: destinationFileURL.relativePath, contents: Data())
        let destinationFileHandle = try FileHandle(forWritingTo: destinationFileURL)
        defer {
            try? destinationFileHandle.close()
        }
        
        // Write GZIP header to output file
        var headerData = Data([0x1f, 0x8b, 0x08, 0x00]) // magic, magic, deflate, noflags
        var unixtime = UInt32(Date().timeIntervalSince1970).littleEndian
        headerData.append(Data(bytes: &unixtime, count: MemoryLayout<UInt32>.size))
        headerData.append(contentsOf: [0x00, 0x03])  // normal compression level, unix file type
        destinationFileHandle.write(headerData)

        let bufferSize = 32_768 * 2
        
        // Calculate CRC32
        var crc:UInt32 = 0x0
        while let data = try sourceFileHandle.read(upToCount: bufferSize) {
            crc = data.withUnsafeBytes {
                UInt32(crc32(uLong(crc), $0.baseAddress, uInt(data.count)))
            }
        }
        crc = crc.littleEndian
        // Get source file length
        let attrs = try fm.attributesOfItem(atPath: sourceFileURL.relativePath)
        guard var sourceFileLength:UInt32 = (attrs[.size] as? UInt32)?.littleEndian else {
            return
        }

        let outputFilter = try OutputFilter(.compress, using: .zlib, bufferCapacity: bufferSize) {(data: Data?) -> Void in
            if let data = data {
                destinationFileHandle.write(data)
            }
        }
        try sourceFileHandle.seek(toOffset: 0)
        while true {
            let subdata = sourceFileHandle.readData(ofLength: bufferSize)

            try outputFilter.write(subdata)
            if subdata.count < bufferSize {
                break
            }
        }
        try outputFilter.finalize()
        
        destinationFileHandle.write(Data(bytes: &crc, count: MemoryLayout<UInt32>.size))
        destinationFileHandle.write(Data(bytes: &sourceFileLength, count: MemoryLayout<UInt32>.size))
    }
    
    public init(sourceFileURL:URL, destinationFileURL:URL) {
        self.sourceFileURL = sourceFileURL
        self.destinationFileURL = destinationFileURL
    }
        
    let sourceFileURL:URL
    let destinationFileURL:URL
}
