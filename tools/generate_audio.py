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


def percussion(buf, start, kind, gain, seed, wrap=False):
    """Short synthesized drum voices; no samples or recordings."""
    duration = .18 if kind == 'kick' else (.11 if kind == 'clap' else .055)
    rng = random.Random(seed)
    for i in range(int(duration * RATE)):
        t = i / RATE
        index = int(start * RATE) + i
        if wrap:
            index %= len(buf)
        if not 0 <= index < len(buf):
            continue
        if kind == 'kick':
            frequency = 150 * math.exp(-t * 20) + 42
            envelope = math.exp(-t * 17)
            value = math.sin(TAU * frequency * t) * envelope
        elif kind == 'clap':
            envelope = (1 - t / duration) ** 2
            value = rng.uniform(-1, 1) * envelope * (.8 + .2 * math.sin(TAU * 70 * t))
        else:
            envelope = (1 - t / duration) ** 3
            value = rng.uniform(-1, 1) * envelope
        buf[index] += value * gain


def theme():
    # Bright, playful 120 BPM pulse: active enough for a rescue mission without
    # becoming a combat soundtrack. Sixteen bars resolve cleanly into the loop.
    beat = 60 / 120
    length = 16 * 4 * beat
    buf = array('f', [0]) * int(length * RATE)
    # Original C-major call-and-response with a bouncy major-sixth motif.
    melody = [
        [76, 79, 81, 79, 76, 79, 83, 81], [79, 76, 74, 76, 72, 74, 76, None],
        [77, 81, 84, 81, 79, 77, 76, 74], [74, 76, 79, 81, 79, 76, 74, None],
        [76, 79, 81, 79, 76, 79, 83, 81], [84, 81, 79, 76, 74, 76, 79, None],
        [77, 81, 79, 77, 74, 77, 81, 79], [76, 74, 72, 74, 76, 72, 72, None],
        [79, 81, 84, 81, 79, 76, 79, 81], [83, 81, 79, 76, 74, 76, 79, None],
        [76, 79, 83, 81, 79, 76, 74, 76], [74, 72, 69, 72, 74, 76, 79, None],
        [77, 81, 84, 81, 79, 77, 76, 74], [79, 81, 79, 76, 74, 76, 79, 81],
        [83, 81, 79, 76, 74, 76, 79, 74], [72, 76, 79, 76, 72, 72, None, None],
    ]
    chords = [(48, 55, 60, 64), (45, 52, 57, 60), (41, 48, 53, 57), (43, 50, 55, 59)]
    for bar in range(16):
        chord = chords[(bar // 2) % 4]
        base = bar * 4 * beat
        # A buoyant bass and off-beat plucks create forward motion.
        for pulse in [0, 3, 4, 6]:
            tone(buf, base + pulse * beat / 2, .42, chord[0] + (12 if pulse == 6 else 0), .105, 'bass', wrap=True)
        for pulse in range(8):
            tone(buf, base + pulse * beat / 2 + beat * .08, .30, chord[1 + pulse % 3] + 12, .072, 'pluck', wrap=True)
            percussion(buf, base + pulse * beat / 2, 'hat', .033, bar * 19 + pulse, wrap=True)
        for pulse in [0, 2, 4, 6]:
            percussion(buf, base + pulse * beat / 2, 'kick', .19, bar * 23 + pulse, wrap=True)
        for pulse in [2, 6]:
            percussion(buf, base + pulse * beat / 2, 'clap', .075, bar * 29 + pulse, wrap=True)
        for pulse, pitch in enumerate(melody[bar]):
            if pitch is not None:
                tone(buf, base + pulse * beat / 2, .30 if pulse % 4 != 2 else .42, pitch, .13, 'pluck', wrap=True)
                if pulse in [0, 4]:
                    tone(buf, base + pulse * beat / 2, .42, pitch - 12, .045, 'flute', wrap=True)
    # Circular short echo retains an energetic tail at the boundary.
    dry = array('f', buf)
    delay = int(.15 * RATE)
    for i in range(len(buf)):
        buf[i] += dry[(i - delay) % len(buf)] * .11
    # Tiny boundary fade avoids discontinuity; no long silence between phrases.
    for i in range(220):
        buf[i] *= i / 220
        buf[-1-i] *= i / 220
    write('harbor_theme', buf, True)


def location_theme(name, chords, melody, accent):
    """A distinct but equally upbeat location loop using the shared original voices."""
    beat = 60 / 120
    buf = array('f', [0]) * int(16 * 4 * beat * RATE)
    for bar in range(16):
        chord = chords[bar % len(chords)]
        base = bar * 4 * beat
        for pulse in [0, 3, 4, 6]:
            tone(buf, base + pulse * beat / 2, .38, chord[0] + (12 if pulse == 6 else 0), .10, 'bass', wrap=True)
        for pulse in range(8):
            tone(buf, base + pulse * beat / 2 + beat * .08, .25, chord[1 + pulse % 3] + 12, .06, 'pluck', wrap=True)
            percussion(buf, base + pulse * beat / 2, 'hat', .028, accent + bar * 17 + pulse, wrap=True)
        for pulse in [0, 2, 4, 6]:
            percussion(buf, base + pulse * beat / 2, 'kick', .16, accent + bar * 23 + pulse, wrap=True)
        for pulse in [2, 6]:
            percussion(buf, base + pulse * beat / 2, 'clap', .060, accent + bar * 29 + pulse, wrap=True)
        phrase = melody[bar % len(melody)]
        for pulse, pitch in enumerate(phrase):
            if pitch is not None:
                tone(buf, base + pulse * beat / 2, .27, pitch, .115, 'pluck', wrap=True)
                if pulse in [1, 5]:
                    tone(buf, base + pulse * beat / 2, .34, pitch - 12, .04, 'flute', wrap=True)
    dry = array('f', buf)
    delay = int(.13 * RATE)
    for i in range(len(buf)):
        buf[i] += dry[(i - delay) % len(buf)] * .10
    for i in range(220):
        buf[i] *= i / 220
        buf[-1-i] *= i / 220
    write(name, buf, True)


def old_town_theme():
    # D minor night patrol: playful but more mysterious than the coastal rescue beat.
    location_theme('old_town_theme',
        [(50, 57, 62, 65), (46, 53, 58, 62), (41, 48, 53, 57), (45, 52, 57, 60)],
        [[74, 77, 81, 77, 74, 76, 77, None], [72, 76, 79, 76, 72, 74, 76, None],
         [69, 72, 77, 74, 72, 69, 72, 74], [71, 74, 77, 74, 71, 69, 69, None]], 101)


def floodworks_theme():
    # E major workshop pulse: brighter, mechanical and quick for the optional trials.
    location_theme('floodworks_theme',
        [(52, 59, 64, 68), (49, 56, 61, 64), (45, 52, 57, 61), (47, 54, 59, 63)],
        [[76, 80, 83, 80, 76, 78, 80, None], [73, 76, 81, 76, 73, 76, 78, None],
         [81, 83, 85, 83, 81, 80, 78, 76], [78, 80, 83, 80, 78, 76, 76, None]], 211)


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
    old_town_theme()
    floodworks_theme()
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
    print('Wrote original 32-second loop and 12 effects to', OUT)
