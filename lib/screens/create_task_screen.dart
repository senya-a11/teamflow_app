import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../services/api_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  List<Map<String, dynamic>> _crew = [];
  int? _selectedCrewId;
  DateTime? _selectedDeadline;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCrew();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadCrew() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final crew = await ApiService.getCrew(token);
      setState(() {
        _crew = crew;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить список команды';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF6C63FF)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDeadline = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      setState(() => _error = 'Заполните название и описание');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();

    final success = await taskProvider.createTask(
      token: auth.token!,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      assignedTo: _selectedCrewId,
      deadline: _selectedDeadline?.toIso8601String().split('T').first,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _error = taskProvider.error ?? 'Ошибка создания задачи';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: const Text('Новая задача', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 2),
                  )
                : const Text('Создать', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 16)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ),

                  _buildLabel('Название задачи'),
                  const SizedBox(height: 8),
                  _buildTextField(_titleController, 'Например: Подготовить отчёт'),

                  const SizedBox(height: 20),
                  _buildLabel('Описание'),
                  const SizedBox(height: 8),
                  _buildTextField(_contentController, 'Подробное описание задачи...', maxLines: 5),

                  const SizedBox(height: 20),
                  _buildLabel('Исполнитель'),
                  const SizedBox(height: 8),
                  _buildDropdown(),

                  const SizedBox(height: 20),
                  _buildLabel('Дедлайн'),
                  const SizedBox(height: 8),
                  _buildDeadlinePicker(),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedCrewId,
          isExpanded: true,
          dropdownColor: const Color(0xFF16213E),
          style: const TextStyle(color: Colors.white),
          hint: const Text('Не назначен', style: TextStyle(color: Colors.white38)),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Не назначен')),
            ..._crew.map((u) => DropdownMenuItem<int?>(
                  value: u['id'] as int,
                  child: Text(u['username'] as String),
                )),
          ],
          onChanged: (val) => setState(() => _selectedCrewId = val),
        ),
      ),
    );
  }

  Widget _buildDeadlinePicker() {
    return GestureDetector(
      onTap: _pickDeadline,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white38, size: 18),
            const SizedBox(width: 12),
            Text(
              _selectedDeadline != null
                  ? '${_selectedDeadline!.day}.${_selectedDeadline!.month}.${_selectedDeadline!.year}'
                  : 'Выбрать дату',
              style: TextStyle(
                color: _selectedDeadline != null ? Colors.white : Colors.white38,
              ),
            ),
            const Spacer(),
            if (_selectedDeadline != null)
              GestureDetector(
                onTap: () => setState(() => _selectedDeadline = null),
                child: const Icon(Icons.close, color: Colors.white38, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
