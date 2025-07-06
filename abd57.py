# Copyright © 2025 Yogesh R. Chauhan
# Project Synapse – Brainwave Decoder
# This project is licensed for personal and educational use only.
# Commercial use, resale, or modification for profit is strictly prohibited.
# Unauthorized use will result in legal action and takedown notices.

# === Imports ===
import os, time, socket, json
import numpy as np
import pandas as pd
from datetime import datetime
from scipy.signal import butter, filtfilt, iirnotch
from joblib import dump, load as joblib_load
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import pairwise_distances
from tensorflow.keras.models import Sequential, load_model
from tensorflow.keras.layers import LSTM, Dense, Dropout, Bidirectional, Conv1D, MaxPooling1D
from tensorflow.keras.utils import to_categorical
from tensorflow.keras.optimizers import Adam

# === Constants ===
LETTERS = list("abcdefghijklmnopqrstuvwxyz")
DATA_DIR = "eeg_letters"
CUSTOM_DIR = os.path.join(DATA_DIR, "custom_words")
LABELS_FILE = "labels.json"
MODEL_RF = "alphabet_model.joblib"
MODEL_LSTM = "brain_model.h5"
HISTORY_FILE = "last_letters.txt"
FS_FILE = "fs.txt"
DURATION = 2
REPEATS = 5
model_type = "lstm"
lstm_model = None

# === Setup ===
os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(CUSTOM_DIR, exist_ok=True)
if not os.path.exists(HISTORY_FILE): open(HISTORY_FILE, "w").close()

# === Utils ===
def recv_byte(sock):
    try: return sock.recv(1)[0] & 0x7F
    except: return None

def measure_fs(seconds=2):
    try:
        sock = socket.create_connection(("127.0.0.1", 8080), timeout=2)
        start, samples = time.time(), []
        while time.time() - start < seconds:
            val = recv_byte(sock)
            if val is not None: samples.append(val)
        sock.close()
        rate = len(samples) // seconds
        if rate < 10:
            print("[!] Low sampling rate detected. Using default 250 Hz.")
            return 250
        print(f"[\u2713] Detected Sampling Rate: {rate} Hz")
        return rate
    except Exception as e:
        print(f"[!] Using default sampling rate. Error: {e}")
        return 250

def save_labels(labels):
    with open(LABELS_FILE, "w") as f:
        json.dump(labels, f)

def load_labels():
    if os.path.exists(LABELS_FILE):
        with open(LABELS_FILE) as f:
            return json.load(f)
    return []

def save_fs(fs):
    with open(FS_FILE, "w") as f:
        f.write(str(fs))

def load_fs():
    if os.path.exists(FS_FILE):
        with open(FS_FILE) as f:
            return int(f.read())
    return 250

# === Signal Processing ===
def preprocess(sig, fs):
    def notch(sig): b, a = iirnotch(50.0, 30.0, fs); return filtfilt(b, a, sig)
    def band(sig): b, a = butter(4, [1/(0.5*fs), 40/(0.5*fs)], btype='band'); return filtfilt(b, a, sig)
    def reject(sig): z = (sig - np.mean(sig)) / (np.std(sig)+1e-8); dz = np.diff(z, prepend=z[0]); return sig * (np.abs(dz)<4)
    sig = reject(band(notch(sig)))
    return (sig - np.mean(sig)) / (np.std(sig) + 1e-8)

def extract(sig, fs):
    freqs = np.fft.rfftfreq(len(sig), d=1/fs)
    fft_vals = np.abs(np.fft.rfft(sig))
    def bp(lo, hi): idx = (freqs >= lo) & (freqs <= hi); return np.mean(fft_vals[idx] ** 2) if any(idx) else 0
    return [bp(0.5,4), bp(4,8), bp(8,13), bp(13,30), bp(30,40), np.mean(sig), np.std(sig)]

# === Recording ===
def record_letter_set(letters, target_dir):
    fs = measure_fs()
    expected = fs * DURATION
    try:
        sock = socket.create_connection(("127.0.0.1", 8080), timeout=2)
    except:
        print("[!] Could not connect to EEG stream.")
        return

    for l in letters:
        print(f"[\U0001f3af] Now recording: {l.upper()}")
        proceed = input(f"\n\u2192 Think '{l.upper()}' and press ENTER, 's' to skip, or 'sa' to skip all: ").strip().lower()
        if proceed == "sa":
            sock.close()
            return
        if proceed == "s": continue

        subdir = os.path.join(target_dir, l)
        os.makedirs(subdir, exist_ok=True)
        for i in range(REPEATS):
            print(f"  \u25b6 Recording {i+1}/{REPEATS}...")
            start, samples = time.time(), []
            while time.time() - start < DURATION:
                val = recv_byte(sock)
                if val is not None: samples.append(val)
            samples = samples[:expected]
            if len(samples) < expected * 0.8:
                print(f"  [!] Skipped (too short: {len(samples)} samples)")
                continue
            fname = f"{l}_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{i}.csv"
            with open(os.path.join(subdir, fname), "w") as f:
                f.write("signal\n")
                f.writelines(f"{v}\n" for v in samples)
            print("     \u2714 Saved")
    sock.close()

