import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/poem/domain/repositories/poem_repository.dart';
import 'package:poem_studio/features/poem/domain/usecases/search_poems_usecase.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_state.dart';
import 'package:stream_transform/stream_transform.dart';

@injectable
class PoemListBloc extends Bloc<PoemListEvent, PoemListState> {
  PoemListBloc(this._repository, this._searchPoems)
    : super(const PoemListState()) {
    on<PoemListSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
    on<PoemListQueryChanged>(
      _onQueryChanged,
      transformer: _debounce(searchDebounce),
    );
  }

  static const searchDebounce = Duration(milliseconds: 300);

  final PoemRepository _repository;
  final SearchPoemsUseCase _searchPoems;

  Future<void> _onSubscriptionRequested(
    PoemListSubscriptionRequested event,
    Emitter<PoemListState> emit,
  ) {
    return emit.forEach(
      _repository.watchPoems(),
      onData: (result) => switch (result) {
        Ok(:final data) => PoemListState(
          status: PoemListStatus.success,
          poems: data,
          visiblePoems: _searchPoems(data, state.query),
          query: state.query,
        ),
        Err(:final failure) => PoemListState(
          status: PoemListStatus.failure,
          poems: state.poems,
          visiblePoems: state.visiblePoems,
          query: state.query,
          failure: failure,
        ),
      },
    );
  }

  void _onQueryChanged(
    PoemListQueryChanged event,
    Emitter<PoemListState> emit,
  ) {
    emit(
      PoemListState(
        status: state.status,
        poems: state.poems,
        visiblePoems: _searchPoems(state.poems, event.query),
        query: event.query,
        failure: state.failure,
      ),
    );
  }
}

EventTransformer<E> _debounce<E>(Duration duration) =>
    (events, mapper) => events.debounce(duration).switchMap(mapper);
