"""
Fix scope issues: add `final colors = context.colors;` to ALL functions/lambdas
that take a BuildContext parameter and contain `colors.` references.

Also handle remaining edge cases from the AppColors→colors migration.
"""

import re
import os

ROOT = r'D:\Hermes\zhangyuzhixue_app_v2'


def find_block_end(lines, start_line):
    bal = 0
    bal += lines[start_line].count('{') - lines[start_line].count('}')
    if bal <= 0:
        return start_line + 1
    j = start_line + 1
    while j < len(lines) and bal > 0:
        bal += lines[j].count('{') - lines[j].count('}')
        j += 1
    return j


def fix_scope_issues(text):
    """
    Add `final colors = context.colors;` to any function/method/lambda that:
    - Has a parameter named 'context' or 'ctx' of type BuildContext
    - Contains `colors.` in its body
    
    Also handle multi-line arrow builder callbacks.
    """
    lines = text.split('\n')
    new_lines = list(lines)
    changed = False

    # Track insertions we need to make (index -> text to add after opening {)
    insertions = []

    # ---- Pass 1: Find all functions/lambdas with BuildContext params that use colors ----
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Skip lines we inserted (empty sentinel)
        if not stripped:
            i += 1
            continue

        # Check if the line has a function/closure signature with BuildContext
        # Pattern A: `SomeReturnType funcName(BuildContext context) {` or `(BuildContext context) {`
        # Pattern B: `funcName(BuildContext context, ...) {`
        
        has_bc_param = False
        ctx_param_name = None
        is_annotation = False

        # Check if this line is a @override or similar annotation
        if re.match(r'^\s*@', stripped):
            is_annotation = True
            # Check next line too
            if i + 1 < len(lines):
                next_line = lines[i + 1].strip()
                # Don't consume the next line, just check
                pass

        # Pattern: (BuildContext context) { or (context) {
        m = re.search(r'\(\s*(BuildContext\s+)?(context|ctx)\s*\)\s*\{', stripped)
        if m:
            has_bc_param = True
            ctx_param_name = m.group(2)
        else:
            # Pattern: funcName(BuildContext context) { 
            # or funcName(BuildContext context,) {
            m = re.search(r'\(\s*BuildContext\s+(context|ctx)\s*[,\)]', stripped)
            if m:
                has_bc_param = True
                ctx_param_name = m.group(1)
            else:
                # Pattern: (context, ...) { - context as first param name
                m = re.search(r'\(\s*(context|ctx)\s*[,\)]', stripped)
                if m:
                    has_bc_param = True
                    ctx_param_name = m.group(1)

        if has_bc_param:
            # Find the function body
            if '{' in stripped:
                end = find_block_end(lines, i)
            else:
                # Opening brace on next line
                j = i + 1
                while j < len(lines) and '{' not in lines[j]:
                    j += 1
                if j < len(lines):
                    end = find_block_end(lines, j)
                else:
                    i += 1
                    continue

            # Check if this function uses `colors.`
            func_body = lines[i:end]
            has_colors_ref = any('colors.' in l for l in func_body)
            
            if has_colors_ref:
                # Check if `final colors =` already exists in the body
                has_def = any('final colors =' in l or 'var colors =' in l for l in func_body)
                if not has_def:
                    # Find the opening brace
                    brace_line = i
                    if '{' not in lines[brace_line]:
                        for k in range(i, end):
                            if '{' in lines[k]:
                                brace_line = k
                                break
                    
                    if brace_line < end:
                        # Insert after the opening brace
                        insertions.append(brace_line)
                i = end
                continue

        # ---- Handle multi-line arrow builder callbacks ----
        # Pattern: builder: (ctx) => Widget(  ...spans multiple lines... ),
        m = re.match(
            r'^(\s*)(\w+\s*:\s*)?\(\s*(?:BuildContext\s+)?(context|ctx)\s*\)\s*=>\s*(.+?)$',
            stripped
        )
        if m and 'colors.' in stripped:
            # This is a single-line arrow that starts on this line
            # Check if the expression continues past this line
            expr = m.group(4).strip()
            open_parens = expr.count('(')
            close_parens = expr.count(')')
            # Also track <>
            open_angles = expr.count('<')
            close_angles = expr.count('>')
            
            # If everything is closed on this line, it was handled in Pass 1 already
            if open_parens > close_parens or open_angles > close_angles:
                # Multi-line: find the end
                bal_parens = open_parens - close_parens
                bal_angles = open_angles - close_angles
                prefix_indent = m.group(1)
                named_param = m.group(2) or ''
                ctx_name = m.group(3)
                expr_parts = [expr]
                
                j = i + 1
                while j < len(lines) and (bal_parens > 0 or bal_angles > 0):
                    line_j = lines[j]
                    bal_parens += line_j.count('(') - line_j.count(')')
                    bal_angles += line_j.count('<') - line_j.count('>')
                    expr_parts.append(line_j.strip())
                    j += 1
                
                # Check if colors appears in any part
                all_expr = ' '.join(expr_parts)
                if 'colors.' in all_expr:
                    # Remove trailing comma or paren
                    all_expr = all_expr.rstrip(',').rstrip(')').rstrip()
                    # Build the replacement
                    new_lines[i] = (
                        f'{prefix_indent}{named_param}({ctx_name}) {{\n'
                        f'{prefix_indent}      final colors = context.colors;\n'
                        f'{prefix_indent}      return {all_expr};\n'
                        f'{prefix_indent}    }},'
                    )
                    for k in range(i + 1, j + 1):
                        new_lines[k] = ''
                    changed = True
                    i = j
                    continue

        i += 1

    # Apply insertions (from end to start to preserve line numbers)
    for idx in sorted(insertions, reverse=True):
        line = new_lines[idx]
        brace_pos = line.index('{')
        new_lines[idx] = (line[:brace_pos + 1] + '\n' +
                         '    final colors = context.colors;' +
                         line[brace_pos + 1:])
        changed = True

    return '\n'.join(new_lines), changed