# === Model Training ===
def train_models(path, fs):
    expected = fs * DURATION
    save_fs(fs)
    X, y = [], []
    class_dirs = sorted([d for d in os.listdir(path) if os.path.isdir(os.path.join(path, d)) and not d.startswith("custom")])
    save_labels(class_dirs)

    for i, label in enumerate(class_dirs):
        sub = os.path.join(path, label)
        for fname in os.listdir(sub):
            try:
                sig = pd.read_csv(os.path.join(sub, fname)).values.flatten()
                sig = np.pad(sig, (0, max(0, expected - len(sig))))[:expected]
                sig = preprocess(sig, fs)
                X.append(sig)
                y.append(i)
            except Exception as e:
                print(f"[!] Skipped {fname}: {e}")
                continue

    if not X:
        print("[!] No training data found. Skipping model training.")
        return

    X = np.array(X).reshape((-1, expected, 1))
    X_feat = np.array([extract(x.flatten(), fs) for x in X])
    rf = RandomForestClassifier(n_estimators=300)
    rf.fit(X_feat, y)
    dump(rf, MODEL_RF)
    print("[\u2713] RF model trained.")

    y_cat = to_categorical(y, num_classes=len(class_dirs))
    model = Sequential([
        Conv1D(32, 5, activation='relu', input_shape=(expected, 1)),
        MaxPooling1D(2),
        Dropout(0.3),
        Bidirectional(LSTM(64, return_sequences=True)),
        LSTM(32),
        Dense(64, activation='relu'),
        Dropout(0.3),
        Dense(len(class_dirs), activation='softmax')
    ])
    model.compile(loss='categorical_crossentropy', optimizer=Adam(1e-3), metrics=['accuracy'])
    model.fit(X, y_cat, epochs=50, batch_size=8, validation_split=0.2)
    model.save(MODEL_LSTM)
    print("[\u2713] LSTM model trained.")
    print(f"[\U0001f9e0] Trained on: {', '.join(class_dirs)}")

# === Real-Time Prediction ===
def predict_realtime():
    global lstm_model
    fs = load_fs()
    expected = fs * DURATION
    try:
        sock = socket.create_connection(("127.0.0.1", 8080), timeout=2)
    except:
        print("[!] EEG stream error")
        return

    print("\u2192 Think now (2s)...")
    start, sig = time.time(), []
    while time.time() - start < DURATION:
        val = recv_byte(sock)
        if val is not None: sig.append(val)
    sock.close()

    sig = np.array(sig)
    sig = np.pad(sig, (0, max(0, expected - len(sig))))[:expected]
    sig = preprocess(sig, fs)

    labels = load_labels()
    if not labels:
        print("[!] No label mapping found.")
        return

    if model_type == "rf":
        model = joblib_load(MODEL_RF)
        feat = np.array(extract(sig, fs)).reshape(1, -1)
        idx = model.predict(feat)[0]
        confidence = 1.0
    else:
        if lstm_model is None:
            lstm_model = load_model(MODEL_LSTM)
        x = sig.reshape((1, expected, 1))
        probs = lstm_model.predict(x)
        idx = int(np.argmax(probs))
        confidence = float(probs[0][idx])

    if idx >= len(labels):
        print("[!] Prediction index out of bounds.")
        return

    prediction = labels[idx]
    print(f"\u2192 Detected: {prediction.upper()} (Confidence: {confidence:.2f})")
    with open(HISTORY_FILE, "a") as f:
        f.write(prediction + "\n")

# === Other Menu Options ===
def record_custom_word():
    word = input("Enter custom word/letter: ").strip().lower()
    if not word: return
    target_dir = os.path.join(CUSTOM_DIR, word)
    os.makedirs(target_dir, exist_ok=True)
    record_letter_set([word], CUSTOM_DIR)
    fs = measure_fs()
    train_models(CUSTOM_DIR, fs)

def main():
    global model_type
    while True:
        print("\n\U0001f9ec Quantum-Level EEG Decoder")
        print("[1] Record New Alphabet Samples")
        print("[2] Train from Existing Directory")
        print("[3] Predict in Real-Time")
        print(f"[4] Switch Model (Now: {model_type.upper()})")
        print("[5] Clear History")
        print("[6] Record Custom Word")
        print("[7] Discover Unique Patterns")
        print("[8] Exit")
        c = input("\nSelect option: ").strip()
        if c == "1":
            record_letter_set(LETTERS, DATA_DIR)
            fs = measure_fs()
            train_models(DATA_DIR, fs)
        elif c == "2":
            path = input("Enter dataset path: ").strip()
            if os.path.isdir(path):
                fs = measure_fs()
                train_models(path, fs)
            else:
                print("[!] Invalid path")
        elif c == "3": predict_realtime()
        elif c == "4":
            model_type = "rf" if model_type == "lstm" else "lstm"
            print(f"[\u2713] Switched to model: {model_type.upper()}")
        elif c == "5":
            open(HISTORY_FILE, "w").close()
            print("[\u2713] Cleared.")
        elif c == "6": record_custom_word()
        elif c == "7": print("[!] Pattern discovery not yet implemented.")
        elif c == "8": break

if __name__ == "__main__":
    main()



