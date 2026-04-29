import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../cubit/quiz_cubit.dart';
import '../cubit/quiz_state.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/answer_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/supabase_storage.dart';
import 'create_quiz_page.dart' show DarkField;

/// Edits an existing quiz, fetching details via [quizId].
class EditQuizPage extends StatefulWidget {
  final String quizId;
  const EditQuizPage({super.key, required this.quizId});

  @override
  State<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  String? _coverImageUrl;
  XFile? _coverImageFile;
  bool _isPublic = true;
  bool _isUploadingCover = false;
  List<_EditQuestionDraft> _questions = [];
  QuizModel? _loadedQuiz;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  void _initFromQuiz(QuizModel quiz) {
    if (_initialized) return;
    _initialized = true;
    _loadedQuiz = quiz;
    _titleCtrl.text = quiz.title;
    _descCtrl.text = quiz.description ?? '';
    _coverImageUrl = quiz.coverImageUrl;
    _isPublic = quiz.isPublic;

    _questions = quiz.questions.map((q) {
      return _EditQuestionDraft(
        id: q.id,
        textCtrl: TextEditingController(text: q.text),
        imageUrl: q.imageUrl,
        timeLimit: q.timeLimit,
        answers: List<AnswerModel>.from(q.answers),
      );
    }).toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final q in _questions) {
      q.textCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile == null) return;
    setState(() => _isUploadingCover = true);
    try {
      final url = await SupabaseStorageHelper.uploadQuizCover(xfile);
      setState(() {
        _coverImageUrl = url;
        _coverImageFile = xfile;
        _isUploadingCover = false;
      });
    } catch (e) {
      setState(() => _isUploadingCover = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.t('uploadFailed', params: {'error': '$e'}),
            ),
          ),
        );
      }
    }
  }

  Future<void> _save(BuildContext context) async {
    if (_loadedQuiz == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('addAtLeastOneQuestion'))),
      );
      return;
    }

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.textCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.t(
                'questionHasNoText',
                params: {'index': '${i + 1}'},
              ),
            ),
          ),
        );
        return;
      }
      if (!q.answers.any((a) => a.isCorrect)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.t(
                'questionNeedsCorrectAnswer',
                params: {'index': '${i + 1}'},
              ),
            ),
          ),
        );
        return;
      }
    }

    final updated = _loadedQuiz!.copyWith(
      title: _titleCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      coverImageUrl: _coverImageUrl,
      isPublic: _isPublic,
      questions: _questions
          .map((q) => QuestionModel(
                id: q.id,
                text: q.textCtrl.text.trim(),
                imageUrl: q.imageUrl,
                timeLimit: q.timeLimit,
                points: AppConstants.defaultPoints,
                answers: q.answers,
              ))
          .toList(),
    );

    context.read<QuizCubit>().updateQuiz(updated);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizCubit, QuizState>(
      listener: (context, state) {
        if (state is QuizSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.t('quizUpdated')),
              backgroundColor: Color(0xFF26890C),
            ),
          );
          context.pop(true);
        } else if (state is QuizError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFE21B3C),
            ),
          );
        } else if (state is QuizDetailLoaded) {
          setState(() {
            _initFromQuiz(state.quiz);
          });
        }
      },
      builder: (context, state) {
        if (!_initialized && (state is QuizLoading || state is QuizInitial)) {
          return const Scaffold(
            backgroundColor: Color(0xFF2D0A5E),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        return Scaffold(
        backgroundColor: const Color(0xFF2D0A5E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF46178F),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            context.l10n.t('editQuiz'),
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            BlocBuilder<QuizCubit, QuizState>(
              builder: (ctx, state) => TextButton(
                onPressed:
                    state is QuizLoading ? null : () => _save(context),
                child: state is QuizLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        context.l10n.t('save'),
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cover image
              GestureDetector(
                onTap: _isUploadingCover ? null : _pickCover,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: Colors.white24),
                    image: _coverImageFile != null
                        ? DecorationImage(
                            image: NetworkImage(_coverImageFile!.path),
                            fit: BoxFit.cover,
                          )
                        : (_coverImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_coverImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: (_coverImageFile == null && _coverImageUrl == null)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isUploadingCover
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Colors.white54,
                                    size: 40,
                                  ),
                            if (!_isUploadingCover)
                              Text(
                                context.l10n.t('addCoverImage'),
                                style: GoogleFonts.nunito(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit,
                                    color: Colors.white, size: 16),
                                onPressed: _pickCover,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              DarkField(
                controller: _titleCtrl,
                label: context.l10n.t('quizTitle'),
                hint: context.l10n.t('quizTitleHint'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.t('titleRequired')
                    : null,
              ),
              const SizedBox(height: 12),

              DarkField(
                controller: _descCtrl,
                label: context.l10n.t('descriptionOptional'),
                hint: context.l10n.t('quizDescriptionHint'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n.t('publicQuiz'),
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  value: _isPublic,
                  activeColor: const Color(0xFF26890C),
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                context.l10n.t(
                  'questionCountLabel',
                  params: {'count': '${_questions.length}'},
                ),
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),

              ..._questions.asMap().entries.map(
                    (e) => _EditQuestionCard(
                      key: ValueKey(e.value.uiKey),
                      index: e.key,
                      draft: e.value,
                      onRemove: () =>
                          setState(() => _questions.removeAt(e.key)),
                      onChanged: () => setState(() {}),
                    ),
                  ),

              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _questions.add(_EditQuestionDraft(
                    id: '',
                    textCtrl: TextEditingController(),
                    timeLimit: AppConstants.defaultTimeLimit,
                    answers: [
                      const AnswerModel(
                          id: '', text: '', isCorrect: false, color: '#E21B3C'),
                      const AnswerModel(
                          id: '', text: '', isCorrect: false, color: '#1368CE'),
                      const AnswerModel(
                          id: '', text: '', isCorrect: false, color: '#26890C'),
                      const AnswerModel(
                          id: '', text: '', isCorrect: false, color: '#FFA602'),
                    ],
                  ));
                }),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(
                  context.l10n.t('addQuestion'),
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit-specific question draft (keeps the server-assigned id)
// ─────────────────────────────────────────────────────────────────────────────

class _EditQuestionDraft {
  final String id;
  final String uiKey;
  final TextEditingController textCtrl;
  String? imageUrl;
  XFile? imageFile;
  int timeLimit;
  List<AnswerModel> answers;

  _EditQuestionDraft({
    required this.id,
    required this.textCtrl,
    this.imageUrl,
    this.imageFile,
    required this.timeLimit,
    required this.answers,
    String? uiKey,
  }) : uiKey = uiKey ?? UniqueKey().toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit question card (same layout as create, but pre-populated)
// ─────────────────────────────────────────────────────────────────────────────

class _EditQuestionCard extends StatefulWidget {
  final int index;
  final _EditQuestionDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _EditQuestionCard({
    super.key,
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_EditQuestionCard> createState() => _EditQuestionCardState();
}

class _EditQuestionCardState extends State<_EditQuestionCard> {
  late final List<TextEditingController> _answerCtrls;

  @override
  void initState() {
    super.initState();
    _answerCtrls = widget.draft.answers
        .map((a) => TextEditingController(text: a.text))
        .toList();
  }

  @override
  void didUpdateWidget(_EditQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.uiKey != widget.draft.uiKey) {
      for (int i = 0; i < _answerCtrls.length; i++) {
        _answerCtrls[i].text = widget.draft.answers[i].text;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _answerCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleCorrect(int idx) {
    final updated = widget.draft.answers.asMap().entries.map((e) {
      final a = e.value;
      return AnswerModel(
        id: a.id,
        text: _answerCtrls[e.key].text,
        isCorrect: e.key == idx ? !a.isCorrect : a.isCorrect,
        color: a.color,
      );
    }).toList();
    setState(() => widget.draft.answers = updated);
    widget.onChanged();
  }

  void _syncAnswerText() {
    widget.draft.answers = widget.draft.answers.asMap().entries.map((e) {
      final a = e.value;
      return AnswerModel(
        id: a.id,
        text: _answerCtrls[e.key].text,
        isCorrect: a.isCorrect,
        color: a.color,
      );
    }).toList();
    widget.onChanged();
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF46178F),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.index + 1}',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: widget.draft.textCtrl,
            style: GoogleFonts.nunito(
              color: const Color(0xFF1A1A2E),
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: context.l10n.t('questionText'),
              filled: true,
              fillColor: const Color(0xFFF5F0FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => widget.onChanged(),
            maxLines: 2,
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 16, color: Color(0xFF46178F)),
              const SizedBox(width: 8),
              Text(
                context.l10n.t(
                  'timeSeconds',
                  params: {'seconds': '${widget.draft.timeLimit}'},
                ),
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Slider(
            value: widget.draft.timeLimit.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            label: '${widget.draft.timeLimit}s',
            activeColor: const Color(0xFF46178F),
            onChanged: (v) {
              setState(() => widget.draft.timeLimit = v.toInt());
              widget.onChanged();
            },
          ),

          Text(
            context.l10n.t('answersTapToMarkCorrect'),
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),

          ...List.generate(2, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: List.generate(2, (col) {
                  final idx = row * 2 + col;
                  final a = widget.draft.answers[idx];
                  final color = _hexToColor(a.color);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: col == 1 ? 6 : 0),
                      child: GestureDetector(
                        onTap: () => _toggleCorrect(idx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: a.isCorrect
                                  ? color
                                  : color.withOpacity(0.3),
                              width: a.isCorrect ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                a.isCorrect
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: color,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: _answerCtrls[idx],
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: context.l10n.t(
                                      'answerHint',
                                      params: {'index': '${idx + 1}'},
                                    ),
                                    hintStyle: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400]),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => _syncAnswerText(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}
