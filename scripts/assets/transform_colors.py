"""
Transform all AppColors.* references in build methods to context.colors.*

Steps per file:
1. Add 'final colors = context.colors;' at the start of each build method
2. Replace AppColors.xxx -> colors.xxx
3. Remove 'const' from expressions that now use colors.xxx
4. Convert arrow function build methods to block bodies if they need colors
"""

import re
import os
import sys

# Fields that exist in AppSemanticColors (mapping)
field_map = {
    'primary': 'primary',
    'primaryContainer': 'primaryContainer',
    'background': 'background',
    'surface': 'surface',
    'surfaceSubtle': 'surfaceSubtle',
    'textPrimary': 'textPrimary',
    'textSecondary': 'textSecondary',
    'textMuted': 'textMuted',
    'border': 'border',
    'borderStrong': 'borderStrong',
    'divider': 'divider',
    'disabledBackground': 'disabledBackground',
    'disabledForeground': 'disabledForeground',
    'focusRing': 'focusRing',
    'scrim': 'scrim',
    'mediaSurface': 'mediaSurface',
    'imageBorder': 'imageBorder',
    'success': 'success',
    'warning': 'warning',
    'error': 'error',
    'info': 'info',
    'recommendation': 'recommendation',
    'successContainer': 'successContainer',
    'warningContainer': 'warningContainer',
    'errorContainer': 'errorContainer',
    'infoContainer': 'infoContainer',
    'recommendationContainer': 'recommendationContainer',
    # Newly added fields
    'onSuccessContainer': 'onSuccessContainer',
    'onWarningContainer': 'onWarningContainer',
    'onErrorContainer': 'onErrorContainer',
    'onInfoContainer': 'onInfoContainer',
    'onRecommendationContainer': 'onRecommendationContainer',
    'heatmapLevel1': 'heatmapLevel1',
    'heatmapLevel2': 'heatmapLevel2',
    # Aliases that map directly
    'tagDifficultyBg': 'warningContainer',
    'statusCompletedBg': 'successContainer',
    'statusInProgressBg': 'infoContainer',
    'statusPendingBg': 'surfaceSubtle',
    'heatmapLevel3': 'primary',
    'primaryLight': 'primaryContainer',
    'card': 'surface',
}

# Fields that need special handling (mapped to onXxxContainer which now exists)
alias_to_fields = {
    'tagDifficultyFg': 'onWarningContainer',
    'statusCompletedFg': 'success',
    'statusInProgressFg': 'warning',
    'statusPendingFg': 'textSecondary',
}


def remove_const_for_colors(line):
    """Remove 'const ' before expressions that use 'colors.' in the line."""
    if 'colors.' not in line:
        return line
    
    # Handle 'const SomeWidget(...)'
    # Need to be careful not to remove 'const' from variable declarations
    
    # Pattern: remove 'const ' before a constructor/function call that has colors in its arguments
    # Simple case: 'const WidgetName(' on same line as colors.
    # More complex: 'const WidgetName(\n  ... colors.'
    
    # First, handle single-line const expressions
    # Replace 'const WidgetName(' -> 'WidgetName(' if colors. is in the same expression
    # This regex matches 'const ' followed by an identifier and '(' or '.' and '<'
    line = re.sub(r'\bconst\s+(?=[A-Za-z_]\w*\s*[<(])', '', line)
    
    # Handle 'const [' and 'const {' if they contain colors.
    line = re.sub(r'\bconst\s+(?=[\[{])', '', line)
    
    return line


def add_colors_declaration(method_body, non_color_appendix='', is_build_method=True):
    """After a '{', add 'final colors = context.colors;' line."""
    # Find the first '{' in the build method
    brace_idx = method_body.find('{')
    if brace_idx == -1:
        return method_body
    
    indent = '  '  # standard 2-space indent for flutter
    
    # Get the indentation based on what comes after the brace
    before_brace = method_body[:brace_idx]
    # Count the existing indentation level by looking at the line structure
    # Default to 2 more spaces than the build method line
    
    insert = f'\n{indent}    final colors = context.colors;'
    new_body = method_body[:brace_idx+1] + insert + method_body[brace_idx+1:]
    return new_body


