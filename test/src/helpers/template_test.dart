import 'package:ack/src/helpers/template.dart';
import 'package:test/test.dart';

void main() {
  group('Template', () {
    // ---------------------------------------------------------------
    // Basic variable interpolation tests
    // ---------------------------------------------------------------
    test('Basic variable interpolation', () {
      final template = Template('Hello, {{ name }}!');
      expect(
        template.render(
          overrideData: {'name': 'World'},
        ),
        'Hello, World!',
      );
    });

    test('Multiple variables', () {
      final template = Template('{{ greeting }}, {{ name }}!');
      expect(
        template.render(
          overrideData: {'greeting': 'Hello', 'name': 'World'},
        ),
        'Hello, World!',
      );
    });

    test('Non-string values', () {
      final template = Template(
        'Number: {{ number }}, Boolean: {{ flag }}, Null: {{ missing }}',
      );
      expect(
        template.render(
          overrideData: {'number': 42, 'flag': true, 'missing': null},
        ),
        'Number: 42, Boolean: true, Null: N/A',
      );
    });

    // ---------------------------------------------------------------
    // Nested property access tests
    // ---------------------------------------------------------------
    test('Nested property access', () {
      final template = Template('{{ user.profile.name }}');
      expect(
        template.render(
          overrideData: {
            'user': {
              'profile': {'name': 'John Doe'}
            }
          },
        ),
        'John Doe',
      );
    });

    test('Deep nested property access', () {
      final template = Template('{{ a.b.c.d.e }}');
      expect(
        template.render(
          overrideData: {
            'a': {
              'b': {
                'c': {
                  'd': {'e': 'Deep value'}
                }
              }
            }
          },
        ),
        'Deep value',
      );
    });

    test('Missing nested properties', () {
      final template = Template('{{ a.b.c.missing }}');
      expect(
        template.render(
          overrideData: {
            'a': {
              'b': {'c': {}}
            }
          },
        ),
        '{}',
      );
    });

    test('Null in path', () {
      final template = Template('{{ a.b.c }}');
      expect(
        template.render(
          overrideData: {
            'a': {'b': null}
          },
        ),
        'N/A',
      );
    });

    // ---------------------------------------------------------------
    // List iteration tests
    // ---------------------------------------------------------------
    test('Basic list iteration', () {
      final template = Template('Items: {{#each items}}{{ @this }}{{/each}}');
      expect(
        template.render(
          overrideData: {
            'items': ['apple', 'banana', 'cherry']
          },
        ),
        'Items: applebananacherry',
      );
    });

    test('List iteration with index', () {
      final template = Template(
        'Items: {{#each items}}[{{@index}}] {{ @this }}, {{/each}}',
      );
      expect(
        template.render(
          overrideData: {
            'items': ['apple', 'banana', 'cherry']
          },
        ),
        'Items: [0] apple, [1] banana, [2] cherry, ',
      );
    });

    test('List of maps', () {
      final template = Template(
        'Users: {{#each users}}{{ name }} ({{ email }}), {{/each}}',
      );
      expect(
        template.render(
          overrideData: {
            'users': [
              {'name': 'John', 'email': 'john@example.com'},
              {'name': 'Jane', 'email': 'jane@example.com'}
            ]
          },
        ),
        'Users: John (john@example.com), Jane (jane@example.com), ',
      );
    });

    test('Empty list', () {
      final template = Template('Items: {{#each items}}{{ @this }}{{/each}}');
      expect(
        template.render(
          overrideData: {'items': []},
        ),
        'Items: ',
      );
    });

    // ---------------------------------------------------------------
    // Map iteration tests
    // ---------------------------------------------------------------
    test('Basic map iteration', () {
      final template = Template(
        'Settings: {{#each settings}}{{ @this.key }}: {{ @this.value }}, {{/each}}',
      );
      expect(
        template.render(
          overrideData: {
            'settings': {'theme': 'dark', 'notifications': true}
          },
        ),
        'Settings: theme: dark, notifications: true, ',
      );
    });

    test('Map with nested objects', () {
      final template = Template(
        'Settings: {{#each settings}}{{ @this.key }}: {{ @this.value.name }}, {{/each}}',
      );
      expect(
        template.render(
          overrideData: {
            'settings': {
              'profile': {'name': 'John'},
              'theme': {'name': 'Dark Mode'}
            }
          },
        ),
        'Settings: profile: John, theme: Dark Mode, ',
      );
    });

    test('Empty map', () {
      final template = Template(
        'Settings: {{#each settings}}{{ @this.key }}: {{ @this.value }}, {{/each}}',
      );
      expect(
        template.render(
          overrideData: {'settings': {}},
        ),
        'Settings: ',
      );
    });

    // ---------------------------------------------------------------
    // Nested loop tests
    // ---------------------------------------------------------------
    test('Nested list loops', () {
      final template = Template('''
Categories:
{{#each categories}}
- {{ name }}:
  {{#each items}}
    * {{ @this }}
  {{/each}}
{{/each}}
''');
      expect(
        template.render(
          overrideData: {
            'categories': [
              {
                'name': 'Fruits',
                'items': ['Apple', 'Banana']
              },
              {
                'name': 'Vegetables',
                'items': ['Carrot', 'Potato']
              },
            ]
          },
        ),
        '''
Categories:
- Fruits:
    * Apple
    * Banana
- Vegetables:
    * Carrot
    * Potato
''',
      );
    }, skip: 'TODO: Fix nested list loops');

    test('List loop inside map loop', () {
      final template = Template('''
{{#each data}}
Section: {{ @this.key }}
{{#each @this.value}}
  - {{ @this }}
{{/each}}

{{/each}}
''');
      expect(
        template.render(
          overrideData: {
            'data': {
              'Fruits': ['Apple', 'Banana'],
              'Vegetables': ['Carrot', 'Potato']
            }
          },
        ),
        '''
Section: Fruits
  - Apple
  - Banana

Section: Vegetables
  - Carrot
  - Potato

''',
      );
    });

    test('Map loop inside list loop', () {
      final template = Template('''
Users:
{{#each users}}
- {{ name }}:
  {{#each settings}}
    * {{ @this.key }}: {{ @this.value }}
  {{/each}}

{{/each}}
''');
      expect(
        template.render(
          overrideData: {
            'users': [
              {
                'name': 'John',
                'settings': {'theme': 'dark', 'notifications': true}
              },
              {
                'name': 'Jane',
                'settings': {'theme': 'light', 'notifications': false}
              }
            ]
          },
        ),
        '''
Users:
- John:
    * theme: dark
    * notifications: true
  
- Jane:
    * theme: light
    * notifications: false
  
''',
      );
    }, skip: 'TODO: Fix map loop inside list loop');

    // ---------------------------------------------------------------
    // Complex nested data
    // ---------------------------------------------------------------
    test('Deeply nested complex data structure', () {
      final template = Template('''
Organization: {{ org.name }}
Departments:
{{#each org.departments}}
- {{ name }} ({{ employees.length }} employees)
  Team Leads:
  {{#each teams}}
    * {{ @key }}: {{ lead.name }} ({{ lead.title }})
    Members:
    {{#each members}}
      - {{ name }} ({{ role }})
    {{/each}}
  {{/each}}
{{/each}}
''');

      expect(
        template.render(
          overrideData: {
            'org': {
              'name': 'Acme Inc',
              'departments': [
                {
                  'name': 'Engineering',
                  'employees': ['Alice', 'Bob', 'Charlie', 'Dave', 'Eve'],
                  'teams': {
                    'Frontend': {
                      'lead': {'name': 'Alice', 'title': 'Senior Developer'},
                      'members': [
                        {'name': 'Bob', 'role': 'UI Developer'},
                        {'name': 'Charlie', 'role': 'UX Designer'}
                      ]
                    },
                    'Backend': {
                      'lead': {'name': 'Dave', 'title': 'Tech Lead'},
                      'members': [
                        {'name': 'Eve', 'role': 'API Developer'}
                      ]
                    }
                  }
                },
                {
                  'name': 'Marketing',
                  'employees': ['Frank', 'Grace', 'Heidi'],
                  'teams': {
                    'Digital': {
                      'lead': {'name': 'Frank', 'title': 'Marketing Director'},
                      'members': [
                        {'name': 'Grace', 'role': 'Social Media Specialist'},
                        {'name': 'Heidi', 'role': 'Content Writer'}
                      ]
                    }
                  }
                }
              ]
            }
          },
        ),
        '''
Organization: Acme Inc
Departments:
- Engineering (5 employees)
  Team Leads:
    * Frontend: Alice (Senior Developer)
    Members:
      - Bob (UI Developer)
      - Charlie (UX Designer)
    
    * Backend: Dave (Tech Lead)
    Members:
      - Eve (API Developer)
- Marketing (3 employees)
  Team Leads:
    * Digital: Frank (Marketing Director)
    Members:
      - Grace (Social Media Specialist)
      - Heidi (Content Writer)
''',
      );
    }, skip: 'TODO: Fix deeply nested complex data structure');

    // ---------------------------------------------------------------
    // Edge cases
    // ---------------------------------------------------------------

    /// Demonstrates that null items become "N/A" by default.
    test('Edge case - null in list', () {
      final template = Template('Items: {{#each items}}{{ @this }}, {{/each}}');
      expect(
        template.render(
          overrideData: {
            'items': ['apple', null, 'cherry']
          },
        ),
        'Items: apple, N/A, cherry, ',
      );
    });

    /// Demonstrates that parent data is accessible if the rendering code
    /// merges parent context. If your Template code *doesn't* currently merge
    /// parent data, this test will produce 'N/A' instead of 'Inventory'.
    test('Edge case - access outer context in loop', () {
      final template = Template(
        '{{#each items}}{{ @this }} (from {{ source }}), {{/each}}',
      );
      expect(
        template.render(
          overrideData: {
            'source': 'Inventory',
            'items': ['Apple', 'Banana', 'Cherry']
          },
        ),
        // If parent context is merged, we get 'Inventory'
        'Apple (from Inventory), Banana (from Inventory), Cherry (from Inventory), ',
      );
    }, skip: 'TODO: Fix access outer context in loop');

    test('Edge case - numeric map keys', () {
      final template = Template(
        'Scores: {{#each scores}}Student {{@this.key}}: {{@this.value}}, {{/each}}',
      );
      expect(
        template.render(
          overrideData: {
            'scores': {'101': 85, '102': 92, '103': 78}
          },
        ),
        'Scores: Student 101: 85, Student 102: 92, Student 103: 78, ',
      );
    });

    test('Mixed content with variables and loops', () {
      final template = Template('''
Report for {{ company }}
Date: {{ date }}

Employees:
{{#each employees}}
- {{ name }}: {{ position }}
  Skills:
  {{#each skills}}
    * {{ @this }}
  {{/each}}
  
{{/each}}

Department Budgets:
{{#each budgets}}
- {{ @this.key }}: \${{ @this.value }}
{{/each}}

Generated by {{ generator }}
''');

      expect(
        template.render(
          overrideData: {
            'company': 'Acme Inc',
            'date': '2025-03-06',
            'employees': [
              {
                'name': 'John Doe',
                'position': 'Developer',
                'skills': ['JavaScript', 'Python', 'Dart']
              },
              {
                'name': 'Jane Smith',
                'position': 'Designer',
                'skills': ['UI/UX', 'Illustration', 'Prototyping']
              }
            ],
            'budgets': {
              'Engineering': 500000,
              'Marketing': 300000,
              'Operations': 200000
            },
            'generator': 'Template Engine'
          },
        ),
        '''
Report for Acme Inc
Date: 2025-03-06

Employees:
- John Doe: Developer
  Skills:
    * JavaScript
    * Python
    * Dart
  
- Jane Smith: Designer
  Skills:
    * UI/UX
    * Illustration
    * Prototyping
  

Department Budgets:
- Engineering: \$500000
- Marketing: \$300000
- Operations: \$200000

Generated by Template Engine
''',
      );
    }, skip: 'TODO: Fix mixed content with variables and loops');
  });

  group('Template Conditional Tests', () {
    test('Basic if condition - true condition', () {
      final template = Template(
        '{{#if isVisible}}Content is visible{{/if}}',
        data: {'isVisible': true},
      );

      expect(template.render(), 'Content is visible');
    });

    test('Basic if condition - false condition', () {
      final template = Template(
        '{{#if isVisible}}Content is visible{{/if}}',
        data: {'isVisible': false},
      );

      expect(template.render(), '');
    });

    test('If-else condition - true condition', () {
      final template = Template(
        '{{#if isVisible}}Content is visible{{else}}Content is hidden{{/if}}',
        data: {'isVisible': true},
      );

      expect(template.render(), 'Content is visible');
    });

    test('If-else condition - false condition', () {
      final template = Template(
        '{{#if isVisible}}Content is visible{{else}}Content is hidden{{/if}}',
        data: {'isVisible': false},
      );

      expect(template.render(), 'Content is hidden');
    });

    test('Nested if conditions - both true', () {
      final template = Template(
        '''
{{#if outer}}
  Outer content
  {{#if inner}}
    Inner content
  {{/if}}
{{/if}}''',
        data: {'outer': true, 'inner': true},
      );

      expect(template.render().replaceAll(RegExp(r'\s+'), ' ').trim(),
          'Outer content Inner content');
    });

    test('Nested if conditions - outer true, inner false', () {
      final template = Template(
        '''
{{#if outer}}
  Outer content
  {{#if inner}}
    Inner content
  {{/if}}
{{/if}}''',
        data: {'outer': true, 'inner': false},
      );

      expect(template.render().replaceAll(RegExp(r'\s+'), ' ').trim(),
          'Outer content');
    });

    test('Nested if-else conditions', () {
      final template = Template(
        '''
{{#if outer}}
  {{#if inner}}
    Both conditions true
  {{else}}
    Only outer true
  {{/if}}
{{else}}
  Outer condition false
{{/if}}''',
        data: {'outer': true, 'inner': false},
      );

      expect(template.render().replaceAll(RegExp(r'\s+'), ' ').trim(),
          'Only outer true');
    });

    test('If condition with nested properties', () {
      final template = Template(
        '{{#if user.profile.isActive}}User is active{{else}}User is inactive{{/if}}',
        data: {
          'user': {
            'profile': {'isActive': true}
          }
        },
      );

      expect(template.render(), 'User is active');
    });

    test('Multiple independent conditionals', () {
      final template = Template(
        '''
{{#if condA}}A is true{{else}}A is false{{/if}}
{{#if condB}}B is true{{else}}B is false{{/if}}''',
        data: {'condA': true, 'condB': false},
      );

      expect(template.render(), 'A is true\nB is false');
    });

    group('Truthy/Falsy Values Tests', () {
      test('Numeric truthy/falsy values', () {
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': 1}).render(),
            'Truthy');
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': 0}).render(),
            'Falsy');
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': -1}).render(),
            'Truthy');
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': 0.0}).render(),
            'Falsy');
      });

      test('String truthy/falsy values', () {
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': 'hello'}).render(),
            'Truthy');
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': ''}).render(),
            'Falsy');
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': '0'}).render(),
            'Truthy'); // Non-empty string
      });

      test('Collection truthy/falsy values', () {
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}', data: {
              'value': [1, 2, 3]
            }).render(),
            'Truthy');
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': []}).render(),
            'Falsy');
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}', data: {
              'value': {'key': 'value'}
            }).render(),
            'Truthy');
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': {}}).render(),
            'Falsy');
      });

      test('Null values', () {
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': null}).render(),
            'Falsy');
        expect(
            Template('{{#if missingKey}}Truthy{{else}}Falsy{{/if}}', data: {})
                .render(),
            'Falsy');
      });

      test('Other object types', () {
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': Duration.zero}).render(),
            'Falsy');
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': Duration(seconds: 1)}).render(),
            'Truthy');
        expect(
            Template('{{#if value}}Truthy{{else}}Falsy{{/if}}',
                data: {'value': Exception('test')}).render(),
            'Truthy');
      });
    });

    group('Combined with Loops', () {
      test('If inside loop', () {
        final template = Template(
          '''
{{#each items}}
  {{#if active}}
    Item {{index}}: {{name}} (active)
  {{else}}
    Item {{index}}: {{name}} (inactive)
  {{/if}}
{{/each}}''',
          data: {
            'items': [
              {'name': 'Item 1', 'active': true},
              {'name': 'Item 2', 'active': false},
              {'name': 'Item 3', 'active': true},
            ]
          },
        );

        final expected = '''
  Item 0: Item 1 (active)
  Item 1: Item 2 (inactive)
  Item 2: Item 3 (active)
''';
        expect(template.render(), expected);
      });

      test('Loop inside if', () {
        final template = Template(
          '''
{{#if hasItems}}
  Items:
  {{#each items}}
    - {{name}}
  {{/each}}
{{else}}
  No items available
{{/if}}''',
          data: {
            'hasItems': true,
            'items': [
              {'name': 'Item 1'},
              {'name': 'Item 2'},
            ]
          },
        );

        final expected = '''
  Items:
    - Item 1
    - Item 2
''';
        expect(template.render(), expected);
      });

      test('Condition based on loop properties', () {
        final template = Template(
          '''
{{#if items.length}}
There are {{items.length}} items.
{{else}}
No items found.
{{/if}}''',
          data: {
            'items': [1, 2, 3],
          },
        );

        expect(template.render(), 'There are 3 items.');
      });
    });

    group('Edge Cases and Error Handling', () {
      test('Unclosed if block', () {
        final template = Template(
          '{{#if condition}}This is unclosed',
          data: {'condition': true},
        );

        // Should leave the template unchanged since it can't find the closing tag
        expect(template.render(), '{{#if condition}}This is unclosed');
      });

      test('Unmatched else block', () {
        final template = Template(
          '{{else}}This is unmatched',
          data: {},
        );

        // Should leave the template unchanged
        expect(template.render(), '{{else}}This is unmatched');
      });

      test('Empty if block', () {
        final template = Template(
          '{{#if condition}}{{/if}}',
          data: {'condition': true},
        );

        expect(template.render(), '');
      });

      test('Complex nested structure', () {
        final template = Template(
          '''
{{#if a}}
  A is true
  {{#if b}}
    B is also true
    {{#if c}}
      C is also true
    {{else}}
      C is false
      {{#if d}}
        But D is true
      {{/if}}
    {{/if}}
  {{else}}
    B is false
  {{/if}}
{{else}}
  A is false
{{/if}}''',
          data: {'a': true, 'b': true, 'c': false, 'd': true},
        );

        final expected = '''
  A is true
  B is also true
    C is false
      But D is true
''';
        expect(template.render(), expected);
      });

      test('Multiples of the same variable', () {
        final template = Template(
          '{{#if value}}{{value}} is truthy{{else}}{{value}} is falsy{{/if}}',
          data: {'value': 42},
        );

        expect(template.render(), '42 is truthy');
      });
    });

    test('Real-world example - Error message with conditional', () {
      final discriminatorKey = 'type';
      final template = Template(
        '''
{{#if extra.missing_key}}
Missing discriminator field "$discriminatorKey" in object.
{{else}}
Invalid discriminator value: "{{extra.discriminator_value}}".
Valid values are: {{extra.valid_values}}.
{{/if}}
''',
        data: {
          'extra': {
            'missing_key': false,
            'discriminator_value': 'unknown',
            'valid_values': 'A, B, C'
          },
          'discriminatorKey': 'type'
        },
      );

      final expected = '''
Invalid discriminator value: "unknown".
Valid values are: A, B, C.
''';
      expect(template.render(), expected);
    });
  });
}
