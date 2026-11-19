"""Keep Kokoro loaded and speak text sent over a unix socket.

Usage: server.py MODEL_DIR SOCKET PW_PLAY SPEED

Each connection sends one JSON line: {"cmd": "say", "text": ...} replaces
whatever is playing, {"cmd": "stop"} silences it. Text is generated and
played sentence by sentence, so speech starts after the first one. Exits
after AZOS_SPEAK_IDLE_SECONDS (default 1800) without requests; the client
starts it again on demand.
"""

import json
import os
import queue
import socket
import subprocess
import sys
import tempfile
import threading
import time

import soundfile
from kokoro import KModel, KPipeline

MODEL_DIR, SOCKET_PATH, PW_PLAY, SPEED = sys.argv[1:5]
SPEED = float(SPEED)
IDLE_SECONDS = int(os.environ.get("AZOS_SPEAK_IDLE_SECONDS", "1800"))
REPO = "hexgrad/Kokoro-82M"
VOICE = os.path.join(MODEL_DIR, "af_heart.pt")
RATE = 24000
# Sentence ends and line breaks: each piece is generated and played on its own.
SPLIT = r"(?<=[.!?])\s+|\n+"

model = KModel(repo_id=REPO,
               config=os.path.join(MODEL_DIR, "config.json"),
               model=os.path.join(MODEL_DIR, "kokoro-v1_0.pth")).eval()
pipeline = KPipeline(lang_code="a", repo_id=REPO, model=model)
for _ in pipeline("Ready.", voice=VOICE, speed=SPEED):
    pass

lock = threading.Lock()
infer_lock = threading.Lock()
generation = 0
player = None
playing = False
last_used = time.time()


def stop():
    global generation
    with lock:
        generation += 1
        if player is not None and player.poll() is None:
            player.terminate()


def current(gen):
    with lock:
        return gen == generation


def produce(text, gen, chunks, workdir):
    try:
        with infer_lock:
            for result in pipeline(text, voice=VOICE, speed=SPEED,
                                   split_pattern=SPLIT):
                if not current(gen):
                    break
                if result.audio is None:
                    continue
                fd, path = tempfile.mkstemp(suffix=".wav", dir=workdir)
                os.close(fd)
                soundfile.write(path, result.audio.numpy(), RATE)
                chunks.put(path)
    finally:
        chunks.put(None)


def speak(text, gen):
    global player, playing
    workdir = os.path.dirname(SOCKET_PATH)
    chunks = queue.Queue()
    threading.Thread(target=produce, args=(text, gen, chunks, workdir),
                     daemon=True).start()
    playing = True
    try:
        while (path := chunks.get()) is not None:
            try:
                with lock:
                    if gen != generation:
                        continue
                    player = subprocess.Popen([PW_PLAY, path])
                player.wait()
            finally:
                os.unlink(path)
    finally:
        if current(gen):
            playing = False


def handle(conn):
    global last_used
    with conn:
        data = b""
        while not data.endswith(b"\n") and (chunk := conn.recv(65536)):
            data += chunk
    try:
        msg = json.loads(data)
    except ValueError:
        return
    last_used = time.time()
    stop()
    if msg.get("cmd") == "say" and msg.get("text", "").strip():
        with lock:
            gen = generation
        threading.Thread(target=speak, args=(msg["text"], gen),
                         daemon=True).start()


def main():
    os.makedirs(os.path.dirname(SOCKET_PATH), exist_ok=True)
    if os.path.exists(SOCKET_PATH):
        os.unlink(SOCKET_PATH)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    server.listen()
    server.settimeout(30)
    try:
        while playing or time.time() - last_used < IDLE_SECONDS:
            try:
                conn, _ = server.accept()
            except socket.timeout:
                continue
            handle(conn)
    finally:
        server.close()
        os.unlink(SOCKET_PATH)


main()
