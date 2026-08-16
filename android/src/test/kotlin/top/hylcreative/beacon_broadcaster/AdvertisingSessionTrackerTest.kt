package top.hylcreative.beacon_broadcaster

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class AdvertisingSessionTrackerTest {
    @Test
    fun staleCallbacksCannotChangeTheCurrentSession() {
        val tracker = AdvertisingSessionTracker<Any>()
        val firstCallback = Any()
        val secondCallback = Any()

        tracker.begin(firstCallback)
        tracker.begin(secondCallback)

        assertFalse(tracker.markStarted(firstCallback))
        assertFalse(tracker.finish(firstCallback))
        assertSame(secondCallback, tracker.activeCallback)
        assertFalse(tracker.hasStarted)

        assertTrue(tracker.markStarted(secondCallback))
        assertTrue(tracker.hasStarted)
    }

    @Test
    fun finishingACallbackMakesRepeatedStopsNoOps() {
        val tracker = AdvertisingSessionTracker<Any>()
        val callback = Any()

        tracker.begin(callback)

        assertTrue(tracker.finish(callback))
        assertFalse(tracker.finish(callback))
        assertNull(tracker.activeCallback)
        assertFalse(tracker.hasStarted)
    }
}
