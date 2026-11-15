/// A clock the tests drive by hand.
///
/// `DateTime.now()` is not faked by `tester.pump()`, so every cooldown test
/// advances this instead of waiting 60 real seconds.
class FakeClock {
  FakeClock({DateTime? start})
      : _now = start ?? DateTime.utc(2026, 10, 7, 12, 0, 0);

  DateTime _now;

  DateTime now() => _now;

  void advance(Duration by) {
    _now = _now.add(by);
  }
}
