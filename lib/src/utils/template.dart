import 'package:mustache_template/mustache.dart';

class AckTemplate {
  final Template _template;
  final Map<String, dynamic>? _variables;

  AckTemplate(
    String source, {
    Map<String, dynamic>? variables,
    bool htmlEscapeValues = false,
  })  : _template = Template(
          _preprocessTemplate(source),
          htmlEscapeValues: htmlEscapeValues,
          lenient: true,
        ),
        _variables = _addLengthProperties(variables);

  Object _processValues(
    Object? variables,
    String Function(String variable) renderer,
  ) {
    if (variables is Map) {
      final result = <String, dynamic>{};
      variables.forEach((key, value) {
        result[key] = _processValue(value, renderer);
      });

      return result;
    } else if (variables is Iterable) {
      return variables.map((item) => _processValue(item, renderer)).toList();
    }

    return _processValue(variables, renderer);
  }

  Object _processValue(
    Object? value,
    String Function(String variable) renderer,
  ) {
    if (value is String) {
      return renderer(value);
    } else if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((key, val) {
        result[key] = _processValue(val, renderer);
      });

      return result;
    } else if (value is Iterable) {
      // Recursively process lists
      final processedList =
          value.map((item) => _processValue(item, renderer)).toList();

      return processedList;
    } else if (value is Function) {
      // Handle lambdas by wrapping them
      return (Object? lambdaArg) {
        var result = value(lambdaArg);
        if (result is String) {
          return renderer(result);
        }

        return result;
      };
    } // For non-string primitives (numbers, booleans, etc.)

    // Convert to string and apply renderer
    return renderer(value?.toString() ?? '');
  }

  String render({String Function(String variable)? renderer}) {
    return _template.renderString(
      renderer == null ? _variables : _processValues(_variables, renderer),
    );
  }
}

Map<String, dynamic>? _addLengthProperties(Map<String, dynamic>? values) {
  if (values == null) return null;

  final result = Map<String, dynamic>.from(values);

  // Process each entry in the map
  values.forEach((key, value) {
    // Add length property for strings
    if (value is String) {
      result['${key}__length'] = value.length;
    }
    // Add length property for lists/iterables
    else if (value is Iterable) {
      result['${key}__length'] = value.length;

      // Also process items in lists if they are maps
      if (value is List) {
        final processedList = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _addLengthProperties(item);
          }

          return item;
        }).toList();
        result[key] = processedList;
      }
    }
    // Add length property for maps
    else if (value is Map) {
      result['${key}__length'] = value.length;

      // Recursively process nested maps
      if (value is Map<String, dynamic>) {
        result[key] = _addLengthProperties(value);
      }
    }
  });

  return result;
}

String _preprocessTemplate(String source) {
  // Regular expression to find {{variable.length}} patterns
  // This handles spaces around the variable name and between '.' and 'length'
  final lengthPattern = RegExp(r'{{([^{}]+)\s*\.\s*length\s*}}');

  // Replace all occurrences with {{variable___length}}
  final replacedSource = source.replaceAllMapped(lengthPattern, (match) {
    final variableName = match.group(1)?.trim();

    if (variableName == null) {
      throw Exception('Invalid template: $source');
    }

    return '{{ ${variableName}__length }}';
  });

  return replacedSource;
}
