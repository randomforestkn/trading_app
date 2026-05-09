import 'package:flutter/widgets.dart';

import '../data/app_result.dart';
import '../utils/app_logger.dart';
import 'journal_entry.dart';
import 'journal_repository.dart';
import 'local_journal_repository.dart';

class JournalState extends ChangeNotifier {
  JournalState({JournalRepository? repository})
    : _repository = repository ?? const LocalJournalRepository();

  final JournalRepository _repository;
  final List<JournalEntry> _entries = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  List<JournalEntry> get entries => List.unmodifiable(_sortedEntries());

  List<JournalEntry> get recentEntries {
    final sorted = _sortedEntries();
    return List.unmodifiable(sorted.take(5).toList(growable: false));
  }

  List<JournalEntry> entriesForSymbol(String symbol) {
    return List.unmodifiable(
      _sortedEntries()
          .where(
            (entry) =>
                entry.linkedAssetSymbol?.toLowerCase() == symbol.toLowerCase(),
          )
          .toList(growable: false),
    );
  }

  List<JournalEntry> entriesForStrategy(JournalStrategyType strategy) {
    return List.unmodifiable(
      _sortedEntries()
          .where((entry) => entry.linkedStrategy == strategy)
          .toList(growable: false),
    );
  }

  List<JournalEntry> entriesForOutcome(JournalOutcome outcome) {
    return List.unmodifiable(
      _sortedEntries()
          .where((entry) => entry.outcome == outcome)
          .toList(growable: false),
    );
  }

  static Future<JournalState> load({JournalRepository? repository}) async {
    final journalState = JournalState(repository: repository);
    await journalState.restore();
    return journalState;
  }

  Future<void> restore() async {
    _setLoading(true);
    late final AppResult<List<JournalEntry>> result;
    try {
      result = await _repository.loadEntries();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Journal restore threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to restore journal entries.';
      _setLoading(false);
      return;
    }
    result.when(
      success: (entries) {
        _entries
          ..clear()
          ..addAll(entries);
        _sortEntries();
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Journal restore failed', error: message);
        _errorMessage = message;
      },
    );
    _setLoading(false);
  }

  Future<void> addEntry(JournalEntry entry) async {
    final now = DateTime.now();
    final normalized = entry.copyWith(
      id: entry.id.isEmpty ? _createId(now) : entry.id,
      updatedAt: now,
      createdAt: entry.createdAt,
    );
    _entries.removeWhere((candidate) => candidate.id == normalized.id);
    _entries.insert(0, normalized);
    _sortEntries();
    notifyListeners();
    await _persistEntries('Unable to save journal entry.');
  }

  Future<void> updateEntry(JournalEntry entry) async {
    final index = _entries.indexWhere((candidate) => candidate.id == entry.id);
    final updated = entry.copyWith(updatedAt: DateTime.now());
    if (index == -1) {
      _entries.insert(0, updated);
    } else {
      _entries[index] = updated;
    }
    _sortEntries();
    notifyListeners();
    await _persistEntries('Unable to update journal entry.');
  }

  Future<void> deleteEntry(String id) async {
    _setSaving(true);
    late final AppResult<void> result;
    try {
      result = await _repository.deleteEntry(id);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Unable to delete journal entry.',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to delete journal entry.';
      _setSaving(false);
      notifyListeners();
      return;
    }
    result.when(
      success: (_) {
        _entries.removeWhere((candidate) => candidate.id == id);
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Unable to delete journal entry.', error: message);
        _errorMessage = message;
      },
    );
    _setSaving(false);
    notifyListeners();
  }

  JournalEntry? entryById(String id) {
    for (final entry in _entries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  Future<void> clearAll() async {
    _setSaving(true);
    late final AppResult<void> result;
    try {
      result = await _repository.clearEntries();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Journal clear threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to clear journal entries.';
      _setSaving(false);
      notifyListeners();
      return;
    }
    result.when(
      success: (_) {
        _entries.clear();
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Journal clear failed', error: message);
        _errorMessage = message;
      },
    );
    _setSaving(false);
    notifyListeners();
  }

  Future<void> _persistEntries(String failureMessage) async {
    _setSaving(true);
    late final AppResult<void> result;
    try {
      result = await _repository.saveEntries(_sortedEntries());
    } catch (error, stackTrace) {
      AppLogger.error(failureMessage, error: error, stackTrace: stackTrace);
      _errorMessage = failureMessage;
      _setSaving(false);
      return;
    }
    result.when(
      success: (_) {
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn(failureMessage, error: message);
        _errorMessage = message;
      },
    );
    _setSaving(false);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  void _sortEntries() {
    _entries.sort((left, right) {
      final updatedComparison = right.updatedAt.compareTo(left.updatedAt);
      if (updatedComparison != 0) {
        return updatedComparison;
      }
      return right.createdAt.compareTo(left.createdAt);
    });
  }

  List<JournalEntry> _sortedEntries() {
    final sorted = List<JournalEntry>.of(_entries);
    sorted.sort((left, right) {
      final updatedComparison = right.updatedAt.compareTo(left.updatedAt);
      if (updatedComparison != 0) {
        return updatedComparison;
      }
      return right.createdAt.compareTo(left.createdAt);
    });
    return sorted;
  }

  String _createId(DateTime timestamp) {
    return 'journal-${timestamp.microsecondsSinceEpoch}';
  }
}

class JournalScope extends InheritedNotifier<JournalState> {
  const JournalScope({
    required JournalState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static JournalState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<JournalScope>();
    assert(scope != null, 'JournalScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
