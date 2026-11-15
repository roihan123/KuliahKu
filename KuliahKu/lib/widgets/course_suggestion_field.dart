import 'package:flutter/material.dart';

/// Input nama mata kuliah disertai chip saran cepat dari mata kuliah yang sudah ada.
class CourseSuggestionField extends StatelessWidget {
  const CourseSuggestionField({
    required this.controller,
    required this.suggestions,
    this.labelText = 'Mata Kuliah (Opsional)',
    this.hintText = 'Nama mata kuliah',
    this.validator,
    super.key,
  });

  final TextEditingController controller;
  final List<String> suggestions;
  final String labelText;
  final String hintText;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            prefixIcon: const Icon(Icons.book_outlined, size: 20),
          ),
          validator: validator,
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final current = value.text.trim();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final course in suggestions.take(8))
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          avatar: current.toLowerCase() == course.toLowerCase()
                              ? const Icon(Icons.check, size: 14)
                              : null,
                          label: Text(course, style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            controller.text = course;
                            controller.selection = TextSelection.collapsed(offset: course.length);
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
