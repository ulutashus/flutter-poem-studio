import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:poem_studio/core/l10n/l10n.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_state.dart';
import 'package:poem_studio/features/poem/presentation/routes/poem_paths.dart';
import 'package:poem_studio/features/poem/presentation/widgets/failure_view.dart';
import 'package:poem_studio/features/poem/presentation/widgets/poem_detail_menu_sheet.dart';
import 'package:poem_studio/features/settings/settings.dart';

class PoemDetailPage extends StatefulWidget {
  const PoemDetailPage({super.key});

  @override
  State<PoemDetailPage> createState() => _PoemDetailPageState();
}

class _PoemDetailPageState extends State<PoemDetailPage> {
  static const _pageAnimationDuration = Duration(milliseconds: 250);

  PageController? _pageController;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  PageController _controllerFor(int initialPage) =>
      _pageController ??= PageController(initialPage: initialPage);

  void _goTo(int index) => _pageController?.animateToPage(
    index,
    duration: _pageAnimationDuration,
    curve: Curves.easeOut,
  );

  void _openEditor(PoemEntity poem) =>
      context.push(PoemPaths.editPath(poem.id));

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoemDetailBloc, PoemDetailState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(
            state is PoemDetailLoaded
                ? context.l10n.poemDetailTitle(state.poem.order)
                : '',
          ),
          actions: [
            if (state is PoemDetailLoaded)
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: context.l10n.menuTooltip,
                onPressed: () => showPoemDetailMenuSheet(
                  context,
                  onEdit: () => _openEditor(state.poem),
                ),
              ),
          ],
        ),
        body: ReadingTextScale(
          child: switch (state) {
            PoemDetailLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            PoemDetailError(:final failure) => FailureView(failure: failure),
            PoemDetailLoaded() => PageView.builder(
              controller: _controllerFor(state.index),
              physics: const _DeliberatePagerPhysics(),
              itemCount: state.poems.length,
              onPageChanged: (index) => context.read<PoemDetailBloc>().add(
                PoemDetailPageChanged(index),
              ),
              itemBuilder: (context, index) =>
                  _PoemPage(poem: state.poems[index]),
            ),
          },
        ),
        bottomNavigationBar: state is PoemDetailLoaded
            ? _PagerBar(
                onPrevious: state.hasPrevious
                    ? () => _goTo(state.index - 1)
                    : null,
                onNext: state.hasNext ? () => _goTo(state.index + 1) : null,
              )
            : null,
      ),
    );
  }
}

class _PagerBar extends StatelessWidget {
  const _PagerBar({required this.onPrevious, required this.onNext});

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              label: Text(context.l10n.previousButton),
            ),
            TextButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              iconAlignment: IconAlignment.end,
              label: Text(context.l10n.nextButton),
            ),
          ],
        ),
      ),
    );
  }
}

/// Requires a firmer swipe than the default, so reading and scrolling do not flip pages by accident.
class _DeliberatePagerPhysics extends PageScrollPhysics {
  const _DeliberatePagerPhysics({super.parent});

  @override
  _DeliberatePagerPhysics applyTo(ScrollPhysics? ancestor) =>
      _DeliberatePagerPhysics(parent: buildParent(ancestor));

  @override
  double get minFlingVelocity => 700;

  @override
  double get minFlingDistance => 80;

  @override
  double? get dragStartDistanceMotionThreshold => 16;
}

class _PoemPage extends StatelessWidget {
  const _PoemPage({required this.poem});

  final PoemEntity poem;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poem.title, style: textTheme.titleLarge),
          const SizedBox(height: 16),
          SelectionArea(
            child: SizedBox(
              width: double.infinity,
              child: _Verses(
                content: poem.content,
                style: textTheme.bodyLarge?.copyWith(height: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays out stanzas (blank-line separated) with spacing that grows with the reading text scale.
class _Verses extends StatelessWidget {
  const _Verses({required this.content, required this.style});

  static const _verseGap = 8.0;
  static const _stanzaGap = 32.0;

  final String content;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final stanzas = content
        .split('\n\n')
        .map(
          (stanza) => stanza
              .split('\n')
              .map((verse) => verse.trim())
              .where((verse) => verse.isNotEmpty)
              .toList(),
        )
        .where((verses) => verses.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (stanzaIndex, verses) in stanzas.indexed) ...[
          if (stanzaIndex > 0) SizedBox(height: _stanzaGap * scale),
          for (final (verseIndex, verse) in verses.indexed) ...[
            if (verseIndex > 0) SizedBox(height: _verseGap * scale),
            Text(verse, style: style),
          ],
        ],
      ],
    );
  }
}
