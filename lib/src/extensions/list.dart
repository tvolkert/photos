extension CloneList<T> on List<T> {
  List<T> clone({bool growable = true}) {
    return List<T>.from(this, growable: growable);
  }
}
