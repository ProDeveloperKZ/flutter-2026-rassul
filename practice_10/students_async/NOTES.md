# Practice 10 — The Data Arrives Later

## Event loop: expected vs observed

Expected order (reasoning): A, C, first frame, B, 6 students. A and C run synchronously; delayed work lets main return and the UI draw.

Observed in the event-order widget test: A, C, first frame, B, 6 students. The two callbacks appeared after advancing the clock by two seconds. The API also prints fetchStudents #1 synchronously before the first frame; this diagnostic is separate from the five experiment markers.

Using sleep instead of await would block the isolate and postpone the first frame. The shipping app contains neither sleep nor the main experiments.

## Lifecycle errors

The isolated disposed-State probe produced this exact first line in the recorded run:

    setState() called after dispose(): _ProbeState#517df(lifecycle state: defunct, not mounted)

The object hash varies between runs. The probe represents the late callback after a load or a stream event; the production screens retain mounted guards and cancellation. UI tests also leave during loading and saving and verify no exception.

## FutureBuilder

The Future is stored in initState. Ten compact switches after loading produced just one fetchStudents #1; no spinner returned and calls stayed at 1. Explicit Reload / Retry creates a new Future. Errors are checked before connection state and empty data is shown as “No students yet”.

Putting fetchStudents() directly into build would create requests on rebuilds. Also, an error-only snapshot has no data; checking only hasData and otherwise showing a spinner would hide the failure.

The assignment's expression setState(() => _future = ...) returns a Future from the callback. Flutter rejects that with “setState() callback argument returned a Future.” The implementation starts the request outside setState and assigns it in a block that returns void.

## Countdown ownership

A (StreamBuilder): the widget test left at 7. After disposal, four more simulated seconds produced no additional tick logs and no exception.

B (listen): the same test left at 7 and also produced no additional logs after disposal. dispose explicitly requests cancellation. Switching between A and B removes the old child and cancels its stream too.

Without cancellation, an isolated subscription test simulated leaving after 7; it still received and printed tick 6, tick 5, tick 4, tick 3, tick 2, tick 1, tick 0. Coupling that live listener to an already-disposed State gives the lifecycle error above. The intentionally unsafe cases live only in contained tests.

## Save failures

The incorrect pattern starts save and pops immediately. On the second save the default uncaught-error report is:

    Unhandled Exception: Bad state: server rejected 6

The user saw a success while the request failed later. In the contained zone test, the actual asynchronous error was “Bad state: server rejected 6”; the test's zone handler received it instead of the caller. The test does not leave an uncaught error in the real app.

The final callback awaits save, catches StateError, checks context.mounted, and pops only on success. The rejected request keeps the screen open and shows “server rejected 6” in a SnackBar. While saving, onPressed is null; two fast taps make one request. A finally block restores the saving state only while mounted.

## API lifetime and explicit fire-and-forget

Home owns the normal and empty FakeApi instances so counters survive navigation. That makes a second Save fail even though the first successful Save closed its route. Load and save have separate counters. Each request captures its own call number before waiting, so overlapping requests cannot change its outcome.

unawaited_futures is enabled. Deliberate unawaited calls are explicit: initState starts _load (which handles errors), navigation returns a result that is not needed, and synchronous dispose requests stream cancellation. No network result is silently discarded.
