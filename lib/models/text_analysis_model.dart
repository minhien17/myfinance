import 'package:my_finance/utils.dart';

class TextAnalysisResult {
  final int count;
  final List<AnalyzedTransaction> transactions;

  TextAnalysisResult({
    required this.count,
    required this.transactions,
  });

  factory TextAnalysisResult.fromJson(Map<String, dynamic> json) {
    return TextAnalysisResult(
      count: json['count'] ?? 0,
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => AnalyzedTransaction.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AnalyzedTransaction {
  final String sentence;
  final double amount;
  final double amountConfidence;
  final String matchedText;
  final String extractionMethod;
  final String category;
  final double categoryConfidence;
  final List<CategorySuggestion> suggestions;
  final String model;

  // Fields for editing
  bool isSelected;
  String editedCategory;
  double editedAmount;
  String editedNote;
  DateTime editedDate;

  AnalyzedTransaction({
    required this.sentence,
    required this.amount,
    required this.amountConfidence,
    required this.matchedText,
    required this.extractionMethod,
    required this.category,
    required this.categoryConfidence,
    required this.suggestions,
    required this.model,
    this.isSelected = true,
    String? editedCategory,
    double? editedAmount,
    String? editedNote,
    DateTime? editedDate,
  })  : editedCategory = editedCategory ?? category,
        editedAmount = editedAmount ?? amount,
        editedNote = editedNote ?? (sentence.isNotEmpty ? sentence : matchedText),
        editedDate = editedDate ?? DateTime.now();

  factory AnalyzedTransaction.fromJson(Map<String, dynamic> json) {
    return AnalyzedTransaction(
      sentence: json['note'] ?? json['sentence'] ?? '',  // Backend trả về 'note'
      amount: Common.parseDouble(json['amount']),
      amountConfidence: Common.parseDouble(json['amountConfidence']),
      matchedText: json['matchedText'] ?? '',
      extractionMethod: json['extractionMethod'] ?? '',
      category: json['category'] ?? 'other',
      categoryConfidence: Common.parseDouble(json['categoryConfidence']),
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => CategorySuggestion.fromJson(e))
              .toList() ??
          [],
      model: json['model'] ?? '',
    );
  }

  Map<String, dynamic> toSaveJson() {
    return {
      'amount': editedAmount,
      'category': editedCategory,
      'note': editedNote,
      'dateTime': editedDate.toUtc().toIso8601String(),
    };
  }
}

class CategorySuggestion {
  final String category;
  final double confidence;

  CategorySuggestion({
    required this.category,
    required this.confidence,
  });

  factory CategorySuggestion.fromJson(Map<String, dynamic> json) {
    return CategorySuggestion(
      category: json['category'] ?? '',
      confidence: Common.parseDouble(json['confidence']),
    );
  }
}
