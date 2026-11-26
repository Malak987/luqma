void main() {
  final m = <String, dynamic>{'Authorization': 'Bearer x', 'Accept': 'json'};
  m.removeWhere((key, _) => key.toLowerCase() == 'authorization');
  print('runtime ${m.runtimeType} keys ${m.keys.toList()}');
  print('contains ${m.containsKey('Authorization')}');
  print('empty ${m.isEmpty}');
}
