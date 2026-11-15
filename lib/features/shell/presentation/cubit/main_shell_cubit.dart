import 'package:flutter_bloc/flutter_bloc.dart';

import 'main_shell_state.dart';

/// Owns only which tab of the shell is visible. Tab content keeps its own
/// cubits, so switching tabs never reloads or resets another tab.
class MainShellCubit extends Cubit<MainShellState> {
  MainShellCubit() : super(const MainShellState());

  void selectTab(MainShellTab tab) {
    if (isClosed || tab == state.tab) {
      return;
    }
    emit(MainShellState(tab: tab));
  }

  void selectIndex(int index) {
    if (index < 0 || index >= MainShellTab.values.length) {
      return;
    }
    selectTab(MainShellTab.values[index]);
  }

  void goHome() => selectTab(MainShellTab.home);
}
