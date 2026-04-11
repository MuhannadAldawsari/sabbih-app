enum IqamaNotifMode {
  before45,
  before30,
  before15,
}

/// ترحيل فهرس الوضع المحفوظ قبل إزالة [IqamaNotifMode.always]:
/// قديم: 0 دائم، 1 قبل 45، 2 قبل 30، 3 قبل 15.
/// جديد: 0 قبل 45، 1 قبل 30، 2 قبل 15.
int migrateLegacyIqamaNotifModeIndex(int? stored) {
  if (stored == null) return IqamaNotifMode.before45.index;
  if (stored >= 4) return IqamaNotifMode.before15.index;
  return stored == 0 ? IqamaNotifMode.before45.index : stored - 1;
}
