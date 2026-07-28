import subprocess
from pathlib import Path

from django.conf import settings
from django.core.cache import cache


HISTORY_PATHS = (
    'server/internal_portal',
    'docs/current/project-work-handbook.md',
    'landing/assets/js/site.js',
)


def _git_command(project_root: Path):
    worktree_git = project_root / '.git'
    bare_git = project_root.parent / f'{project_root.name}.git'
    if worktree_git.exists():
        return [
            'git', '-c', f'safe.directory={project_root.as_posix()}',
            '-C', str(project_root),
        ]
    if bare_git.is_dir():
        return [
            'git', '-c', f'safe.directory={bare_git.as_posix()}',
            f'--git-dir={bare_git}',
        ]
    return None


def get_portal_history(limit=10):
    cache_key = f'internal-portal-git-history-{limit}'
    cached = cache.get(cache_key)
    if cached is not None:
        return cached

    project_root = Path(settings.BASE_DIR).parent
    command = _git_command(project_root)
    if command is None:
        return []
    try:
        result = subprocess.run(
            command + [
                'log', f'-{limit}', '--date=short',
                '--format=%ad%x1f%h%x1f%s', '--', *HISTORY_PATHS,
            ],
            check=True,
            capture_output=True,
            text=True,
            encoding='utf-8',
            timeout=2,
        )
    except (OSError, subprocess.SubprocessError):
        return []

    history = []
    for line in result.stdout.splitlines():
        parts = line.split('\x1f', 2)
        if len(parts) == 3:
            history.append({'date': parts[0], 'commit': parts[1], 'subject': parts[2]})
    cache.set(cache_key, history, 300)
    return history
