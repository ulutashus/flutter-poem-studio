import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:poem_studio/core/l10n/failure_messages.dart';
import 'package:poem_studio/core/l10n/l10n.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_edit_state.dart';
import 'package:poem_studio/features/poem/presentation/widgets/failure_view.dart';

class PoemEditPage extends StatefulWidget {
  const PoemEditPage({super.key});

  @override
  State<PoemEditPage> createState() => _PoemEditPageState();
}

class _PoemEditPageState extends State<PoemEditPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late final _fields = Listenable.merge([_titleController, _contentController]);
  String _savedTitle = '';
  String _savedContent = '';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // The listener only sees later states, so a bloc that is already ready must be applied here.
    if (context.read<PoemEditBloc>().state case final PoemEditReady ready) {
      _initializeFields(ready);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty;

  bool get _isDirty =>
      _titleController.text != _savedTitle ||
      _contentController.text != _savedContent;

  void _initializeFields(PoemEditReady state) {
    if (_initialized) return;
    _initialized = true;
    _savedTitle = _titleController.text = state.poem.title;
    _savedContent = _contentController.text = state.poem.content;
  }

  void _save() {
    context.read<PoemEditBloc>().add(
      PoemEditSaveRequested(
        title: _titleController.text,
        content: _contentController.text,
      ),
    );
  }

  void _onStateChanged(BuildContext context, PoemEditState state) {
    switch (state) {
      case PoemEditReady(:final saveFailure):
        _initializeFields(state);
        if (saveFailure != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(saveFailure.message(context.l10n))),
            );
        }
      case PoemEditSaved():
        context.pop();
      case PoemEditLoading() || PoemEditError():
        break;
    }
  }

  Future<void> _confirmDiscard() async {
    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => _DiscardChangesSheet(canSave: _canSave),
    );
    if (!mounted || shouldSave == null) return;
    if (shouldSave) {
      _save();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PoemEditBloc, PoemEditState>(
      listener: _onStateChanged,
      child: ListenableBuilder(
        listenable: _fields,
        builder: (context, child) => PopScope(
          canPop: !_isDirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmDiscard();
          },
          child: child!,
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.editAction),
            actions: [
              BlocSelector<PoemEditBloc, PoemEditState, bool>(
                selector: (state) => state is PoemEditReady && !state.isSaving,
                builder: (context, canSubmit) => ListenableBuilder(
                  listenable: _fields,
                  builder: (context, _) => TextButton(
                    onPressed: canSubmit && _canSave && _isDirty ? _save : null,
                    child: Text(context.l10n.saveButton),
                  ),
                ),
              ),
            ],
          ),
          body: BlocBuilder<PoemEditBloc, PoemEditState>(
            buildWhen: (previous, current) =>
                previous.runtimeType != current.runtimeType,
            builder: (context, state) => switch (state) {
              PoemEditLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              PoemEditError(:final failure) => FailureView(failure: failure),
              PoemEditReady() || PoemEditSaved() => _EditForm(
                titleController: _titleController,
                contentController: _contentController,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.titleController,
    required this.contentController,
  });

  final TextEditingController titleController;
  final TextEditingController contentController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: titleController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: context.l10n.editTitleLabel),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: context.l10n.editVerseLabel,
                alignLabelWithHint: true,
              ),
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pops `true` to save, `false` to discard, or `null` when dismissed.
class _DiscardChangesSheet extends StatelessWidget {
  const _DiscardChangesSheet({required this.canSave});

  final bool canSave;

  @override
  Widget build(BuildContext context) {
    const buttonSize = Size.fromHeight(48);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.saveChangesPrompt,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: buttonSize),
              onPressed: canSave ? () => Navigator.pop(context, true) : null,
              child: Text(context.l10n.saveButton),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: buttonSize),
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.discardButton),
            ),
          ],
        ),
      ),
    );
  }
}
