import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// Returns a [BlocProvider] so it also works inside [MultiBlocProvider] without a child.
BlocProvider<B> provideBloc<B extends BlocBase<Object?>>({
  Widget? child,
  void Function(B bloc)? init,
}) {
  return BlocProvider<B>(
    create: (_) {
      final bloc = GetIt.instance<B>();
      init?.call(bloc);
      return bloc;
    },
    child: child,
  );
}
