#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys
from infinite_loop_thread import start_thread, stop_thread
from bfs.settings import DEBUG


def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'bfs.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    if not DEBUG:
        start_thread()
    main()
    if not DEBUG:
        stop_thread()
