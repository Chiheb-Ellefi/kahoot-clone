import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../../../../core/utils/supabase_storage.dart';

/// Creates a brand-new quiz with questions and answers.
class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _coverImageUrl;
  XFile? _coverImageFile;
  bool _isPublic = true;
  bool _isUploadingCover = false;

  final List<_QuestionDraft> _questions = [_QuestionDraft.empty()];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─── Pick & upload cover image ─────────────────────────────────────────
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
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionDraft.empty());
    });
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one question.')),
      );
      return;
    }

    // Validate all questions
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.textCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1} has no text.')),
        );
        return;
      }
      if (!q.answers.any((a) => a.isCorrect)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Question ${i + 1} needs at least one correct answer.'),
          ),
        );
        return;
      }
    }

    final quiz = QuizModel(
      id: '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      coverImageUrl: _coverImageUrl,
      isPublic: _isPublic,
      questions: _questions.asMap().entries.map((e) {
        final q = e.value;
        return QuestionModel(
          id: '',
          text: q.textCtrl.text.trim(),
          imageUrl: q.imageUrl,
          timeLimit: q.timeLimit,
          points: AppConstants.defaultPoints,
          answers: q.answers,
        );
      }).toList(),
    );

    context.read<QuizCubit>().createQuiz(quiz);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuizCubit, QuizState>(
      listener: (context, state) {
        if (state is QuizSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quiz created! 🎉'),
              backgroundColor: Color(0xFF26890C),
            ),
          );
          context.go('/home');
        } else if (state is QuizError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFE21B3C),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2D0A5E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF46178F),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Create Quiz',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            BlocBuilder<QuizCubit, QuizState>(
              builder: (context, state) => TextButton(
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
                        'Save',
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
              // ── Cover image picker ────────────────────────────────────
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
                            image: kIsWeb
                                ? NetworkImage(_coverImageFile!.path)
                                    as ImageProvider
                                : NetworkImage(_coverImageFile!.path),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _coverImageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isUploadingCover
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Icon(Icons.add_photo_alternate_outlined,
                                    color: Colors.white54, size: 40),
                            const SizedBox(height: 8),
                            if (!_isUploadingCover)
                              Text(
                                'Add Cover Image',
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

              // ── Title ─────────────────────────────────────────────────
              DarkField(
                controller: _titleCtrl,
                label: 'Quiz Title',
                hint: 'e.g. World Geography',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),

              DarkField(
                controller: _descCtrl,
                label: 'Description (optional)',
                hint: 'A short description of this quiz',
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // ── Public toggle ─────────────────────────────────────────
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
                    'Public Quiz',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _isPublic
                        ? 'Visible to everyone'
                        : 'Only visible to you',
                    style: GoogleFonts.nunito(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  value: _isPublic,
                  activeColor: const Color(0xFF26890C),
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
              ),
              const SizedBox(height: 24),

              // ── Questions section ──────────────────────────────────────
              Row(
                children: [
                  Text(
                    'Questions (${_questions.length})',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Question draft cards
              ..._questions.asMap().entries.map((e) => _QuestionDraftCard(
                    key: ValueKey(e.key),
                    index: e.key,
                    draft: e.value,
                    onRemove: () => _removeQuestion(e.key),
                    onChanged: () => setState(() {}),
                  )),

              const SizedBox(height: 12),

              // Add question button
              OutlinedButton.icon(
                onPressed: _addQuestion,
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
                  'Add Question',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared question draft model (mutable, used only in the form)
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionDraft {
  final TextEditingController textCtrl;
  String? imageUrl;
  XFile? imageFile;
  int timeLimit;
  List<AnswerModel> answers;

  _QuestionDraft({
    required this.textCtrl,
    this.imageUrl,
    this.imageFile,
    required this.timeLimit,
    required this.answers,
  });


  factory _QuestionDraft.empty() {
    return _QuestionDraft(
      textCtrl: TextEditingController(),
      timeLimit: AppConstants.defaultTimeLimit,
      answers: const [
        AnswerModel(id: '', text: '', isCorrect: false, color: '#E21B3C'),
        AnswerModel(id: '', text: '', isCorrect: false, color: '#1368CE'),
        AnswerModel(id: '', text: '', isCorrect: false, color: '#26890C'),
        AnswerModel(id: '', text: '', isCorrect: false, color: '#FFA602'),
      ],
    );
  }

  void dispose() => textCtrl.dispose();
}

// ─────────────────────────────────────────────────────────────────────────────
// Question draft card widget
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionDraftCard extends StatefulWidget {
  final int index;
  final _QuestionDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _QuestionDraftCard({
    super.key,
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_QuestionDraftCard> createState() => _QuestionDraftCardState();
}

class _QuestionDraftCardState extends State<_QuestionDraftCard> {
  final List<TextEditingController> _answerCtrls = [];
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    for (final a in widget.draft.answers) {
      _answerCtrls.add(TextEditingController(text: a.text));
    }
  }

  @override
  void dispose() {
    for (final c in _answerCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    setState(() => _isUploadingImage = true);
    try {
      final url = await SupabaseStorageHelper.uploadQuestionImage(xfile);
      setState(() {
        widget.draft.imageUrl = url;
        widget.draft.imageFile = xfile;
        _isUploadingImage = false;
      });
      widget.onChanged();
    } catch (_) {
      setState(() => _isUploadingImage = false);
    }
  }

  void _toggleCorrect(int answerIndex) {
    final updated = widget.draft.answers.asMap().entries.map((e) {
      final a = e.value;
      return AnswerModel(
        id: a.id,
        text: _answerCtrls[e.key].text,
        isCorrect: e.key == answerIndex ? !a.isCorrect : a.isCorrect,
        color: a.color,
      );
    }).toList();
    setState(() {
      widget.draft.answers = updated;
    });
    widget.onChanged();
  }

  void _updateAnswerText(int answerIndex) {
    final updated = widget.draft.answers.asMap().entries.map((e) {
      final a = e.value;
      return AnswerModel(
        id: a.id,
        text: _answerCtrls[e.key].text,
        isCorrect: a.isCorrect,
        color: a.color,
      );
    }).toList();
    widget.draft.answers = updated;
    widget.onChanged();
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
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
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

          // Question text field
          TextFormField(
            controller: widget.draft.textCtrl,
            style: GoogleFonts.nunito(
              color: const Color(0xFF1A1A2E),
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Question text',
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
          const SizedBox(height: 12),

          // Time limit slider
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 16, color: Color(0xFF46178F)),
              const SizedBox(width: 8),
              Text(
                'Time: ${widget.draft.timeLimit}s',
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

          // Optional image
          Row(
            children: [
              TextButton.icon(
                onPressed: _isUploadingImage ? null : _pickImage,
                icon: _isUploadingImage
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_outlined,
                        size: 16, color: Color(0xFF46178F)),
                label: Text(
                  widget.draft.imageFile != null
                      ? 'Change image ✓'
                      : 'Add image',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF46178F),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.draft.imageFile != null)
                const Icon(Icons.check_circle,
                    color: Color(0xFF26890C), size: 16),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            'Answers (tap ✓ to mark correct)',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),

          // Answer fields — 2x2 grid
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
                                    hintText: 'Answer ${idx + 1}',
                                    hintStyle: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => _updateAnswerText(idx),
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

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dark theme input field (for the purple quiz background)
// ─────────────────────────────────────────────────────────────────────────────

class DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const DarkField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.nunito(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
