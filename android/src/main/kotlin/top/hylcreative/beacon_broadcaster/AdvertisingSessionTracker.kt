package top.hylcreative.beacon_broadcaster

/** Tracks the callback that owns the current asynchronous advertising request. */
internal class AdvertisingSessionTracker<T : Any> {
    var activeCallback: T? = null
        private set

    var hasStarted = false
        private set

    fun begin(callback: T) {
        activeCallback = callback
        hasStarted = false
    }

    fun markStarted(callback: T): Boolean {
        if (activeCallback !== callback) {
            return false
        }
        hasStarted = true
        return true
    }

    fun finish(callback: T): Boolean {
        if (activeCallback !== callback) {
            return false
        }
        clear()
        return true
    }

    fun clear(): T? {
        val callback = activeCallback
        activeCallback = null
        hasStarted = false
        return callback
    }
}
