//
//  Compressor.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import Compression

struct CompressorError : Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var localizedDescription: String {
        return "CompressorError<\(self.message)>"
    }
}

final class Compressor {
    let algorithm = COMPRESSION_ZLIB

    enum Mode {
        case infate
        case deflate
    }

    let data: Data
    let mode: Mode


    /// Adler32 Checksum
    static func checksum(_ data: Data) -> UInt32 {
        var a: UInt32 = 1
        var b: UInt32 = 0
        let prime: UInt32 = 65521

        for byte in data {
            a += UInt32(byte)
            if a >= prime { a = a % prime }
            b += a
            if b >= prime { b = b % prime }
        }

        return (b << 16) | a
    }

    private var operation: compression_stream_operation {
        switch self.mode {
        case .infate:
            return COMPRESSION_STREAM_DECODE
        case .deflate:
            return COMPRESSION_STREAM_ENCODE
        }
    }

    init(_ data: Data, _ mode: Mode) {
        self.data = data
        self.mode = mode
    }

    final func perform() throws -> Data {
        return try self.data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Data in
            return try self.perform(bytes, data.count)
        }
    }

    private func perform(_ bytes: UnsafePointer<UInt8>, _ size: Int) throws -> Data {
        guard self.mode == .deflate || size > 0 else {
            throw CompressorError("Can't inflate 0 data")
        }

        var streamWrapper = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        defer { streamWrapper.deallocate(capacity: 1) }
        var stream = streamWrapper.pointee

        let initStatus = compression_stream_init(&stream, self.operation, self.algorithm)
        guard initStatus != COMPRESSION_STATUS_ERROR else {
            throw CompressorError("Failed to create stream")
        }
        defer { compression_stream_destroy(&stream) }

        let bufferSize = min(size, 0x3E800)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate(capacity: bufferSize) }

        stream.src_ptr = bytes
        stream.src_size = size
        stream.dst_ptr = buffer
        stream.dst_size = bufferSize

        let flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
        var output = Data()

        while true {
            let status = compression_stream_process(&stream, flags)

            switch status {
            case COMPRESSION_STATUS_ERROR:
                throw CompressorError("Stream process error")
            case COMPRESSION_STATUS_OK:
                guard stream.dst_size == 0 else {
                    throw CompressorError("WTF")
                }
                output.append(buffer, count: stream.dst_ptr - buffer)
                stream.dst_ptr = buffer
                stream.dst_size = bufferSize
            case COMPRESSION_STATUS_END:
                if stream.dst_ptr > buffer {
                    output.append(buffer, count: stream.dst_ptr - buffer)
                }
                return output
            default:
                fatalError()
            }
        }
    }
}

public extension Data {
    /// Check if the returned data has a zipped header
    public var isZip: Bool {
        do {
            try self.validateZipHeader()
            return true
        } catch {
            return false
        }
    }

    /// Compresses the data.  Will add the Zlib header and Adler-32 checksum
    ///
    /// - Returns: The compressed data
    func zip() throws -> Data {
        var result = Data(bytes: [0x78, 0x5e])
        do {
            let compressor = Compressor(self, .deflate)
            let compressed = try compressor.perform()
            result.append(compressed)
        }
        do {
            var adler = Compressor.checksum(self).bigEndian
            let checksum = Data(bytes: &adler, count: MemoryLayout<UInt32>.size)
            result.append(checksum)
        }
        return result
    }

    /// Called on compressed data.
    ///
    /// - Parameter skipChecksumValidate: Pass true if the checksum shouldn't be validated.
    /// - Returns: The uncompressed data
    func unzip(skipChecksumValidate: Bool = false) throws -> Data {
        try self.validateZipHeader()

        // Header
        let startIndex = self.startIndex.advanced(by: 2)
        // Checksum
        let endIndex = self.endIndex.advanced(by: -4)
        let range = Range(uncheckedBounds: (startIndex, endIndex))
        let subset = self.subdata(in: range)
        let compressor = Compressor(subset, .infate)
        let inflated = try compressor.perform()
        if skipChecksumValidate == true {
            return inflated
        }
        let checksum: UInt32 = self.withUnsafeBytes { (bytePtr: UnsafePointer<UInt8>) -> UInt32 in
            let last = bytePtr.advanced(by: count - 4)
            return last.withMemoryRebound(to: UInt32.self, capacity: 1) { (intPtr) -> UInt32 in
                return intPtr.pointee.bigEndian
            }
        }
        guard checksum == Compressor.checksum(inflated) else {
            throw CompressorError("Checksum Missmatch")
        }

        return inflated
    }

    private func validateZipHeader() throws {
        // Overhead 2 bytes header and 4 bytes checksum
        guard self.count > 6 else {
            throw CompressorError("Not enough data to unzip")
        }

        let header: UInt16 = self.withUnsafeBytes { (ptr: UnsafePointer<UInt16>) -> UInt16 in
            return ptr.pointee.bigEndian
        }

        guard header >> 8 & 0b1111 == 0b1000 else {
            throw CompressorError("Invalid Header (1)")
        }
        guard header % 31 == 0 else {
            throw CompressorError("Invalid Header (2)")
        }
    }
}

