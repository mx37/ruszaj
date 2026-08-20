part of '../../main.dart';

class _RouteTimeSelection {
  const _RouteTimeSelection({required this.time, required this.arriveBy});
  final DateTime time;
  final bool arriveBy;
}

class _RouteTimeSheet extends StatefulWidget {
  const _RouteTimeSheet({required this.initialTime, required this.arriveBy});
  final DateTime initialTime;
  final bool arriveBy;

  @override
  State<_RouteTimeSheet> createState() => _RouteTimeSheetState();
}

class _RouteTimeSheetState extends State<_RouteTimeSheet> {
  late DateTime _time = widget.initialTime;
  late bool _arriveBy = widget.arriveBy;

  void _chooseDate(DateTime date) {
    setState(
      () => _time = DateTime(
        date.year,
        date.month,
        date.day,
        _time.hour,
        _time.minute,
      ),
    );
  }

  List<DateTime> _dateOptions() {
    final selected = DateUtils.dateOnly(_time);
    return List.generate(5, (index) => selected.add(Duration(days: index - 2)));
  }

  Future<void> _chooseTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time),
    );
    if (time == null || !mounted) return;
    setState(
      () => _time = DateTime(
        _time.year,
        _time.month,
        _time.day,
        time.hour,
        time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lineOf(context),
              borderRadius: AppRadii.pill,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _arriveBy ? l10n.arriveBy : l10n.leaveAt,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.softOf(context),
                  borderRadius: AppRadii.pill,
                ),
                child: Row(
                  children: [
                    _TimeModeButton(
                      label: l10n.leaveAt,
                      selected: !_arriveBy,
                      onTap: () => setState(() => _arriveBy = false),
                    ),
                    _TimeModeButton(
                      label: l10n.arriveBy,
                      selected: _arriveBy,
                      onTap: () => setState(() => _arriveBy = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dateOptions().length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = _dateOptions()[index];
                final selected = DateUtils.isSameDay(date, _time);
                return GestureDetector(
                  onTap: () => _chooseDate(date),
                  child: Container(
                    width: 76,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.blue
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: AppRadii.field,
                      border: Border.all(
                        color: selected
                            ? AppColors.blue
                            : AppColors.lineOf(context),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.MMM(
                            Localizations.localeOf(context).toString(),
                          ).format(date),
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textMuted(context),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _chooseTime,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.softOf(context),
                borderRadius: AppRadii.field,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppIcon(
                    HugeIcons.strokeRoundedClock01,
                    color: AppColors.blue,
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                _RouteTimeSelection(time: _time, arriveBy: _arriveBy),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.field,
                ),
              ),
              child: Text(l10n.saveTime),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeModeButton extends StatelessWidget {
  const _TimeModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.surface
            : Colors.transparent,
        borderRadius: AppRadii.pill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected
              ? Theme.of(context).colorScheme.onSurface
              : AppColors.textMuted(context),
        ),
      ),
    ),
  );
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.suggestions,
    required this.searching,
    required this.onSelected,
  });
  final List<SearchPlace> suggestions;
  final bool searching;
  final ValueChanged<SearchPlace> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10),
    decoration: BoxDecoration(
      color: AppColors.softOf(context),
      borderRadius: AppRadii.field,
    ),
    child: searching
        ? Padding(
            padding: EdgeInsets.all(14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        : Column(
            children: [
              for (final place in suggestions)
                ListTile(
                  dense: true,
                  title: Text(place.name),
                  subtitle: Text(place.type),
                  onTap: () => onSelected(place),
                ),
            ],
          ),
  );
}
