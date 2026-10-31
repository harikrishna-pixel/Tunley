// Builds a short H.264 + AAC test video for simulator QA.
// swiftc -O packages/tunely_engine/tool/make_test_video.swift -o /tmp/make_test_video
// /tmp/make_test_video <audio-in> <video-out.mov>
import AVFoundation
import CoreVideo
import Foundation

let args = CommandLine.arguments
guard args.count == 3 else {
  print("usage: make_test_video <audio-in> <video-out.mov>")
  exit(2)
}
let audioURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])
try? FileManager.default.removeItem(at: outURL)

let width = 360
let height = 640
let fps: Int32 = 30
let audioAsset = AVURLAsset(url: audioURL)
let audioTracks = audioAsset.tracks(withMediaType: .audio)

let writer = try AVAssetWriter(outputURL: outURL, fileType: .mov)
let video = AVAssetWriterInput(mediaType: .video, outputSettings: [
  AVVideoCodecKey: AVVideoCodecType.h264,
  AVVideoWidthKey: width,
  AVVideoHeightKey: height,
])
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: video, sourcePixelBufferAttributes: [
  kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
  kCVPixelBufferWidthKey as String: width,
  kCVPixelBufferHeightKey as String: height,
])
let audio = AVAssetWriterInput(mediaType: .audio, outputSettings: [
  AVFormatIDKey: kAudioFormatMPEG4AAC,
  AVSampleRateKey: 44100,
  AVNumberOfChannelsKey: 2,
  AVEncoderBitRateKey: 128000,
])
writer.add(video)
writer.add(audio)

let reader = try AVAssetReader(asset: audioAsset)
let output = AVAssetReaderAudioMixOutput(
  audioTracks: audioTracks,
  audioSettings: [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 2])
reader.add(output)
reader.startReading()
writer.startWriting()
writer.startSession(atSourceTime: .zero)

let seconds = CMTimeGetSeconds(audioAsset.duration)
let frames = Int(seconds * Double(fps))
var frame = 0
var audioDone = false
let queue = DispatchQueue(label: "writer")
let group = DispatchGroup()

group.enter()
video.requestMediaDataWhenReady(on: queue) {
  while video.isReadyForMoreMediaData {
    if frame >= frames {
      video.markAsFinished()
      group.leave()
      return
    }
    var buffer: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
    guard let pixels = buffer else { return }
    CVPixelBufferLockBaseAddress(pixels, [])
    let base = CVPixelBufferGetBaseAddress(pixels)!.assumingMemoryBound(to: UInt8.self)
    let stride = CVPixelBufferGetBytesPerRow(pixels)
    let t = Double(frame) / Double(max(1, frames))
    for y in 0..<height {
      let row = base + y * stride
      let v = Double(y) / Double(height)
      let b = UInt8(200 + 55 * v), g = UInt8(40 + 60 * t), r = UInt8(90 + 120 * (1 - v))
      for x in 0..<width {
        let p = row + x * 4
        p[0] = b; p[1] = g; p[2] = r; p[3] = 255
      }
    }
    CVPixelBufferUnlockBaseAddress(pixels, [])
    adaptor.append(pixels, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: fps))
    frame += 1
  }
}

group.enter()
audio.requestMediaDataWhenReady(on: queue) {
  while audio.isReadyForMoreMediaData && !audioDone {
    if let sample = output.copyNextSampleBuffer() {
      audio.append(sample)
    } else {
      audioDone = true
      audio.markAsFinished()
      group.leave()
    }
  }
}

group.wait()
let done = DispatchSemaphore(value: 0)
writer.finishWriting { done.signal() }
done.wait()
print(writer.status == .completed ? "wrote \(outURL.path)" : "failed: \(String(describing: writer.error))")
