import os
import re

def fix_with_opacity(directory):
    """Replace .withOpacity() with .withValues(alpha:) in all Dart files"""
    count = 0
    files_modified = []
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Replace .withOpacity(value) with .withValues(alpha: value)
                    new_content = re.sub(
                        r'\.withOpacity\((\s*[\d.]+\s*)\)',
                        r'.withValues(alpha: \1)',
                        content
                    )
                    
                    if new_content != content:
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        files_modified.append(filepath)
                        count += content.count('.withOpacity(')
                        print(f"Fixed: {filepath}")
                except Exception as e:
                    print(f"Error processing {filepath}: {e}")
    
    print(f"\nTotal: Fixed {count} occurrences in {len(files_modified)} files")
    return files_modified

if __name__ == "__main__":
    lib_dir = r"e:\Garage_App\lib"
    fixed_files = fix_with_opacity(lib_dir)
