import os
import glob
import re

files = glob.glob('src/**/*.ts', recursive=True)
for file in files:
    with open(file, 'r') as f:
        content = f.read()

    uses_timestamp = 'Timestamp' in content
    uses_fieldvalue = 'FieldValue' in content

    if uses_timestamp or uses_fieldvalue:
        imports = []
        if uses_timestamp: imports.append('Timestamp')
        if uses_fieldvalue: imports.append('FieldValue')

        if 'from "firebase-admin/firestore"' in content:
            # Add to existing import
            def repl(m):
                existing = [x.strip() for x in m.group(1).split(',')]
                for i in imports:
                    if i not in existing:
                        existing.append(i)
                return f'import {{ {", ".join(existing)} }} from "firebase-admin/firestore";'
            
            content = re.sub(r'import\s*\{\s*([^}]+)\s*\}\s*from\s*"firebase-admin/firestore";', repl, content)
        else:
            # Add new import at top
            content = f'import {{ {", ".join(imports)} }} from "firebase-admin/firestore";\n' + content

    with open(file, 'w') as f:
        f.write(content)
