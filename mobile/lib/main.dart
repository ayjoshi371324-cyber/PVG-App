import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return BlocProvider(
      create: (_) => RoleCubit(),
      child: MaterialApp(
        title: 'RidePool AI',
        debugShowCheckedModeBanner: false,
        theme: UberTheme.lightTheme,
        home: const ShellView(),
      ),
    );
  }
}
