import 'package:ack/src/helpers.dart';

class Template {
  final String _content;
  final Map<String, Object?> _data;

  const Template(this._content, {Map<String, Object?>? data})
      : _data = data ?? const {};

  /// Orchestrates both loop parsing and variable replacement
  /// Modified method to include conditionals processing
  String _renderTemplate(String template, Map<String, Object?> data) {
    // First handle conditionals (recursively)
    final withConditionalsHandled = _processConditionals(template, data);

    // Then handle loops (recursively)
    final withLoopsHandled = _processLoops(withConditionalsHandled, data);

    // Finally handle variable substitutions
    return _processVariables(withLoopsHandled, data);
  }

  String _processConditionals(String template, Map<String, Object?> data) {
    // Find the first conditional opening
    final startRegex = RegExp(r'\{\{#if\s+([^\}]+)\}\}\n?');
    final startMatch = startRegex.firstMatch(template);

    if (startMatch == null) {
      return template; // No conditional, nothing more to do
    }

    final condition = startMatch.group(1)?.trim() ?? '';
    final startTagEnd = startMatch.end;

    // Find matching else and /if tags, accounting for nested conditionals
    final tagRegex = RegExp(r'\{\{(#if\s+[^\}]+|else|\/if)\}\}');
    int nested = 1;
    int elseTagStart = -1;
    int endTagStart = -1;

    for (final match in tagRegex.allMatches(template, startTagEnd)) {
      final tag = match.group(0)!;

      if (tag.startsWith('{{#if')) {
        nested++;
      } else if (tag == '{{else}}' && nested == 1 && elseTagStart == -1) {
        elseTagStart = match.start;
      } else if (tag == '{{/if}}') {
        nested--;
        if (nested == 0) {
          endTagStart = match.start;
          break;
        }
      }
    }

    if (endTagStart == -1) {
      // No matching closing tag found
      return template;
    }

    final closingRegex = RegExp(r'\{\{/if\}\}\n?');
    final closingMatch = closingRegex.matchAsPrefix(template, endTagStart);
    final endIndex = closingMatch != null
        ? closingMatch.end
        : endTagStart + '{{/if}}'.length;

    // Extract if and else blocks
    final ifContent = elseTagStart == -1
        ? template.substring(startTagEnd, endTagStart)
        : template.substring(startTagEnd, elseTagStart);

    final elseContent = elseTagStart == -1
        ? ''
        : template.substring(elseTagStart + '{{else}}'.length, endTagStart);

    // Evaluate the condition
    final conditionResult = _evaluateCondition(condition, data);

    // Render the appropriate block
    final renderedBlock = conditionResult ? ifContent : elseContent;

    // Replace the entire conditional block with the rendered content
    final updatedTemplate =
        template.replaceRange(startMatch.start, endIndex, renderedBlock);

    // Recursively handle any further conditionals in the updated template
    return _processConditionals(updatedTemplate, data);
  }

  bool _evaluateCondition(String condition, Map<String, Object?> data) {
    // Get the value from data
    final value = _getNestedValue(data, condition);

    // Convert to boolean using the extension method

    return value.isTruthy;
  }
  // =========================================================
  // LOOP HANDLING
  // =========================================================

  String _processLoops(String template, Map<String, Object?> data) {
    // Find the first loop opening
    final startRegex = RegExp(r'\{\{#each\s+([^\}]+)\}\}\n?');
    final startMatch = startRegex.firstMatch(template);

    if (startMatch == null) {
      return template; // No loop, nothing more to do
    }

    final path = startMatch.group(1)?.trim() ?? '';
    final startTagEnd = startMatch.end;

    // Find matching /each, accounting for nested loops
    final tagRegex = RegExp(r'\{\{(#each\s+[^\}]+|\/each)\}\}');
    int nested = 1;
    int endTagStart = -1;

    for (final match in tagRegex.allMatches(template, startTagEnd)) {
      if (match.group(0)!.startsWith('{{#each')) {
        nested++;
      } else {
        nested--;
      }
      if (nested == 0) {
        endTagStart = match.start;
        break;
      }
    }

    if (endTagStart == -1) {
      // No matching closing tag found
      return template;
    }

    final closingRegex = RegExp(r'\{\{/each\}\}\n?');
    final closingMatch = closingRegex.matchAsPrefix(template, endTagStart);
    final endIndex = closingMatch != null
        ? closingMatch.end
        : endTagStart + '{{/each}}'.length;

    final blockContent = template.substring(startTagEnd, endTagStart);

    // Retrieve the data for iteration
    final loopData = _getNestedValue(data, path);
    final renderedBlock = _renderLoop(loopData, blockContent);

    // Replace the entire `{{#each}} ... {{/each}}` block with the expanded text
    final updatedTemplate =
        template.replaceRange(startMatch.start, endIndex, renderedBlock);

    // Recursively handle any further loops in the updated template
    return _processLoops(updatedTemplate, data);
  }

  String _renderLoop(Object? collection, String blockContent) {
    final result = StringBuffer();
    int index = 0;

    Iterable entries;
    if (collection is List) {
      entries = collection.asMap().entries; // Convert list to map-like entries
    } else if (collection is Map) {
      entries = collection.entries;
    } else {
      return ''; // Invalid input
    }

    for (final entry in entries) {
      final key = entry.key;
      final value = entry.value;
      final localContext = <String, Object?>{
        '@this': collection is List ? value : {'key': key, 'value': value},
        '@index': index++,
      };

      if (value is Map) {
        value.forEach((k, v) {
          if (k is String) localContext[k] = v;
        });
      }

      String rendered = _renderTemplate(blockContent, {...localContext});
      result.write(rendered);
    }

    return result.toString();
  }
  // =========================================================
  // VARIABLE HANDLING
  // =========================================================

  String _processVariables(String template, Map<String, Object?> data) {
    return template.replaceAllMapped(
      RegExp(r'{{\s*([@\w.]+)\s*}}'),
      (match) {
        final path = match.group(1) ?? '';
        final value = _getNestedValue(data, path);

        // Default to 'N/A' if value is null
        return value?.toString() ?? 'N/A';
      },
    );
  }

  // =========================================================
  // LOOKUP HELPER
  // =========================================================

  Object? _getNestedValue(Map<String, Object?> data, String path) {
    final keys = path.split('.');
    Object? current = data;

    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      }
      if (key == 'length') {
        final currentValue = current;
        if (currentValue is Iterable) return currentValue.length;
        if (currentValue is Map) return currentValue.length;
        if (currentValue is String) return currentValue.length;
      }
    }

    return current;
  }

  String render({
    Map<String, Object?>? overrideData,
    TemplateRenderer? customRenderer,
  }) {
    final renderData = overrideData ?? _data;

    if (customRenderer == null) {
      return _renderTemplate(_content, renderData);
    }

    final customRenderedData = <String, Object?>{};

    for (final entry in renderData.entries) {
      final customRendered = customRenderer(entry);
      customRenderedData[entry.key] = customRendered;
    }

    return _renderTemplate(_content, customRenderedData);
  }
}

typedef TemplateRenderer = String Function(MapEntry<String, Object?> entry);
