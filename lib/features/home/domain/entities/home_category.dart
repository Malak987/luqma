import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One category of the home screen.
///
/// This is the UI-side contract for the catalog categories. It stays empty
/// until the catalog endpoint is connected; no sample categories are baked
/// into the feature in the meantime.
@immutable
class HomeCategory extends Equatable {
  const HomeCategory({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object> get props => <Object>[id, name];
}
