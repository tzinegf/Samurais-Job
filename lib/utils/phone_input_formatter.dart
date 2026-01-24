import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Clean all non-digit characters
    final newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limit to 11 digits
    if (newText.length > 11) {
      return oldValue;
    }

    final buffer = StringBuffer();
    int selectionIndex = newValue.selection.end;

    // Adjust selection index based on added characters
    // This part is tricky without a proper mask library.
    // Simplest approach: formatting applied, cursor at end.
    // Most users type phone numbers linearly.
    
    for (int i = 0; i < newText.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(newText[i]);
    }

    final String formatted = buffer.toString();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
