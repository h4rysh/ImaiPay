const fs = require('fs');
const glob = require('glob');

const files = glob.sync('src/**/*.ts');
for (const file of files) {
  let content = fs.readFileSync(file, 'utf8');
  
  const usesTimestamp = content.includes('Timestamp');
  const usesFieldValue = content.includes('FieldValue');
  
  if (usesTimestamp || usesFieldValue) {
    const imports = [];
    if (usesTimestamp) imports.push('Timestamp');
    if (usesFieldValue) imports.push('FieldValue');
    
    // Check if there is already an import from "firebase-admin/firestore"
    if (content.includes('from "firebase-admin/firestore"')) {
      // Just replace it. This is a bit hacky but we know wallet.ts has `import { Transaction } from "firebase-admin/firestore";`
      content = content.replace(/import\s*{([^}]+)}\s*from\s*"firebase-admin\/firestore";/, (match, p1) => {
         const existing = p1.split(',').map(s => s.trim()).filter(Boolean);
         imports.forEach(i => { if (!existing.includes(i)) existing.push(i); });
         return `import { ${existing.join(', ')} } from "firebase-admin/firestore";`;
      });
    } else {
      content = `import { ${imports.join(', ')} } from "firebase-admin/firestore";\n` + content;
    }
    
    fs.writeFileSync(file, content);
  }
}
