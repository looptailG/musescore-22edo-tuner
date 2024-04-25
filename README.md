# 22EDO Tuner
A Musescore plugin for tuning scores to [22EDO](https://en.xen.wiki/w/22edo).

## Features
This plugin can be used to tune the whole score, or only a portion of it, to 22EDO,

It's compatible with the [Ups and Downs Notation](https://en.xen.wiki/w/22edo#Ups_and_Downs_Notation), more specifically with its [variant](https://en.xen.wiki/w/Alternative_symbols_for_ups_and_downs_notation#Sharp-3) that combines the arrows with the accidentals.  For example, a chromatic scale between `C` and `D` would be written as:

![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/baf955eb-6bee-4f99-80e2-a97f7f19d70e)

## Usage
- If the score contains transposing instruments, ensure that the score is being displayed at concert pitch.  If it's not, the notes of transposing instruments will not be tuned correctly.
- If you want to tune only a portion of the score, select it before running the plugin.  If nothing is selected, the entire score will be tuned.
- Launch the plugin:
  - Musescore3: <code>Plugins</code> → <code>Tuner</code> → <code>22EDO</code>
  - Musescore4: <code>Plugins</code> → <code>Playback</code> → <code>22EDO Tuner</code>

If the score contains transposing instruments, you can safely turn off concert pitch after running the plugin, as the tuning of the notes will not be affected.

## Installing
### Musescore3
- Download the file <code>22edo_tuner_x.y.z.zip</code>, where <code>x.y.z</code> is the version of the plugin.  You can find the latest version [here](https://github.com/looptailG/musescore-22edo-tuner/releases/latest).
- Extract the file `22EdoTuner.qml`, and move it to Musescore's plugin folder.
- Follow the steps listed [here](https://musescore.org/en/handbook/3/plugins#enable-disable) to enable the plugin.

### Musescore4
- Download the file <code>22edo_tuner_x.y.z.zip</code>, where <code>x.y.z</code> is the version of the plugin.  You can find the latest version [here](https://github.com/looptailG/musescore-22edo-tuner/releases/latest).
- Extract the folder `22edo_tuner` and move it to Musescore's plugin folder.
- Follow the steps listed [here](https://musescore.org/en/handbook/4/plugins#enable-disable) to enable the plugin.
