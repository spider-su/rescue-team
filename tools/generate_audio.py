#!/usr/bin/env python3
"""Original Rescue Team score and effects, standard-library-only offline synthesis.
Run from any directory. No recordings, samples, or third-party compositions used.
"""
from array import array
import math
from pathlib import Path
import random
import wave

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / 'assets/audio'
TAU = math.tau


def note(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def tone(buf, start, duration, midi, gain, voice='pluck', wrap=False):
    frequency = note(midi)
    for i in range(int(duration * RATE)):
        t = i / RATE
        attack = min(1, t / .018)
        release = min(1, (duration - t) / .09)
        if voice == 'flute':
            env = attack * release * (.8 + .2 * math.exp(-t * 3))
            value = math.sin(TAU * frequency * t + .012 * math.sin(TAU * 4.8 * t)) + .15 * math.sin(TAU * frequency * 2 * t)
        else:
            env = attack * release * math.exp(-t * (3.8 if voice == 'pluck' else 2.2))
            value = math.sin(TAU * frequency * t) + .24 * math.sin(TAU * frequency * 2 * t) + .08 * math.sin(TAU * frequency * 3 * t)
        index = int(start * RATE) + i
        if wrap:
            index %= len(buf)
        if 0 <= index < len(buf):
            buf[index] += value * env * gain


def write(name, buf, loop=False):
    peak = max(abs(v) for v in buf) or 1
    scale = .74 / max(1, peak / .74) # conservative headroom; never hard-clip
    pcm = array('h', (round(max(-1, min(1, v * scale)) * 32767) for v in buf))
    import sys
    if sys.byteorder != 'little':
        pcm.byteswap()
    with wave.open(str(OUT / (name + '.wav')), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(pcm.tobytes())


def theme():
    beat = 60 / 96
    length = 16 * 4 * beat
    buf = array('f', [0]) * int(length * RATE)
    # Original 16-bar C-major melody over C / Am / F / G, with a resolving answer.
    melody = [
        [76, 79, 81, 79], [76, 74, 72, None], [76, 79, 83, 81], [79, 76, 74, None],
        [77, 81, 79, 77], [76, 74, 72, None], [74, 79, 77, 74], [71, 74, 79, None],
        [79, 81, 84, 83], [81, 79, 76, None], [76, 79, 81, 76], [74, 72, 69, None],
        [77, 79, 81, 79], [77, 76, 74, None], [74, 76, 79, 71], [74, 72, 72, None],
    ]
    chords = [(48, 55, 60, 64), (45, 52, 57, 60), (41, 48, 53, 57), (43, 50, 55, 59)]
    for bar in range(16):
        chord = chords[(bar // 2) % 4]
        base = bar * 4 * beat
        for pulse in range(8):
            tone(buf, base + pulse * beat / 2, .8, chord[1 + pulse % 3] + 12, .055, wrap=True)
        for pulse in [0, 2]:
            tone(buf, base + pulse * beat, 1.15, chord[0], .10, 'bass', wrap=True)
        for pulse, pitch in enumerate(melody[bar]):
            if pitch is not None:
                tone(buf, base + pulse * beat, .54 if pulse != 2 else .8, pitch, .105, 'flute', wrap=True)
    # Circular short room echo retains a continuous loop tail at the boundary.
    dry = array('f', buf)
    delay = int(.21 * RATE)
    for i in range(len(buf)):
        buf[i] += dry[(i - delay) % len(buf)] * .16
    # Tiny boundary fade avoids discontinuity; no long silence between phrases.
    for i in range(220):
        buf[i] *= i / 220
        buf[-1-i] *= i / 220
    write('harbor_theme', buf, True)


def effect(name, pitches, duration=.35, voice='pluck'):
    buf = array('f', [0]) * int(duration * RATE)
    for start, pitch, gain in pitches:
        tone(buf, start, max(.05, duration - start), pitch, gain, voice)
    write(name, buf)


def noise_effect(name, duration, base, sweep, gain, seed):
    rng = random.Random(seed)
    buf = array('f', [0]) * int(duration * RATE)
    phase = 0
    smooth = 0
    for i in range(len(buf)):
        t = i / RATE
        env = min(1, t / .008) * (1 - t / duration) ** 2
        smooth = .75 * smooth + .25 * rng.uniform(-1, 1)
        phase += TAU * (base + sweep * t / duration) / RATE
        buf[i] = env * gain * (.55 * smooth + .45 * math.sin(phase))
    write(name, buf)


if __name__ == '__main__':
    OUT.mkdir(exist_ok=True)
    theme()
    effect('select', [(0, 76, .25), (.055, 79, .2)], .20)
    effect('ui', [(0, 72, .20)], .12)
    noise_effect('step', .10, 145, -50, .21, 1)
    noise_effect('fire', .58, 900, -660, .42, 2)
    noise_effect('crate', .26, 110, -60, .48, 3)
    effect('gate', [(0, 60, .23), (.09, 67, .22), (.18, 72, .26)], .75)
    noise_effect('stun', .30, 620, 540, .35, 4)
    effect('pickup', [(0, 72, .24), (.10, 76, .24), (.20, 79, .22)], .65)
    effect('victory', [(0, 72, .24), (.13, 76, .24), (.26, 79, .24), (.43, 84, .24), (.43, 76, .12)], 1.4)
    effect('blocked', [(0, 62, .17), (.09, 60, .15)], .30)
    effect('undo', [(0, 79, .18), (.08, 76, .17), (.16, 72, .16)], .40)
    effect('restart', [(0, 67, .18), (.08, 72, .18)], .32)
    print('Wrote original 40-second loop and 12 effects to', OUT)
