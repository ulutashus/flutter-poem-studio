import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:poem_studio/core/l10n/l10n.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_list_state.dart';
import 'package:poem_studio/features/poem/presentation/routes/poem_paths.dart';
import 'package:poem_studio/features/poem/presentation/widgets/failure_view.dart';
import 'package:poem_studio/features/poem/presentation/widgets/poem_sync_indicator.dart';
import 'package:poem_studio/features/settings/settings.dart';

class PoemListPage extends StatelessWidget {
  const PoemListPage({super.key});

  static const _appIcon = AssetImage('assets/icon/app_icon.png');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 68,
        titleSpacing: 0,
        leading: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Image(image: _appIcon),
        ),
        title: Text(context.l10n.poemListTitle),
        actions: [
          const PoemSyncIndicator(),
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: context.l10n.settingsTitle,
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        child: const ReadingTextScale(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _SearchField(),
              ),
              Expanded(child: _PoemListBody()),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) =>
      context.read<PoemListBloc>().add(PoemListQueryChanged(value));

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) => TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          hintText: context.l10n.searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: context.l10n.clearTooltip,
                  onPressed: _clear,
                ),
          border: const OutlineInputBorder(),
        ),
        onChanged: _onChanged,
      ),
    );
  }
}

class _PoemListBody extends StatelessWidget {
  const _PoemListBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoemListBloc, PoemListState>(
      builder: (context, state) => switch (state) {
        PoemListState(status: PoemListStatus.loading) => const Center(
          child: CircularProgressIndicator(),
        ),
        PoemListState(status: PoemListStatus.failure, :final failure?) =>
          FailureView(failure: failure),
        PoemListState(:final visiblePoems) when visiblePoems.isEmpty => Center(
          child: Text(context.l10n.noResults),
        ),
        PoemListState(:final visiblePoems) => ListView.separated(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: visiblePoems.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => _PoemTile(poem: visiblePoems[index]),
        ),
      },
    );
  }
}

class _PoemTile extends StatelessWidget {
  const _PoemTile({required this.poem});

  final PoemEntity poem;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('${poem.order}')),
      title: Text(poem.title),
      onTap: () => context.push(PoemPaths.detailPath(poem.id)),
    );
  }
}
