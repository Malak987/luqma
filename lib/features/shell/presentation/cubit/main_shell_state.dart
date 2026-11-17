import 'package:equatable/equatable.dart';

/// Top-level destinations of the persistent bottom navigation bar.
///
/// The declaration order is the visual order of the bar (start → end).
enum MainShellTab { home, restaurants, cart, favorites, account }

class MainShellState extends Equatable {
  const MainShellState({this.tab = MainShellTab.home});

  final MainShellTab tab;

  int get index => tab.index;
  bool get isHome => tab == MainShellTab.home;

  @override
  List<Object?> get props => <Object?>[tab];
}
