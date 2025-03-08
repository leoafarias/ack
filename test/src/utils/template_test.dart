import 'package:ack/src/utils/template.dart';
import 'package:mustache_template/mustache.dart';
import 'package:test/test.dart';

void main() {
  group('AckTemplate', () {
    // Basic rendering tests
    group('Basic rendering', () {
      test('renders simple template with string values', () {
        final template =
            AckTemplate('Hello {{name}}!', variables: {'name': 'World'});
        final result = template.render(renderer: (v) => v);
        expect(result, 'Hello World!');
      });

      test('applies renderer to string values', () {
        final template =
            AckTemplate('Hello {{name}}!', variables: {'name': 'World'});
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, 'Hello <value>World</value>!');
      });

      test('renders with multiple values', () {
        final template = AckTemplate('{{greeting}} {{name}}!',
            variables: {'greeting': 'Hello', 'name': 'World'});
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '<value>Hello</value> <value>World</value>!');
      });
    });

    // Nested maps tests
    group('Nested maps', () {
      test('renders values from nested maps', () {
        final template = AckTemplate(
            '{{person.name}} is {{person.age}} years old',
            variables: {
              'person': {'name': 'John', 'age': 30}
            });
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '<value>John</value> is <value>30</value> years old');
      });

      test('handles deeply nested maps', () {
        final template = AckTemplate('{{a.b.c.d}}', variables: {
          'a': {
            'b': {
              'c': {'d': 'deep value'}
            }
          }
        });
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '<value>deep value</value>');
      });
    });

    // List handling tests
    group('Lists', () {
      test('renders lists with sections', () {
        final template =
            AckTemplate('{{#items}}{{name}},{{/items}}', variables: {
          'items': [
            {'name': 'a'},
            {'name': 'b'},
            {'name': 'c'}
          ]
        });
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '<value>a</value>,<value>b</value>,<value>c</value>,');
      });

      test('handles empty lists correctly', () {
        final template = AckTemplate(
            '{{#items}}{{name}}{{/items}}{{^items}}No items{{/items}}',
            variables: {'items': []});
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, 'No items');
      });
    });

    // Data type tests
    group('Data types', () {
      test('handles numeric values', () {
        final template = AckTemplate('{{count}}', variables: {'count': 42});
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '<value>42</value>');
      });

      test('handles boolean values', () {
        final template = AckTemplate('{{flag}}', variables: {'flag': true});
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '<value>true</value>');
      });

      test('handles null values', () {
        final template =
            AckTemplate('{{nullValue}}', variables: {'nullValue': null});
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '<value></value>');
      });
    });

    // Lambda function tests
    group('Lambda functions', () {
      test('processes simple lambda result', () {
        lambda(_) => 'Lambda result';
        final template = AckTemplate('{{#lambda}}{{/lambda}}',
            variables: {'lambda': lambda});
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '<value>Lambda result</value>');
      });

      test('processes section lambda with content', () {
        lambda(LambdaContext ctx) => 'Before ${ctx.renderString()} After';
        final template = AckTemplate('{{#format}}{{value}}{{/format}}',
            variables: {'format': lambda, 'value': 'content'});
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '<value>Before <value>content</value> After</value>');
      });
    });

    // HTML escaping tests
    group('HTML escaping', () {
      test('does not escape HTML when htmlEscapeValues is false', () {
        final template = AckTemplate('{{htmlContent}}',
            variables: {'htmlContent': '<script>alert("XSS")</script>'},
            htmlEscapeValues: false);
        final result = template.render(renderer: (v) => v);
        expect(result, '<script>alert("XSS")</script>');
      });

      test('renders correctly with HTML in wrapper tags', () {
        final template = AckTemplate('{{value}}',
            variables: {'value': 'test'}, htmlEscapeValues: false);
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '<value>test</value>');
      });
    });

    // Edge cases
    group('Edge cases', () {
      test('handles empty values map', () {
        final template = AckTemplate('Hello {{name}}!', variables: {});
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, 'Hello !');
      });

      test('handles null values map', () {
        final template = AckTemplate('Static content', variables: null);
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, 'Static content');
      });

      test('handles empty template', () {
        final template = AckTemplate('', variables: {'key': 'value'});
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '');
      });

      test('handles complex renderer with special characters', () {
        final template = AckTemplate('{{value}}', variables: {'value': 'test'});
        final result = template.render(
            renderer: (v) => '<xml:value attr="special">$v</xml:value>');
        expect(result, '<xml:value attr="special">test</xml:value>');
      });
    });

    // Custom renderer tests
    group('Custom renderers', () {
      test('applies uppercase renderer', () {
        final template = AckTemplate('{{value}}', variables: {'value': 'test'});
        final result = template.render(renderer: (v) => v.toUpperCase());
        expect(result, 'TEST');
      });

      test('applies conditional renderer', () {
        final template = AckTemplate('{{value1}} {{value2}}',
            variables: {'value1': '', 'value2': 'present'});
        final result =
            template.render(renderer: (v) => v.isEmpty ? '[EMPTY]' : v);
        expect(result, '[EMPTY] present');
      });

      test('applies complex formatting', () {
        final template = AckTemplate('{{count}}', variables: {'count': 1234});
        final result = template.render(
            renderer: (v) => v == '1234' ? v.split('').join(',') : v);
        expect(result, '1,2,3,4');
      });
    });

    // HTML escaping tests - expanded with more cases
    group('HTML escaping', () {
      test('escapes HTML by default when htmlEscapeValues is true', () {
        final template = AckTemplate('{{htmlContent}}',
            variables: {'htmlContent': '<script>alert("XSS")</script>'},
            // Default is true, but explicitly setting for clarity
            htmlEscapeValues: true);
        final result = template.render(renderer: (v) => v);
        expect(
            result, "&lt;script&gt;alert(&quot;XSS&quot;)&lt;&#x2F;script&gt;");
      });

      test('escapes HTML tags in renderer with htmlEscapeValues true', () {
        final template = AckTemplate('{{plainText}}',
            variables: {'plainText': 'normal text'}, htmlEscapeValues: true);
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, "&lt;value&gt;normal text&lt;&#x2F;value&gt;");
      });

      test('renders error messages correctly with htmlEscapeValues false', () {
        final template = AckTemplate(
            'Invalid type of {{actualType}}, expected {{expectedType}}',
            variables: {'actualType': 'String', 'expectedType': 'int'},
            htmlEscapeValues: false);
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result,
            'Invalid type of <value>String</value>, expected <value>int</value>');
      });

      test(
          'handles HTML content in both value and renderer with htmlEscapeValues false',
          () {
        final template = AckTemplate('{{content}}',
            variables: {'content': '<b>Bold text</b>'},
            htmlEscapeValues: false);
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '<value><b>Bold text</b></value>');
      });

      test('preserves nested HTML with htmlEscapeValues false', () {
        final template = AckTemplate('{{#user}}{{name}}{{/user}}',
            variables: {
              'user': {'name': '<Admin>'}
            },
            htmlEscapeValues: false);
        final result = template.render(renderer: (v) => '<value>$v</value>');
        expect(result, '<value><Admin></value>');
      });

      test('renderer with complex HTML structure - unescaped', () {
        final template = AckTemplate('{{value}}',
            variables: {'value': 'test'}, htmlEscapeValues: false);
        final result = template.render(
            renderer: (v) =>
                '<span class="highlight" data-value="$v">$v</span>');
        expect(result, '<span class="highlight" data-value="test">test</span>');
      });

      test('renderer with XML-style tags - unescaped', () {
        final template = AckTemplate('{{value}}',
            variables: {'value': 'test'}, htmlEscapeValues: false);
        final result = template.render(
            renderer: (v) => '<xml:value attr="special">$v</xml:value>');
        expect(result, '<xml:value attr="special">test</xml:value>');
      });
    });

    // Error message tests specifically for your use case
    group('Error message rendering', () {
      test('renders type error message with htmlEscapeValues false (SOLUTION)',
          () {
        final template = AckTemplate(
            'Invalid type of {{actualType}}, expected {{expectedType}}',
            variables: {'actualType': 'String', 'expectedType': 'int'},
            htmlEscapeValues: false);
        final result = template.render(renderer: (v) => '<value>$v</value>');
        // This shows the solution - HTML is not escaped
        expect(result,
            'Invalid type of <value>String</value>, expected <value>int</value>');
      });
    });
  });
}
