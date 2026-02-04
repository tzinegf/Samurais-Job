class ContentValidator {
  // Regex patterns
  static final RegExp _emailRegex = RegExp(
    r'\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b',
    caseSensitive: false,
  );

  static final RegExp _phoneRegex = RegExp(
    r'(\(?\d{2}\)?\s?)?(\d{4,5}[-\s]?\d{4})',
    caseSensitive: false,
  );
  
  // Detects URLs (http, https, www)
  static final RegExp _urlRegex = RegExp(
    r'((https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*))',
    caseSensitive: false,
  );

  static ValidationResult validate(String text) {
    if (_emailRegex.hasMatch(text)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'É proibido enviar e-mails pelo chat/orçamento. Mantenha a comunicação dentro da plataforma.',
        violationType: 'email',
      );
    }

    // Phone validation needs to be a bit smarter to avoid false positives (like prices, dates)
    // But for now, we'll check for the pattern.
    // If user types "1234-5678" or "(11) 91234-5678", it matches.
    if (_phoneRegex.hasMatch(text)) {
       // Optional: Filter out simple numbers if needed, but the regex enforces some structure or length
       // Let's rely on the regex for now.
       return ValidationResult(
        isValid: false,
        errorMessage: 'É proibido enviar telefones. Mantenha a comunicação segura dentro do aplicativo.',
        violationType: 'phone',
      );
    }

    if (_urlRegex.hasMatch(text)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'É proibido enviar links externos.',
        violationType: 'link',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? violationType;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.violationType,
  });
}
