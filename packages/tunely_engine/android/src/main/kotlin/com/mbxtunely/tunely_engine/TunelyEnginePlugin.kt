package com.mbxtunely.tunely_engine

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Android stub. The same Pigeon API gets a Media3 implementation later. */
class TunelyEnginePlugin : FlutterPlugin, EngineApi {
  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    EngineApi.setUp(binding.binaryMessenger, this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    EngineApi.setUp(binding.binaryMessenger, null)
  }

  override fun pickVideos(maxCount: Long, callback: (Result<List<String>>) -> Unit) =
    callback(Result.failure(unimplemented()))

  override fun inspect(path: String, callback: (Result<MediaInfo>) -> Unit) =
    callback(Result.failure(unimplemented()))

  override fun waveform(path: String, buckets: Long, callback: (Result<List<Double>>) -> Unit) =
    callback(Result.failure(unimplemented()))

  override fun thumbnail(path: String, maxPixels: Long, callback: (Result<String?>) -> Unit) =
    callback(Result.success(null))

  override fun convert(jobId: String, request: ConvertRequest, callback: (Result<ConvertResult>) -> Unit) =
    callback(Result.failure(unimplemented()))

  override fun cancel(jobId: String) = throw unimplemented()

  override fun availableFormats(): List<OutFormat> = emptyList()

  override fun pickFolder(callback: (Result<String?>) -> Unit) =
    callback(Result.failure(unimplemented()))

  override fun bookmarkedFolderName(bookmarkId: String): String? = null

  override fun copyToBookmarkedFolder(path: String, bookmarkId: String, callback: (Result<String>) -> Unit) =
    callback(Result.failure(unimplemented()))

  override fun freeBytes(): Long = throw unimplemented()

  override fun cleanTemp(olderThanHours: Long) = throw unimplemented()

  override fun startContinuedBatch(title: String, callback: (Result<Boolean>) -> Unit) =
    callback(Result.success(false))

  override fun updateContinuedBatch(completed: Long, total: Long, subtitle: String) {}

  override fun finishContinuedBatch(success: Boolean) {}

  override fun openUrl(url: String, callback: (Result<Boolean>) -> Unit) =
    callback(Result.success(false))

  override fun appInfo(): AppInfo = AppInfo(version = "", build = "", osVersion = "")

  override fun trackingStatus(): String = "authorized"

  override fun requestTracking(callback: (Result<String>) -> Unit) =
    callback(Result.success("authorized"))

  override fun bookmarkedFolderIsICloud(bookmarkId: String): Boolean = false

  override fun deviceCheckToken(callback: (Result<String?>) -> Unit) =
    callback(Result.success(null))

  override fun openAppStorePage(appStoreId: String, callback: (Result<Boolean>) -> Unit) =
    callback(Result.success(false))

  private fun unimplemented() = FlutterError("unavailable", "The Android engine isn't implemented yet.", null)
}
