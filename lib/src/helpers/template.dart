class Template {
  final String _content;
  final Map<String, Object?> _data;

  const Template(this._content, {Map<String, Object?>? data})
      : _data = data ?? const {};

  /// Orchestrates both loop parsing and variable replacement
  String _renderTemplate(String template, Map<String, Object?> data) {
    // First handle loops (recursively)
    final withLoopsHandled = _processLoops(template, data);

    // Then handle variable substitutions
    return _processVariables(withLoopsHandled, data);
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

  String _renderLoop(Object? value, String blockContent) {
    if (value is List) {
      return _renderListLoop(value, blockContent);
    } else if (value is Map) {
      return _renderMapLoop(value, blockContent);
    }

    return '';
  }

  String _renderListLoop(List items, String blockContent) {
    final result = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final localContext = <String, Object?>{'@this': item, '@index': i};

      if (item is Map) {
        // Flatten all item properties into local context
        item.forEach((k, v) {
          if (k is String) localContext[k] = v;
        });
      }

      // Render the sub-block
      result.write(_renderTemplate(blockContent, {...localContext}));
    }

    return result.toString();
  }

  String _renderMapLoop(Map map, String blockContent) {
    final result = StringBuffer();
    var index = 0;
    map.forEach((key, value) {
      final localContext = <String, Object?>{
        '@this': {'key': key, 'value': value},
        '@index': index++,
      };

      if (value is Map) {
        value.forEach((k, v) {
          if (k is String) localContext[k] = v;
        });
      }

      // Render the sub-block
      result.write(_renderTemplate(blockContent, {...localContext}));
    });

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
      } else if (current is List && key == 'length') {
        return current.length;
      } else {
        return null;
      }
    }

    return current;
  }

  String render([Map<String, Object?>? overrideData]) {
    final renderData = overrideData ?? _data;

    return _renderTemplate(_content, renderData);
  }
}
