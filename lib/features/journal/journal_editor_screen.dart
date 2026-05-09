import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/journal/journal_entry.dart';
import '../../core/journal/journal_state.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/section_header.dart';

class JournalEditorScreen extends StatefulWidget {
  const JournalEditorScreen({
    super.key,
    this.initialEntry,
    this.prefillTitle,
    this.prefillBody,
    this.prefillLinkedOrderId,
    this.prefillLinkedAssetSymbol,
    this.prefillLinkedStrategy,
    this.prefillMood,
    this.prefillOutcome,
    this.prefillLessonsLearned,
    this.prefillTags,
  });

  final JournalEntry? initialEntry;
  final String? prefillTitle;
  final String? prefillBody;
  final String? prefillLinkedOrderId;
  final String? prefillLinkedAssetSymbol;
  final JournalStrategyType? prefillLinkedStrategy;
  final JournalMood? prefillMood;
  final JournalOutcome? prefillOutcome;
  final String? prefillLessonsLearned;
  final List<String>? prefillTags;

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _assetSymbolController = TextEditingController();
  final TextEditingController _lessonsController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  JournalStrategyType? _strategy;
  JournalMood? _mood;
  JournalOutcome? _outcome;
  int _conviction = 3;
  int _risk = 3;
  bool _didSeed = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _orderIdController.dispose();
    _assetSymbolController.dispose();
    _lessonsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSeed) {
      return;
    }
    _didSeed = true;
    final entry = widget.initialEntry;
    _titleController.text = widget.prefillTitle ?? entry?.title ?? '';
    _bodyController.text = widget.prefillBody ?? entry?.body ?? '';
    _orderIdController.text =
        widget.prefillLinkedOrderId ?? entry?.linkedOrderId ?? '';
    _assetSymbolController.text =
        widget.prefillLinkedAssetSymbol ?? entry?.linkedAssetSymbol ?? '';
    _lessonsController.text =
        widget.prefillLessonsLearned ?? entry?.lessonsLearned ?? '';
    _tagsController.text = (widget.prefillTags ?? entry?.tags ?? const []).join(
      ', ',
    );
    _strategy = widget.prefillLinkedStrategy ?? entry?.linkedStrategy;
    _mood = widget.prefillMood ?? entry?.mood;
    _outcome = widget.prefillOutcome ?? entry?.outcome;
    _conviction = entry?.convictionRating ?? _conviction;
    _risk = entry?.riskRating ?? _risk;
  }

  @override
  Widget build(BuildContext context) {
    final journalState = JournalScope.of(context);
    final isEditing = widget.initialEntry != null;

    return AppPage(
      title: isEditing ? 'Edit journal entry' : 'New journal entry',
      subtitle: 'Record rationale, emotion, and post-trade review',
      actions: [
        IconButton(
          tooltip: 'Save',
          onPressed: journalState.isSaving ? null : () => _save(context),
          icon: const Icon(Icons.save_outlined),
        ),
      ],
      children: [
        const AppInfoBanner(
          title: 'Private trading notes',
          message:
              'Use this space to capture the thinking behind a trade, how you felt, and what to improve next time.',
          icon: Icons.lock_outline,
          accentColor: AppTheme.secondary,
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _detailsCard(context),
              const SizedBox(height: 12),
              _classificationCard(context),
              const SizedBox(height: 12),
              _ratingsCard(context),
              if (isEditing) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: AppSecondaryButton(
                    label: 'Delete entry',
                    icon: Icons.delete_outline,
                    onPressed: journalState.isSaving
                        ? null
                        : () => _confirmDelete(context, journalState),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              AppCard(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppSecondaryButton(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      onPressed: journalState.isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                    AppPrimaryButton(
                      label: isEditing ? 'Update entry' : 'Save entry',
                      icon: Icons.save,
                      onPressed: journalState.isSaving
                          ? null
                          : () => _save(context),
                    ),
                  ],
                ),
              ),
              if (journalState.errorMessage != null) ...[
                const SizedBox(height: 12),
                AppInfoBanner(
                  title: 'Journal update failed',
                  message: journalState.errorMessage!,
                  icon: Icons.warning_amber_outlined,
                  accentColor: AppTheme.danger,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailsCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Entry details'),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.title_outlined),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a title.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bodyController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              prefixIcon: Icon(Icons.notes_outlined),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            minLines: 3,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Add trade notes.'
                : null,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 240,
                child: TextFormField(
                  controller: _assetSymbolController,
                  decoration: const InputDecoration(
                    labelText: 'Asset symbol',
                    prefixIcon: Icon(Icons.show_chart),
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextFormField(
                  controller: _orderIdController,
                  decoration: const InputDecoration(
                    labelText: 'Linked order ID',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _classificationCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Classification'),
          DropdownButtonFormField<JournalStrategyType?>(
            initialValue: _strategy,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Strategy',
              prefixIcon: Icon(Icons.tune),
            ),
            items: [
              const DropdownMenuItem<JournalStrategyType?>(
                value: null,
                child: Text('None'),
              ),
              ...JournalStrategyType.values.map(
                (value) => DropdownMenuItem<JournalStrategyType?>(
                  value: value,
                  child: Text(value.label),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _strategy = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<JournalMood?>(
            initialValue: _mood,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Mood',
              prefixIcon: Icon(Icons.mood_outlined),
            ),
            items: [
              const DropdownMenuItem<JournalMood?>(
                value: null,
                child: Text('None'),
              ),
              ...JournalMood.values.map(
                (value) => DropdownMenuItem<JournalMood?>(
                  value: value,
                  child: Text(value.label),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _mood = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<JournalOutcome?>(
            initialValue: _outcome,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Outcome',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            items: [
              const DropdownMenuItem<JournalOutcome?>(
                value: null,
                child: Text('None'),
              ),
              ...JournalOutcome.values.map(
                (value) => DropdownMenuItem<JournalOutcome?>(
                  value: value,
                  child: Text(value.label),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _outcome = value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lessonsController,
            decoration: const InputDecoration(
              labelText: 'Lessons learned',
              prefixIcon: Icon(Icons.lightbulb_outline),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            minLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags, comma-separated',
              prefixIcon: Icon(Icons.local_offer_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingsCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Risk and conviction'),
          _RatingSlider(
            label: 'Conviction',
            value: _conviction,
            onChanged: (value) => setState(() => _conviction = value),
          ),
          const SizedBox(height: 10),
          _RatingSlider(
            label: 'Risk',
            value: _risk,
            onChanged: (value) => setState(() => _risk = value),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final journalState = JournalScope.of(context);
    final now = DateTime.now();
    final entry = JournalEntry(
      id: widget.initialEntry?.id ?? '',
      createdAt: widget.initialEntry?.createdAt ?? now,
      updatedAt: widget.initialEntry?.updatedAt ?? now,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      linkedOrderId: _normalizedText(_orderIdController.text),
      linkedAssetSymbol: _normalizedText(_assetSymbolController.text),
      linkedStrategy: _strategy,
      mood: _mood,
      convictionRating: _conviction,
      riskRating: _risk,
      outcome: _outcome,
      lessonsLearned: _normalizedText(_lessonsController.text),
      tags: _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false),
    );

    if (widget.initialEntry == null) {
      await journalState.addEntry(entry);
    } else {
      await journalState.updateEntry(entry);
    }
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    JournalState journalState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete journal entry?'),
        content: const Text(
          'This removes the note permanently from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete entry'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await journalState.deleteEntry(widget.initialEntry!.id);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  String? _normalizedText(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _RatingSlider extends StatelessWidget {
  const _RatingSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            '$label ${value.toString()} / 5',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toString(),
            onChanged: (next) => onChanged(next.round()),
          ),
        ),
      ],
    );
  }
}
