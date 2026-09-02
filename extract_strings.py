import re
import json
import sys
from pathlib import Path

# ──────────────────────────────────────────────────────────────
#  CONFIG
# ──────────────────────────────────────────────────────────────

IGNORE_DIRS = {'.dart_tool', '.idea', 'build', '.gradle', 'android', 'ios', 'generated', 'l10n'}

ALREADY_DONE = {'home_page.dart', 'welcome_page.dart', 'profile_page.dart'}

# Strings techniques à ignorer
IGNORE_EXACT = {
    'EXP', 'RFID', 'QC', 'NFC', 'EPC', 'SSE', 'ARB',
    '0000', 'v1.0', 'TC52', 'CapMobile',
}

IGNORE_PATTERNS = [
    r'^com\.', r'^flutter/', r'^package:', r'^assets/',
    r'^#[0-9A-Fa-f]{3,}',
    r'^\d+[\.\d]*$',
    r'^[A-Z_]{3,}$',
    r'onScanButton', r'disableDataWedge', r'cap_mobile',
    r'^\s*$', r'^\.', r'^http', r'^/',
    r'\.dart$', r'\.json$', r'\.png$',
    r'^com\.example',
    r'^\w+\.\w+\(',   # méthode call
]

def should_ignore(text):
    text = text.strip()
    if len(text) < 2:
        return True
    if text in IGNORE_EXACT:
        return True
    for p in IGNORE_PATTERNS:
        if re.search(p, text):
            return True
    return False

def to_camel_key(text, prefix=''):
    clean = re.sub(r'[^a-zA-Z0-9\s]', ' ', text)
    words = clean.strip().split()[:5]
    if not words:
        return None
    key = words[0].lower() + ''.join(w.capitalize() for w in words[1:])
    if prefix:
        key = prefix + key[0].upper() + key[1:]
    # max 40 chars
    return key[:40]

def get_prefix(filename):
    name = Path(filename).stem
    parts = name.replace('_page', '').replace('_screen', '').replace('_tab', '').split('_')
    return parts[0] if parts else ''

# ──────────────────────────────────────────────────────────────
#  EXTRACTION — patterns très larges
# ──────────────────────────────────────────────────────────────

def extract_from_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    found = []
    seen_texts = set()

    # Pattern universel : trouve TOUTES les strings simples (sans $ ni \n)
    # entre quotes simples ou doubles, de 2 à 100 chars
    universal = re.compile(r"""(?:const\s+)?['"]([\w\s\u00C0-\u024F\u00B7&·'\-\!\?\:\.\,\/\(\)%@\+\=\[\]]{2,100})['"]""")

    lines = content.split('\n')

    for line_num, line in enumerate(lines, 1):
        # Ignorer les lignes qui sont déjà localisées
        if 'AppLocalizations' in line or 'l10n.' in line:
            continue
        # Ignorer les commentaires
        stripped = line.strip()
        if stripped.startswith('//') or stripped.startswith('*'):
            continue
        # Ignorer les imports
        if stripped.startswith('import ') or stripped.startswith('export '):
            continue

        for match in universal.finditer(line):
            text = match.group(1).strip()

            # Filtres
            if should_ignore(text):
                continue
            if text in seen_texts:
                continue

            # Vérifier que c'est dans un contexte UI (pas une valeur technique)
            # On accepte si la ligne contient des mots-clés UI
            ui_keywords = [
                'Text(', 'label:', 'title:', 'subtitle:', 'hintText:',
                'hint:', 'value:', 'child:', 'content:', 'message:',
                'tooltip:', 'semanticsLabel:', 'helperText:', 'errorText:',
                'prefixText:', 'suffixText:', 'counterText:',
                'ElevatedButton', 'OutlinedButton', 'TextButton',
                'SnackBar', 'AlertDialog', 'showDialog',
                'AppBar', 'Tab(', 'BottomNavigationBarItem',
            ]

            is_ui = any(kw in line for kw in ui_keywords)

            # Aussi accepter si c'est du français/texte humain (contient espace ou accent)
            has_space_or_accent = ' ' in text or any(c > '\x7f' for c in text)

            if not is_ui and not has_space_or_accent:
                continue

            seen_texts.add(text)
            found.append({
                'text': text,
                'line': line_num,
                'context': line.strip()[:100]
            })

    return found

# ──────────────────────────────────────────────────────────────
#  MAIN
# ──────────────────────────────────────────────────────────────

def main():
    project_root = Path(r'C:\Users\asmaa.ouahyb\StudioProjects\cap_mobile1')
    lib_path = project_root / 'lib'

    if not lib_path.exists():
        print(f"ERREUR: Dossier lib introuvable : {lib_path}")
        sys.exit(1)

    print("=" * 65)
    print("  ANALYSE DES STRINGS EN DUR v2 — MODE RAPPORT")
    print("=" * 65)
    print()

    all_results = {}

    for dart_file in sorted(lib_path.rglob('*.dart')):
        parts = dart_file.parts
        if any(d in IGNORE_DIRS for d in parts):
            continue

        filename = dart_file.name

        if filename in ALREADY_DONE:
            print(f"  ✓ DÉJÀ FAIT : {filename}")
            continue

        if filename.startswith('app_localizations') or filename.endswith('.g.dart'):
            continue

        strings = extract_from_file(dart_file)

        if strings:
            rel_path = dart_file.relative_to(project_root)
            all_results[str(rel_path)] = strings

    print()
    print("=" * 65)
    print("  RÉSULTATS")
    print("=" * 65)

    total = 0
    arb_additions = {}

    for filepath, strings in all_results.items():
        filename = Path(filepath).name
        prefix = get_prefix(filename)
        print(f"\n📄 {filepath} ({len(strings)} strings)")
        print("-" * 55)

        for item in strings:
            text = item['text']
            key = to_camel_key(text, prefix)
            if key:
                print(f"  L{item['line']:4d} | {key}")
                print(f"         → \"{text}\"")
                if key not in arb_additions:
                    arb_additions[key] = text
                total += 1

    print()
    print("=" * 65)
    print(f"  TOTAL : {total} strings dans {len(all_results)} fichiers")
    print("=" * 65)

    report_path = project_root / 'strings_report_v2.json'
    with open(report_path, 'w', encoding='utf-8') as f:
        json.dump({
            'files': all_results,
            'arb_additions': arb_additions
        }, f, ensure_ascii=False, indent=2)

    print(f"\n✅ Rapport sauvegardé : {report_path}")
    print()
    print("PROCHAINE ÉTAPE :")
    print("  Envoie le rapport à Claude pour validation.")

if __name__ == '__main__':
    main()