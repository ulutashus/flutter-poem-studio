import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/result/result.dart';
import 'package:poem_studio/core/share/share_service.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';
import 'package:poem_studio/features/poem/domain/repositories/poem_repository.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_state.dart';

@injectable
class PoemDetailBloc extends Bloc<PoemDetailEvent, PoemDetailState> {
  PoemDetailBloc(this._repository, this._shareService)
    : super(const PoemDetailLoading()) {
    on<PoemDetailSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
    on<PoemDetailPageChanged>(_onPageChanged);
    on<PoemDetailTextShareRequested>(_onTextShareRequested);
    on<PoemDetailImageShareRequested>(_onImageShareRequested);
  }

  final PoemRepository _repository;
  final ShareService _shareService;

  Future<void> _onSubscriptionRequested(
    PoemDetailSubscriptionRequested event,
    Emitter<PoemDetailState> emit,
  ) {
    return emit.forEach(
      _repository.watchPoems(),
      onData: (result) => switch (result) {
        // Stay on the poem being read when the collection changes underneath it.
        Ok(:final data) => _locate(data, _currentPoemId ?? event.poemId),
        Err(:final failure) => PoemDetailError(failure),
      },
    );
  }

  void _onPageChanged(
    PoemDetailPageChanged event,
    Emitter<PoemDetailState> emit,
  ) {
    if (state case PoemDetailLoaded(:final poems)) {
      emit(PoemDetailLoaded(poems: poems, index: event.index));
    }
  }

  Future<void> _onTextShareRequested(
    PoemDetailTextShareRequested event,
    Emitter<PoemDetailState> emit,
  ) async {
    if (state case PoemDetailLoaded(:final poem)) {
      await _shareService.shareText(
        '${poem.title}\n\n${poem.content}',
        subject: poem.title,
      );
    }
  }

  Future<void> _onImageShareRequested(
    PoemDetailImageShareRequested event,
    Emitter<PoemDetailState> emit,
  ) async {
    if (state case PoemDetailLoaded(:final poem)) {
      await _shareService.shareImage(event.pngBytes, subject: poem.title);
    }
  }

  String? get _currentPoemId => switch (state) {
    PoemDetailLoaded(:final poem) => poem.id,
    _ => null,
  };

  PoemDetailState _locate(List<PoemEntity> poems, String id) {
    final index = poems.indexWhere((poem) => poem.id == id);
    return index == -1
        ? const PoemDetailError(NotFoundFailure())
        : PoemDetailLoaded(poems: poems, index: index);
  }
}
