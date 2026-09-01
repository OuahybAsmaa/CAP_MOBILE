/// Emplacement unique des conversions JSON du domaine reception.
abstract final class ReceptionMapper {
  static List<T> typedList<T>(Iterable<T> items) => List<T>.unmodifiable(items);
}