def fix_main_dart_issues(text):
    """
    Specific fixes for main.dart edge cases:
    1. Line 102: colors.warning inside _ callback in main() - no context param
    2. Multi-line arrow builder callback at line 145
    3. Top-level _showForcedUpdateDialog, _startUpdate, _showUpdateBanner
    """
    lines = text.split('\n')
    new_lines = list(lines)
    changed = False

    # Fix 1: _showForcedUpdateDialog(BuildContext context, ...) - has BuildContext context param
    # Add `final colors = context.colors;` after the opening brace
    # Pattern on line 139 currently
    for i in range(len(lines)):
        stripped = lines[i].strip()
        if '_showForcedUpdateDialog(BuildContext context' in stripped and '{' in stripped:
            brace_pos = lines[i].index('{')
            # Check if colors already defined
            has_colors_def = False
            end = find_block_end(lines, i)
            for j in range(i, end):
                if 'final colors =' in lines[j] or 'var colors =' in lines[j]:
                    has_colors_def = True
                    break
            if not has_colors_def and any('colors.' in lines[j] for j in range(i, end)):
                new_lines[i] = (lines[i][:brace_pos + 1] + '\n' +
                               '    final colors = context.colors;' +
                               lines[i][brace_pos + 1:])
                changed = True
            break

    # Fix 2: _startUpdate(BuildContext context, ...)
    for i in range(len(lines)):
        stripped = lines[i].strip()
        if '_startUpdate(BuildContext context' in stripped and '{' in stripped:
            brace_pos = lines[i].index('{')
            end = find_block_end(lines, i)
            has_colors_def = any('final colors =' in lines[j] or 'var colors =' in lines[j] for j in range(i, end))
            if not has_colors_def and any('colors.' in lines[j] for j in range(i, end)):
                new_lines[i] = (lines[i][:brace_pos + 1] + '\n' +
                               '    final colors = context.colors;' +
                               lines[i][brace_pos + 1:])
                changed = True
            break

    # Fix 3: colors.warning at line 102 (inside main() callback, no context)
    # This one is tricky - the `ctx` is from routerNavigatorKey, not a param
    # Need to change `colors.warning` back to `AppColors.warning` or add a workaround
    # Since there's no context parameter, we need to use ctx.colors
    for i in range(len(lines)):
        if 'backgroundColor: colors.warning' in lines[i]:
            # This is inside addPostFrameCallback where ctx is local
            # We need `final colors = Theme.of(ctx).extension<AppSemanticColors>()!;`
            # OR just use AppColors.warning (static)
            # Since it's a simple color reference, let's use AppColors.warning to be safe
            # Actually, let me look at the context more carefully.
            # The function `main()` doesn't have context, but `ctx` is obtained from
            # routerNavigatorKey.currentContext. We could do:
            # final colors = Theme.of(ctx).extension<AppSemanticColors>()!;
            # But that's complex. The safest fix is to revert to AppColors.warning
            new_lines[i] = lines[i].replace('colors.warning', 'AppColors.warning')
            changed = True
            break

    # Fix 4: builder: (ctx) => PopScope(...) at line 145 - multi-line arrow callback
    for i in range(len(lines)):
        stripped = lines[i].strip()
        m = re.match(r'^(\s*)builder:\s*\(ctx\)\s*=>\s*PopScope\(', stripped)
        if m:
            prefix_indent = m.group(1)
            # Find how many lines this spans
            bal = 1  # one opening paren
            j = i + 1
            while j < len(lines) and bal > 0:
                bal += lines[j].count('(') - lines[j].count(')')
                j += 1
            
            expr_parts = []
            for k in range(i, j):
                expr_parts.append(lines[k].strip())
            all_expr = ' '.join(expr_parts)
            # Remove leading "builder: (ctx) => "
            expr_body = re.sub(r'^builder:\s*\(ctx\)\s*=>\s*', '', all_expr)
            expr_body = expr_body.rstrip(',').rstrip()
            
            # Only replace if colors. is in the expression
            if 'colors.' in all_expr:
                new_lines[i] = (
                    f'{prefix_indent}builder: (ctx) {{\n'
                    f'{prefix_indent}      final colors = context.colors;\n'
                    f'{prefix_indent}      return {expr_body};\n'
                    f'{prefix_indent}    }},'
                )
                for k in range(i + 1, j + 1):
                    new_lines[k] = ''
                changed = True
            break

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


