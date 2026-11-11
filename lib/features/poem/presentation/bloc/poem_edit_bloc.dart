import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/features/poem/domain/repositories/poem_repository.dart';
import 'package:poem_studio/features/poem/domain/usecases/edit_poem_usecase.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_state.dart';

@injectable
class PoemEditBloc extends Bloc<PoemEditEvent, PoemEditState> {
  PoemEditBloc(this._repository, this._editPoem)
    : super(const PoemEditLoading()) {
    on<PoemEditStarted>(_onStarted);
    on<PoemEditSaveRequested>(_onSaveRequested, transformer: droppable());
  }

  final PoemRepository _repository;
  final EditPoemUseCase _editPoem;

  Future<void> _onStarted(
    PoemEditStarted event,
    Emitter<PoemEditState> emit,
  ) async {
    emit(const PoemEditLoading());
    emit(switch (await _repository.getPoemById(event.poemId)) {
      Ok(:final data) => PoemEditReady(poem: data),
      Err(:final failure) => PoemEditError(failure),
    });
  }

  Future<void> _onSaveRequested(
    PoemEditSaveRequested event,
    Emitter<PoemEditState> emit,
  ) async {
    final current = state;
    if (current is! PoemEditReady) return;

    emit(PoemEditReady(poem: current.poem, isSaving: true));
    final result = await _editPoem(
      id: current.poem.id,
      title: event.title,
      content: event.content,
    );
    emit(switch (result) {
      Ok(:final data) => PoemEditSaved(data),
      Err(:final failure) => PoemEditReady(
        poem: current.poem,
        saveFailure: failure,
      ),
    });
  }
}
