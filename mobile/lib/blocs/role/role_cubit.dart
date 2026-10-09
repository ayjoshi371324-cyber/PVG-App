import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/role/role_state.dart';

class RoleCubit extends Cubit<RoleState> {
  RoleCubit({AppRole initialRole = AppRole.passenger})
      : super(RoleState(currentRole: initialRole));

  void selectRole(AppRole role) {
    if (state.currentRole == role) return;

    emit(RoleState(
      currentRole: role,
      previousRole: state.currentRole,
    ));
  }
}
