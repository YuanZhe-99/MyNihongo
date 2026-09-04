import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/progress/models/history_entry.dart';
import '../../l10n/app_localizations.dart';

/// The remembered sentences of one page, newest first.
///
/// Shared by the sentence lab and writing practice because the two want exactly
/// the same thing: a list of what was typed before, one tap to bring it back,
/// and one tap to forget it. Where it is *put* differs — a pane beside the
/// result on a wide window, a sheet behind an app-bar button on a narrow one —
/// and that is the page's decision, not this widget's.
class HistoryList extends StatelessWidget {
  const HistoryList({
    super.key,
    required this.entries,
    required this.onOpen,
    required this.onDelete,
    this.shrinkWrap = true,
  });

  /// What to show, already ordered newest first.
  final List<HistoryEntry> entries;

  /// Called with the text of the entry the learner tapped.
  final void Function(HistoryEntry entry) onOpen;

  /// Called with the entry the learner deleted.
  final void Function(HistoryEntry entry) onDelete;

  /// Whether the list sizes itself to its children.
  ///
  /// True inside a scrolling pane, false when the list owns the scroll — a
  /// sheet, where the entries are the only thing on screen.
  final bool shrinkWrap;

  /// Purpose: Build the list, or the line that says there is nothing in it.
  /// Inputs: The build `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: An empty history says so rather than rendering nothing, for the
  /// same reason the issue list does: an absence is something the reader has to
  /// interpret, and a sentence is not.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.historyEmpty,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            entry.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            _formatTime(context, entry.at),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () => onOpen(entry),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: l10n.historyDelete,
            onPressed: () => onDelete(entry),
          ),
        );
      },
    );
  }

  /// Purpose: Say when an entry was written, in the reader's own zone.
  /// Inputs: `context` for the locale, and the UTC `time`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Today's entries show
  /// the clock time and older ones the date: within a session the useful
  /// question is which of these is the one from a minute ago, and after it the
  /// useful question is which day it came from.
  static String _formatTime(BuildContext context, DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return sameDay
        ? DateFormat.Hm(locale).format(local)
        : DateFormat.yMd(locale).format(local);
  }
}

/// Purpose: Show a page's history in a bottom sheet.
/// Inputs: `context`, the `entries`, and the two callbacks.
/// Returns: `Future<void>` completing when the sheet closes.
/// Side effects: Opens a modal route.
/// Notes: The narrow-window half of the layout decision: below the split
/// threshold there is no room for a second pane, and a history the learner has
/// to scroll past to reach the input would make the common case worse to serve
/// the rare one. Opening an entry closes the sheet, because the result it
/// produces is on the page behind it.
Future<void> showHistorySheet(
  BuildContext context, {
  required List<HistoryEntry> entries,
  required void Function(HistoryEntry entry) onOpen,
  required void Function(HistoryEntry entry) onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.historyTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: _SheetHistory(
                    entries: entries,
                    onOpen: (entry) {
                      Navigator.of(sheetContext).pop();
                      onOpen(entry);
                    },
                    onDelete: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// The sheet's own copy of the list, so deleting a row updates it in place.
class _SheetHistory extends StatefulWidget {
  const _SheetHistory({
    required this.entries,
    required this.onOpen,
    required this.onDelete,
  });

  final List<HistoryEntry> entries;
  final void Function(HistoryEntry entry) onOpen;
  final void Function(HistoryEntry entry) onDelete;

  @override
  State<_SheetHistory> createState() => _SheetHistoryState();
}

class _SheetHistoryState extends State<_SheetHistory> {
  late final List<HistoryEntry> _entries = List.of(widget.entries);

  /// Purpose: Build the sheet's list.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: The sheet keeps its own list because it is a route of its own: the
  /// provider behind the page rebuilds the page, not this. Removing the row
  /// here and letting the page write the file is what makes a delete look
  /// immediate without waiting for a save.
  @override
  Widget build(BuildContext context) {
    return HistoryList(
      entries: _entries,
      shrinkWrap: false,
      onOpen: widget.onOpen,
      onDelete: (entry) {
        setState(() => _entries.remove(entry));
        widget.onDelete(entry);
      },
    );
  }
}
