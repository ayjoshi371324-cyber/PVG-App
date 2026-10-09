import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/driver/driver_cubit.dart';
import 'package:ridepool_app/blocs/passenger/passenger_cubit.dart';
import 'package:ridepool_app/blocs/role/role_cubit.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/views/shell_view.dart';

void main() {
  runApp(const RidePoolApp());
}

class RidePoolApp extends StatelessWidget {
  const RidePoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoleCubit>(create: (_) => RoleCubit()),
        BlocProvider<PassengerCubit>(create: (_) => PassengerCubit()),
        BlocProvider<DriverCubit>(create: (_) => DriverCubit()),
      ],
      child: MaterialApp(
        title: 'RidePool AI',
        debugShowCheckedModeBanner: false,
        theme: UberTheme.lightTheme,
        home: const ShellView(),
      ),
    );
  }
}
