"""azos-speak: spoken Claude Code replies, per session.

  azos-speak on|off     turn spoken replies on/off for this Claude session
  azos-speak status     whether they're on for this session
  azos-speak stop       silence whatever is playing
  azos-speak say TEXT   speak TEXT (for testing)
  azos-speak hook       Claude Code hook entry point (JSON on stdin)

The session is $CLAUDE_CODE_SESSION_ID, which Claude Code sets for the
commands it runs. Speech comes from the azos-speak user service, started
on demand.
"""

import json
import os
import re
import socket
import subprocess
import sys
import time

RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
RUN_DIR = os.path.join(RUNTIME_DIR, "azos-speak")
SOCKET_PATH = os.path.join(RUN_DIR, "server.sock")
SESSIONS = os.path.join(RUN_DIR, "sessions")
STYLE_FILE = "@styleFile@"
SYSTEMCTL = "@systemctl@"
MAX_CHARS = 4000


def flag(session):
    return os.path.join(SESSIONS, os.path.basename(session))


def is_on(session):
    return bool(session) and os.path.exists(flag(session))


def start_server():
    subprocess.run([SYSTEMCTL, "--user", "start", "--no-block",
                    "azos-speak.service"], check=False)


def send(msg, start=False, wait=0.0):
    """Send MSG to the server, starting it and retrying for WAIT seconds."""
    deadline = time.time() + wait
    started = False
    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                sock.connect(SOCKET_PATH)
                sock.sendall(json.dumps(msg).encode() + b"\n")
            return True
        except OSError:
            if start and not started:
                start_server()
                started = True
            if time.time() >= deadline:
                return False
            time.sleep(0.25)


def clean(text):
    """Markdown reply to text that reads well aloud."""
    text = re.sub(r"```.*?(```|\Z)", "\n", text, flags=re.S)
    text = re.sub(r"^\s*\|?\s*:?-{2,}[-:| ]*$", "", text, flags=re.M)
    text = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"https?://\S+", "a link", text)
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = re.sub(r"\\[()\[\]]", "", text)
    text = re.sub(r"^\s*(#{1,6}|>+|[-*+]|\d+[.)])\s+", "", text, flags=re.M)
    text = re.sub(r"\*\*|__|~~|(?<!\w)[*_]|[*_](?!\w)", "", text)
    text = re.sub(r"[ \t]*\|[ \t]*", ", ", text)
    lines = []
    for line in text.splitlines():
        line = re.sub(r"[ \t]+", " ", line).strip(" ,")
        if line:
            # Headings and list items: end them so they're said as sentences.
            lines.append(line if line[-1] in ".!?:;" else line + ".")
    text = "\n".join(lines)
    if len(text) > MAX_CHARS:
        cut = text.rfind(".", 0, MAX_CHARS)
        text = text[:cut + 1 if cut > 0 else MAX_CHARS]
    return text


def detach():
    """Fork; the parent returns True, the child carries on in the background."""
    if os.fork():
        return True
    os.setsid()
    devnull = os.open(os.devnull, os.O_RDWR)
    for fd in (0, 1, 2):
        os.dup2(devnull, fd)
    return False


def hook():
    data = json.load(sys.stdin)
    session = data.get("session_id", "")
    event = data.get("hook_event_name")
    if not is_on(session):
        return
    if event == "Stop":
        text = clean(data.get("last_assistant_message") or "")
        if text and not detach():
            send({"cmd": "say", "text": text}, start=True, wait=60)
            os._exit(0)
    elif event == "UserPromptSubmit":
        send({"cmd": "stop"})
        with open(STYLE_FILE, encoding="utf-8") as style:
            print(json.dumps({"hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": style.read()}}))
    elif event == "SessionEnd":
        os.unlink(flag(session))
        send({"cmd": "stop"})


def main(args):
    command = args[0] if args else "status"
    session = os.environ.get("CLAUDE_CODE_SESSION_ID", "")
    if command == "hook":
        hook()
    elif command in ("on", "off", "status"):
        if not session:
            sys.exit("azos-speak: no CLAUDE_CODE_SESSION_ID; run this from Claude Code")
        if command == "on":
            os.makedirs(SESSIONS, exist_ok=True)
            open(flag(session), "a").close()
            start_server()
        elif command == "off":
            if is_on(session):
                os.unlink(flag(session))
            send({"cmd": "stop"})
        print("Spoken replies are", "on" if is_on(session) else "off",
              "for this session.")
    elif command == "stop":
        send({"cmd": "stop"})
    elif command == "say":
        if not send({"cmd": "say", "text": clean(" ".join(args[1:]))},
                    start=True, wait=60):
            sys.exit("azos-speak: the speech service didn't start")
    else:
        sys.exit(__doc__)


main(sys.argv[1:])
