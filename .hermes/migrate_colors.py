"""
Migrate AppColors.xxx → context.colors.xxx in Flutter widget files.

Safe, error-tolerant approach.
"""

import re
import os
import traceback

ROOT = r'D:\Hermes\zhangyuzhixue_app_v2'

TARGET_DIRS = [
    r'flutter_app\lib\pages',
    r'flutter_app\lib\widgets',
    r'packages\shared\lib\widgets',
    r'teacher_app\lib\pages',
    r'teacher_app\lib\widgets',
]

EXTRA_FILES = [
    r'flutter_app\lib\main.dart',
]


def find_target_files():
    files = set()
    for d in TARGET_DIRS:
        full_dir = os.path.join(ROOT, d)
        if os.path.isdir(full_dir):
            for root, _, filenames in os.walk(full_dir):
                for fn in filenames:
                    if fn.endswith('.dart'):
                        files.add(os.path.join(root, fn))
    for f in EXTRA_FILES:
        p = os.path.join(ROOT, f)
        if os.path.exists(p):
            files.add(p)
    return sorted(files)


def remove_const_from_colors_lines(text):
    """
    Remove `const ` keyword from any line that references `colors.`.
    Also handles multi-line const constructors.
    """
    lines = text.split('\n')
    new_lines = list(lines)
    changed = False

    # Phase 1: Remove inline `const` on lines that directly contain colors.
    for i, line in enumerate(lines):
        if 'colors.' in line and 'const ' in line:
            new_line = re.sub(r'\bconst\s+(?=[A-Z]\w*[\s.\(])', '', line)
            if new_line != line:
                new_lines[i] = new_line
                changed = True

    # Phase 2: Multi-line const constructors
    i = 0
    while i < len(lines):
        line = lines[i]
        m = re.match(r'^(\s*)const\s+([A-Z]\w*)\s*\(', line)
        if m:
            open_count = line.count('(') - line.count(')')
            if open_count > 0:
                j = i + 1
                bal = open_count
                has_colors_inside = 'colors.' in line
                while j < len(lines) and bal > 0:
                    bal += lines[j].count('(') - lines[j].count(')')
                    if 'colors.' in lines[j]:
                        has_colors_inside = True
                    j += 1
                if has_colors_inside:
                    new_lines[i] = line.replace('const ', '', 1)
                    changed = True
        i += 1

    if changed:
        return '\n'.join(new_lines)
    return text


def find_block_end(lines, start_line, open_char='{', close_char='}'):
    """Find the end line of a brace-block starting at start_line."""
    bal = 0
    bal += lines[start_line].count(open_char) - lines[start_line].count(close_char)
    if bal <= 0:
        return start_line + 1
    j = start_line + 1
    while j < len(lines) and bal > 0:
        bal += lines[j].count(open_char) - lines[j].count(close_char)
        j += 1
    return j


