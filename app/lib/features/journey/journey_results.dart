part of '../../main.dart';

class _JourneyResults extends StatefulWidget {
  const _JourneyResults({
    required this.page,
    required this.fromName,
    required this.toName,
    required this.from,
    required this.to,
    this.time,
    this.arriveBy = false,
  });
  final JourneyPage page;
  final String fromName;
  final String toName;
  final String from;
  final String to;
  final DateTime? time;
  final bool arriveBy;

  @override
  State<_JourneyResults> createState() => _JourneyResultsState();
}

class _JourneyResultsState extends State<_JourneyResults> {
  late JourneyPage _page = widget.page;
  bool _loading = false;

  Future<void> _loadPage(String cursor, {required bool append}) async {
    setState(() => _loading = true);
    try {
      final page = await RuszajApi().journeyPage(
        from: widget.from,
        to: widget.to,
        time: widget.time,
        arriveBy: widget.arriveBy,
        pageCursor: cursor,
      );
      if (!mounted) return;
      final combined = append
          ? [..._page.journeys, ...page.journeys]
          : [...page.journeys, ..._page.journeys];
      final journeys = <JourneyOption>[];
      final ids = <String>{};
      for (final journey in combined) {
        final key = journey.id.isEmpty
            ? '${journey.departure.toIso8601String()}|${journey.arrival.toIso8601String()}'
            : journey.id;
        if (ids.add(key)) journeys.add(journey);
      }
      setState(
        () => _page = JourneyPage(
          journeys: journeys,
          previousPageCursor: append
              ? _page.previousPageCursor ?? page.previousPageCursor
              : page.previousPageCursor,
          nextPageCursor: append
              ? page.nextPageCursor
              : _page.nextPageCursor ?? page.nextPageCursor,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final journeys = _page.journeys;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const AppIcon(
                      HugeIcons.strokeRoundedArrowLeft01,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.routeOptions,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${widget.fromName}  →  ${widget.toName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.textMuted(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: journeys.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noUpcomingJourneys,
                        style: TextStyle(color: AppColors.textMuted(context)),
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.extentAfter < 240 &&
                            _page.nextPageCursor != null &&
                            !_loading) {
                          unawaited(
                            _loadPage(_page.nextPageCursor!, append: true),
                          );
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        onRefresh: _page.previousPageCursor == null
                            ? () async {}
                            : () => _loadPage(
                                _page.previousPageCursor!,
                                append: false,
                              ),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount:
                              journeys.length +
                              (_loading && _page.nextPageCursor != null
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index >= journeys.length) {
                              return const Padding(
                                padding: EdgeInsets.all(18),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            final journey = journeys[index];
                            final isPast = journey.departure.isBefore(
                              DateTime.now(),
                            );
                            final textColor = isPast
                                ? AppColors.textMuted(context)
                                : Theme.of(context).colorScheme.onSurface;
                            return GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => _JourneyDetail(
                                    journey: journey,
                                    fromName: widget.fromName,
                                    toName: widget.toName,
                                  ),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isPast
                                      ? Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: 0.55)
                                      : Theme.of(context).colorScheme.surface,
                                  borderRadius: AppRadii.field,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _departureLabel(
                                            journey.departure,
                                            l10n,
                                          ),
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: AppIcon(
                                            HugeIcons.strokeRoundedArrowRight01,
                                            size: 17,
                                            color: AppColors.subtle,
                                          ),
                                        ),
                                        Text(
                                          _time(journey.arrival),
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${(journey.durationSeconds / 60).round()} ${l10n.minutes}',
                                          style: TextStyle(
                                            color: isPast
                                                ? AppColors.textMuted(context)
                                                : AppColors.textMuted(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 7,
                                      runSpacing: 7,
                                      children: [
                                        for (final leg in journey.legs)
                                          _ModeChip(leg: leg, l10n: l10n),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      journey.transfers == 0
                                          ? l10n.transit
                                          : '${journey.transfers} ${journey.transfers == 1 ? l10n.transfer : l10n.transfers}',
                                      style: TextStyle(
                                        color: isPast
                                            ? AppColors.textMuted(context)
                                            : AppColors.textMuted(context),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _departureLabel(DateTime departure, AppLocalizations l10n) {
    final difference = departure.difference(DateTime.now());
    if (difference.isNegative) {
      final minutes = difference.inMinutes.abs();
      if (minutes < 5) return '-${minutes == 0 ? 1 : minutes} ${l10n.minutes}';
      return l10n.departed;
    }
    final minutes = difference.inMinutes;
    if (minutes < 60) return l10n.inMinutes(minutes);
    return _time(departure);
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.leg, required this.l10n});
  final JourneyLeg leg;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isWalk = leg.mode == 'WALK';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isWalk
            ? AppColors.softOf(context)
            : Theme.of(context).colorScheme.onSurface,
        borderRadius: AppRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            isWalk
                ? HugeIcons.strokeRoundedWalking
                : HugeIcons.strokeRoundedBus01,
            size: 16,
            color: isWalk
                ? AppColors.blue
                : Theme.of(context).colorScheme.surface,
          ),
          const SizedBox(width: 5),
          Text(
            isWalk ? l10n.walking : (leg.routeName ?? leg.mode),
            style: TextStyle(
              color: isWalk
                  ? AppColors.blue
                  : Theme.of(context).colorScheme.surface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyDetail extends StatelessWidget {
  const _JourneyDetail({
    required this.journey,
    required this.fromName,
    required this.toName,
  });
  final JourneyOption journey;
  final String fromName;
  final String toName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: PageView(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const AppIcon(
                            HugeIcons.strokeRoundedArrowLeft01,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fromName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                toName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _time(journey.departure),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: AppIcon(
                              HugeIcons.strokeRoundedArrowRight01,
                              color: AppColors.subtle,
                            ),
                          ),
                          Text(
                            _time(journey.arrival),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(journey.durationSeconds / 60).round()} ${l10n.minutes}',
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      for (final leg in journey.legs)
                        _DetailLeg(leg: leg, l10n: l10n),
                    ]),
                  ),
                ),
              ],
            ),
            JourneyRouteMap(
              journey: journey,
              fromName: fromName,
              toName: toName,
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _DetailLeg extends StatefulWidget {
  const _DetailLeg({required this.leg, required this.l10n});
  final JourneyLeg leg;
  final AppLocalizations l10n;

  @override
  State<_DetailLeg> createState() => _DetailLegState();
}

class _DetailLegState extends State<_DetailLeg> {
  bool _stopsExpanded = false;

  JourneyLeg get leg => widget.leg;
  AppLocalizations get l10n => widget.l10n;

  @override
  Widget build(BuildContext context) {
    final isWalk = leg.mode == 'WALK';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            isWalk
                ? HugeIcons.strokeRoundedWalking
                : HugeIcons.strokeRoundedBus01,
            color: isWalk ? AppColors.blue : AppColors.green,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWalk
                      ? l10n.walking
                      : '${leg.routeName ?? leg.mode}${leg.headsign == null ? '' : ' → ${leg.headsign}'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_time(leg.departure)}  →  ${_time(leg.arrival)}',
                  style: TextStyle(color: AppColors.textMuted(context)),
                ),
                if (leg.fromName != null || leg.toName != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    '${leg.fromName ?? ''}  →  ${leg.toName ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                if (!isWalk && leg.intermediateStops.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  _StopsDropdown(
                    expanded: _stopsExpanded,
                    stops: leg.intermediateStops,
                    onToggle: () =>
                        setState(() => _stopsExpanded = !_stopsExpanded),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _StopsDropdown extends StatelessWidget {
  const _StopsDropdown({
    required this.expanded,
    required this.stops,
    required this.onToggle,
  });
  final bool expanded;
  final List<IntermediateStop> stops;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softOf(context),
        borderRadius: AppRadii.field,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: AppRadii.field,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const AppIcon(
                    HugeIcons.strokeRoundedBus01,
                    size: 16,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${stops.length} ${stops.length == 1 ? l10n.stop : l10n.stops}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppIcon(
                    expanded
                        ? HugeIcons.strokeRoundedArrowUp01
                        : HugeIcons.strokeRoundedArrowDown01,
                    size: 16,
                    color: AppColors.textMuted(context),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.lineOf(context)),
                ),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < stops.length; index++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 24),
                          Expanded(
                            child: Text(
                              stops[index].name,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          if (stops[index].arrival != null)
                            Text(
                              _time(stops[index].arrival!),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (index != stops.length - 1)
                      Padding(
                        padding: EdgeInsets.only(left: 36),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.lineOf(context),
                        ),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