def fix_file(filepath):
    rel = os.path.relpath(filepath, ROOT)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Only process files that have `colors.` references
    if 'colors.' not in content:
        return False
    
    # Global fix: add colors to all functions/lambdas with BuildContext params
    content, changed1 = fix_scope_issues(content)
    
    # Specific fix for main.dart
    if 'main.dart' in filepath:
        content = fix_main_dart_issues(content)
        changed1 = True
    
    content = pad_lines(content)
    
    if changed1 or content != content:  # second condition always false, but kept for safety
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False


def main():
    # Process all files that were already modified
    target_dirs = []
    for d in [
        r'flutter_app\lib\pages',
        r'flutter_app\lib\widgets',
        r'packages\shared\lib\widgets',
        r'teacher_app\lib\pages',
        r'teacher_app\lib\widgets',
    ]:
        target_dirs.append(os.path.join(ROOT, d))
    
    extra_files = [os.path.join(ROOT, r'flutter_app\lib\main.dart')]
    
    files = set()
    for td in target_dirs:
        if os.path.isdir(td):
            for root, _, filenames in os.walk(td):
                for fn in filenames:
                    if fn.endswith('.dart'):
                        files.add(os.path.join(root, fn))
    for ef in extra_files:
        if os.path.exists(ef):
            files.add(ef)
    
    files = sorted(files)
    print(f"Scanning {len(files)} files for colors scope issues")
    
    modified = []
    for filepath in files:
        try:
            if fix_file(filepath):
                modified.append(os.path.relpath(filepath, ROOT))
        except Exception as e:
            print(f"  ERROR: {os.path.relpath(filepath, ROOT)}: {e}")
            import traceback
            traceback.print_exc()
    
    print(f"\nFixed scope issues in {len(modified)} files")
    for f in modified:
        print(f"  ✓ {f}")


if __name__ == '__main__':
    main()