def add_colors_to_build_methods(text):
    """
    Find build methods and builder callbacks that reference colors,
    and add `final colors = context.colors;` at their start.
    """
    lines = text.split('\n')
    new_lines = list(lines)
    changed = False

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # ---- Pattern A: Widget build(BuildContext context) { ... } ----
        m = re.match(
            r'^(\s*)Widget\s+build\s*\(\s*(?:covariant\s+)?BuildContext\s+(\w+)\s*\)\s*\{',
            stripped
        )
        if m:
            indent = m.group(1)
            end = find_block_end(lines, i)
            func_lines = lines[i:end]
            if any('colors.' in l for l in func_lines):
                brace_pos = line.index('{')
                new_lines[i] = (line[:brace_pos + 1] + '\n' +
                               indent + '    final colors = context.colors;' +
                               line[brace_pos + 1:])
                changed = True
                i = end
                continue

        # ---- Pattern B: Widget build(BuildContext context) => expr; ----
        m = re.match(
            r'^(\s*)Widget\s+build\s*\(\s*(?:covariant\s+)?BuildContext\s+\w+\s*\)\s*=>\s*(.+);\s*$',
            stripped
        )
        if m:
            indent = m.group(1)
            expr = m.group(2).strip()
            if 'colors.' in expr:
                new_lines[i] = (
                    f'{indent}Widget build(BuildContext context) {{\n'
                    f'{indent}    final colors = context.colors;\n'
                    f'{indent}    return {expr};\n'
                    f'{indent}  }}'
                )
                changed = True
                i += 1
                continue

        # ---- Pattern C: Named arrow callbacks like `builder: (context) => Widget(...)` ----
        m = re.match(
            r'^(\s*)(\w+\s*:\s*)?\(\s*(?:BuildContext\s+)?(\w+)\s*\)\s*=>\s*(.+),?\s*$',
            stripped
        )
        if m and 'colors.' in stripped:
            prefix_indent = m.group(1)
            named_param = m.group(2) or ''
            ctx_name = m.group(3)
            expr = m.group(4).rstrip(',').strip()
            new_lines[i] = (
                f'{prefix_indent}{named_param}({ctx_name}) {{\n'
                f'{prefix_indent}      final colors = context.colors;\n'
                f'{prefix_indent}      return {expr};\n'
                f'{prefix_indent}    }},'
            )
            changed = True
            i += 1
            continue

        # ---- Pattern D: Builder callbacks (context) { ... } ----
        # Must NOT be `Widget build` (already handled above)
        if '(context)' in stripped or '(ctx)' in stripped:
            if 'Widget build' in stripped:
                i += 1
                continue
            # Check various parenthesized parameter patterns
            # (context) {  or  (ctx) {
            for ctx_name in ['context', 'ctx']:
                pattern = r'\(\s*(?:BuildContext\s+)?' + re.escape(ctx_name) + r'\s*\)\s*\{'
                m2 = re.search(pattern, stripped)
                if m2:
                    # Find the block end
                    end = find_block_end(lines, i)
                    block_lines = lines[i:end]
                    if any('colors.' in l for l in block_lines):
                        if '{' in line:
                            brace_pos = line.index('{')
                            new_lines[i] = (line[:brace_pos + 1] + '\n' +
                                           '      final colors = context.colors;' +
                                           line[brace_pos + 1:])
                            changed = True
                            i = end
                            break
                    else:
                        break
            # If no pattern matched, just continue

        i += 1

    if changed:
        return '\n'.join(new_lines)
    return text


def pad_lines(text):
    lines = text.split('\n')
    result = []
    for l in lines:
        if l.strip():
            result.append(l)
        elif result and result[-1] != '':
            result.append('')
    while result and result[-1] == '':
        result.pop()
    return '\n'.join(result)


def process_file(filepath):
    rel = os.path.relpath(filepath, ROOT)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    if 'AppColors.' not in content:
        return False
    
    # Phase 1: Replace AppColors. → colors.
    content = content.replace('AppColors.', 'colors.')
    
    # Phase 2: Remove const from lines that now reference colors.
    content = remove_const_from_colors_lines(content)
    
    # Phase 3: Add final colors = context.colors; to build methods and callbacks
    content = add_colors_to_build_methods(content)
    
    # Phase 4: Clean up
    content = pad_lines(content)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False


def main():
    files = find_target_files()
    print(f"Found {len(files)} target files")
    
    modified = []
    errors = []
    for filepath in files:
        try:
            if process_file(filepath):
                modified.append(os.path.relpath(filepath, ROOT))
        except Exception as e:
            errors.append((os.path.relpath(filepath, ROOT), str(e)))
            traceback.print_exc()
    
    print(f"\n=== Summary ===")
    print(f"Modified: {len(modified)} files")
    for f in modified:
        print(f"  ✓ {f}")
    if errors:
        print(f"\nErrors: {len(errors)}")
        for f, e in errors:
            print(f"  ✗ {f}: {e}")


if __name__ == '__main__':
    main()