def convert_arrow_to_block(match_text, arrow_expr, non_color_part=''):
    """Convert an arrow function to a block body."""
    indent = '  '
    body_indent = '      '
    colors_line = f'{body_indent}final colors = context.colors;\n'
    
    # Build the new block body
    new_body = f'{indent}}}}}\n{indent}        {colors_line}{body_indent}return {arrow_expr.strip()};'
    
    # Hmm this is getting complex. Let me use a simpler approach.
    return match_text  # placeholder - will be handled differently


def transform_file(filepath, dry_run=False):
    """Transform a single Dart file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content

    # 1. Replace AppColors.xxx -> colors.xxx
    # Both simple fields and aliases
    for old_field, new_field in {**field_map, **alias_to_fields}.items():
        content = content.replace(f'AppColors.{old_field}', f'colors.{new_field}')
    
    if content == original:
        return False  # No changes
    
    # 2. Handle const removal for expressions that now use colors.
    lines = content.split('\n')
    new_lines = []
    
    for i, line in enumerate(lines):
        if 'colors.' in line:
            # Remove 'const ' before expressions on this line
            line = remove_const_for_colors(line)
        new_lines.append(line)
    
    content = '\n'.join(new_lines)
    
    # 3. Handle multiline const expressions
    # Find cases where a line starts with 'const ' and later lines contain 'colors.'
    # This is for multiline expressions like:
    # const SomeWidget(
    #   color: colors.xxx,
    # )
    result_lines = []
    i = 0
    while i < len(new_lines):
        line = new_lines[i]
        stripped = line.strip()
        
        # Check if this line starts a const expression (const WidgetName(...)
        # or const [...)
        if stripped.startswith('const '):
            # Check if this expression (possibly multi-line) contains 'colors.'
            # Find matching closing bracket if needed
            # Simplification: just check if 'colors.' appears in any subsequent line
            # before the expression closes
            pass  # Will handle via dart analyze errors
        
        result_lines.append(line)
        i += 1
    
    # 4. Add 'final colors = context.colors;' in build methods
    # Find patterns like:
    #   Widget build(BuildContext context) {
    # or arrow functions with colors usage:
    #   Widget build(BuildContext context) => ...AppColors...
    # which would already be replaced to colors.
    
    # Find all build methods with block bodies
    content = _add_colors_to_build_methods(content)
    
    # 5. Handle Builder callbacks
    content = _add_colors_to_builder_callbacks(content)
    
    if dry_run:
        return content != original
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return True


def _add_colors_to_build_methods(content):
    """Add 'final colors = context.colors;' to beginning of build methods."""
    # Pattern: Widget build(BuildContext context) {
    # But also nested methods, stateful/stateless
	
    # Simple approach: find 'build(BuildContext context) {' and add declaration after
    # More precise: find function definition lines
	
    lines = content.split('\n')
    new_lines = []
    in_build_method = False
    brace_depth = 0
    build_start_line = -1
	
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        
        # Detect start of build method
        # Match: Widget build(BuildContext context) {  or  Widget build(BuildContext context) =>
        if not in_build_method:
            build_match = re.search(r'\bWidget\s+build\s*\(\s*BuildContext\s+\w+\s*\)', stripped)
            if build_match:
                # Check if it's an arrow function
                if '=>' in stripped:
                    # Arrow function - check if colors. is used in the expression
                    # The expression after => might span multiple lines via parenthesis
                    # We need to convert it to a block body
                    
                    # Get the part after =>
                    arrow_idx = stripped.index('=>')
                    rest = stripped[arrow_idx+2:].strip()
                    
                    # Check if this arrow expression or subsequent lines have 'colors.'
                    colors_in_expr = 'colors.' in rest or 'colors.' in '\n'.join(lines[i:i+10])
                    
                    if colors_in_expr:
                        # Convert to block body
                        # Find the entire expression (could be multiline if wrapped in parens)
                        expr_start = arrow_idx + 2
                        # Check if expression is wrapped in parens
                        if rest.startswith('('):
                            # Find matching closing paren
                            depth = 0
                            end_idx = -1
                            for j, c in enumerate(rest):
                                if c == '(':
                                    depth += 1
                                elif c == ')':
                                    depth -= 1
                                    if depth == 0:
                                        end_idx = arrow_idx + 2 + j + 1
                                        break
                            if end_idx > 0:
                                # Check if it ends with );
                                full_expr = rest[:end_idx - arrow_idx - 2 + 1]
                                semicolon = ';' if lines[i].rstrip().endswith(';') else ';'
                                
                                indent_match = re.match(r'^(\s*)', line)
                                indent = indent_match.group(1) if indent_match else '  '
                                body_indent = indent + '  '
                                
                                new_line = f'{indent}Widget build(BuildContext context) {{\n'
                                new_line += f'{body_indent}final colors = context.colors;\n'
                                new_line += f'{body_indent}return {full_expr};\n'
                                new_line += f'{indent}}}'
                                
                                lines[i] = new_line
                                new_lines.append(lines[i])
                                i += 1
                                continue
                        else:
                            # Simple expression (no parens)
                            # Extract the expression (remove trailing semicolon)
                            expr = rest.rstrip().rstrip(';')
                            
                            indent_match = re.match(r'^(\s*)', line)
                            indent = indent_match.group(1) if indent_match else '  '
                            body_indent = indent + '  '
                            
                            new_line = f'{indent}Widget build(BuildContext context) {{\n'
                            new_line += f'{body_indent}final colors = context.colors;\n'
                            new_line += f'{body_indent}return {expr};\n'
                            new_line += f'{indent}}}'
                            
                            lines[i] = new_line
                            new_lines.append(lines[i])
                            i += 1
                            continue
                else:
                    # Block body - check if }, ); or } is on same line
                    brace_idx = stripped.index('{')
                    if brace_idx >= 0:
                        # Check if this file has 'colors.' anywhere
                        if 'colors.' in '\n'.join(lines[i:]):  # Only bother if colors are used
                            in_build_method = True
                            brace_depth = 1
                            build_start_line = i
                            # Add colors declaration right after the opening brace
                            indent_match = re.match(r'^(\s*)', line)
                            indent = indent_match.group(1) if indent_match else '  '
                            body_indent = indent + '  '
                            
                            # Insert after the brace
                            insert = f'\n{body_indent}final colors = context.colors;'
                            brace_pos_in_line = stripped.index('{')
                            actual_brace_pos = len(line) - len(stripped) + brace_pos_in_line
                            line = line[:actual_brace_pos+1] + insert + line[actual_brace_pos+1:]
                            lines[i] = line
                            new_lines.append(lines[i])
                            i += 1
                            continue
                # If no colors usage or no {, just pass through
                new_lines.append(lines[i])
                i += 1
                continue
        else:
            # We're inside a build method - track brace depth
            for c in line:
                if c == '{':
                    brace_depth += 1
                elif c == '}':
                    brace_depth -= 1
                    if brace_depth == 0:
                        in_build_method = False
        
        new_lines.append(lines[i])
        i += 1
    
    return '\n'.join(new_lines)


def _add_colors_to_builder_callbacks(content):
    """Add colors declaration to Builder callbacks like builder: (ctx) => ..."""
    # Pattern 1: builder: (ctx) =>  (then need to add { final colors = ctx.colors; return ...; })
    # Pattern 2: builder: (ctx) { ... }
    
    lines = content.split('\n')
    new_lines = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        
        # Detect builder: (ctx) => ... pattern
        # This is a callback, not a build method, but the task says to handle dialog builders
        builder_arrow_match = re.search(r'\bbuilder\s*:\s*\((\w+)\)\s*=>', stripped)
        if builder_arrow_match:
            ctx_var = builder_arrow_match.group(1)
            # Check if 'colors.' or 'AppColors.' (already transformed) is in the arrow expression
            rest = stripped[stripped.index('=>')+2:].strip()
            has_colors = 'colors.' in rest
            # Also check subsequent lines if the expression wraps
            j = i + 1
            while j < len(lines) and not rest.rstrip().endswith(','):
                has_colors = has_colors or 'colors.' in lines[j]
                rest += ' ' + lines[j].strip()
                j += 1
            
            if has_colors:
                # Convert arrow to block
                indent_match = re.match(r'^(\s*)', line)
                indent = indent_match.group(1) if indent_match else '    '
                body_indent = indent + '  '
                
                # Extract the full expression
                full_expr_lines = [line]
                k = i + 1
                while k < len(lines):
                    l = lines[k]
                    full_expr_lines.append(l)
                    if l.rstrip().endswith(','):
                        k += 1
                        break
                    k += 1
                
                full_expr = ' '.join(l.strip() for l in full_expr_lines)
                arrow_idx = full_expr.index('=>')
                expr = full_expr[arrow_idx+2:].strip()
                if expr.endswith(','):
                    expr = expr[:-1]
                
                # Convert to block body
                new_line = f'{indent}builder: ({ctx_var}) {{\n'
                new_line += f'{body_indent}final colors = {ctx_var}.colors;\n'
                new_line += f'{body_indent}return {expr};\n'
                new_line += f'{indent}}},'
                
                lines[i] = new_line
                # Skip the consumed lines
                for skip in range(i+1, k):
                    lines[skip] = ''  # Comment out or remove
                new_lines.append(lines[i])
                i = k
                continue
        
        # Pattern: builder: (ctx) { ... } - check if it uses colors and needs declaration
        builder_block_match = re.search(r'\bbuilder\s*:\s*\((\w+)\)\s*\{', stripped)
        if builder_block_match:
            ctx_var = builder_block_match.group(1)
            # Check if colors. is used in this block
            brace_count = 1
            has_colors = 'colors.' in line
            j = i + 1
            while j < len(lines) and brace_count > 0:
                l = lines[j]
                for c in l:
                    if c == '{':
                        brace_count += 1
                    elif c == '}':
                        brace_count -= 1
                if brace_count > 0:
                    has_colors = has_colors or 'colors.' in l
                j += 1
            
            if has_colors and not re.search(r'final\s+colors\s*=\s*' + ctx_var + r'\.colors', 
                                              '\n'.join(lines[i:j])):
                # Add colors declaration after the opening brace
                brace_pos = line.index('{')
                indent_match = re.match(r'^(\s*)', line)
                indent = indent_match.group(1) if indent_match else '    '
                body_indent = indent + '  '
                insert = f'\n{body_indent}final colors = {ctx_var}.colors;'
                line = line[:brace_pos+1] + insert + line[brace_pos+1:]
                lines[i] = line
        
        new_lines.append(lines[i])
        i += 1
    
    return '\n'.join(new_lines)


def main():
    target_dirs = [
        'flutter_app/lib/pages',
        'flutter_app/lib/widgets',
        'packages/shared/lib/widgets',
    ]
    
    base_dir = 'D:\\Hermes\\zhangyuzhixue_app_v2'
    dry_run = '--dry-run' in sys.argv
    
    total = 0
    modified = 0
    skipped = []
    
    for d in target_dirs:
        full_dir = os.path.join(base_dir, d)
        if not os.path.exists(full_dir):
            continue
        for root, dirs, files in os.walk(full_dir):
            for f in files:
                if not f.endswith('.dart'):
                    continue
                path = os.path.join(root, f)
                total += 1
                try:
                    changed = transform_file(path, dry_run=dry_run)
                    if changed:
                        modified += 1
                        rel = os.path.relpath(path, base_dir)
                        print(f"  {'[DRY RUN]' if dry_run else '[MODIFIED]'} {rel}")
                    else:
                        rel = os.path.relpath(path, base_dir)
                        skipped.append(rel)
                except Exception as e:
                    rel = os.path.relpath(path, base_dir)
                    print(f"  [ERROR] {rel}: {e}", file=sys.stderr)
    
    print(f"\n{'--- DRY RUN ---' if dry_run else '--- DONE ---'}")
    print(f"Total: {total} files")
    print(f"Modified: {modified} files")
    print(f"No AppColors: {len(skipped)} files")


if __name__ == '__main__':
    main()
