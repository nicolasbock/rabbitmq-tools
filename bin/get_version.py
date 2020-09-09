#!/usr/bin/env python3

import subprocess


def get_version():
    try:
        git = subprocess.run(['git', 'describe', '--tags'],
                             stdout=subprocess.PIPE, universal_newlines=True)
        full_version = git.stdout.strip()[1:]
    except AttributeError:
        git = subprocess.Popen(['git', 'describe', '--tags'],
                               stdout=subprocess.PIPE, universal_newlines=True)
        stdout_raw, stderr_raw = git.communicate()
        git.wait()
        full_version = stdout_raw.strip()[1:]
    except Exception:
        print("Cannot read version")
        raise

    try:
        git = subprocess.run(['git', 'describe', '--tags', '--abbrev=0'],
                             stdout=subprocess.PIPE, universal_newlines=True)
        abbreviated_version = git.stdout.strip()[1:]
    except AttributeError:
        git = subprocess.Popen(['git', 'describe', '--tags', '--abbrev=0'],
                               stdout=subprocess.PIPE, universal_newlines=True)
        stdout_raw, stderr_raw = git.communicate()
        git.wait()
        abbreviated_version = stdout_raw.strip()[1:]
    except Exception:
        print("Cannot read version")
        raise

    local_version = full_version.replace(abbreviated_version, '')

    if len(local_version) > 0:
        version = (abbreviated_version + '+'
                   + local_version[1:].replace('-', '.'))
    else:
        version = abbreviated_version

    return version


if __name__ == "__main__":
    print(get_version())
