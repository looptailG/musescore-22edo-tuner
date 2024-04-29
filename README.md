# 22EDO Tuner
A Musescore plugin for tuning scores to [22EDO](https://en.xen.wiki/w/22edo).


## Features
This plugin can be used to tune the whole score, or only a portion of it, to 22EDO,

### Accidentals

This plugin is compatible with the [Ups and Downs Notation](https://en.xen.wiki/w/22edo#Ups_and_Downs_Notation), more specifically with its [variant](https://en.xen.wiki/w/Alternative_symbols_for_ups_and_downs_notation#Sharp-3) that combines the arrows with the accidentals.  For example, a chromatic scale between `C` and `D` would be written as:

![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/baf955eb-6bee-4f99-80e2-a97f7f19d70e)

See [here](https://github.com/looptailG/musescore-22edo-tuner/wiki/Supported-Accidentals) for a list of every supported accidental.

This plugin remembers which accidental is applied to any given note, and will automatically apply the correct tuning offset to the following notes within the same measure.  This is also true for microtonal accidentals, for which this is usually not automatically done in Musescore.  A limitation of this is that the plugin only checks for accidentals for each voice individually, so if there are multiple voices with microtonal accidentals, it might be necessary to add an extra accidental for the first modified note in each voice.  This extra accidental can be safely made invisible, as that won't affect the plugin, as in the following example:

![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/7f5c20c8-6a68-441a-8294-45654d0678b0)

### Key Signatures

This plugin supports custom key signatures.  If the custom key signatures only contain standard accidentals, no extra action is required other than inserting the custom key signaturs into the score.

If the key signature contains microtonal accidentals, then it is necessary to also add a text (`System Text` for a regular key signature, or `Staff Text` for a local key signature) to inform the plugin about the accidentals present in the key signature.  This text has to be formatted as `X.X.X.X.X.X.X`, where `X` are the accidental applied to each note, arranged according to the circle of fifths: `F.C.G.D.A.E.B`.  These accidentals are written using ASCII characters only in the following way:

| Accidental | Text |
| :--------: | :--: |
| ![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/decf7f19-9781-4eaf-8ba1-fc5e0e800935) | `vbb` |
| ![doubleFlat](https://github.com/looptailG/musescore-31edo-tuner/assets/99362337/aed40ea1-31b3-4ce8-97a3-c737ec7dc51c) | `bb` |
| ![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/daad1af2-6a2c-4b10-9f03-98859544f15f) | `^bb` |
| ![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/6d9233ef-7a94-457f-bd70-5874868417a7) | `vb` |
| ![flat](https://github.com/looptailG/musescore-31edo-tuner/assets/99362337/5fe008de-b58c-4ad4-bec7-51449c2050f4) | `b` |
| ![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/03f057c6-de5d-410d-ab16-c4a3017b76f4) | `^b` |
| ![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/ad058fc6-47a8-4869-84b0-15ab08024798) | `vh` |
| ![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/c34427a9-1906-4849-93fa-f68e8ab41927) | `^h` |
| ![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/a6f765af-29d3-4fc2-bad2-b69a418fce46) | `v#` |
| ![sharp](https://github.com/looptailG/musescore-31edo-tuner/assets/99362337/8d63ed6d-6495-4f73-a4f5-2c2dde707008) | `#` |
| ![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/bd1a9a12-56dc-4d79-bb8c-bb2f16a31a6a) | `^#` |
| ![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/431efcd1-2c59-4904-8cc9-658b3905b57c) | `vx` |
| ![doubleSharp](https://github.com/looptailG/musescore-31edo-tuner/assets/99362337/83bbb0e3-00e3-4ed6-b57d-ac679d757401) | `x` |
| ![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/415e1c1d-39b7-4295-92be-ff3391dcb1ea) | `^x` |

If a note does not have an accidental in the custom key signature, you can leave the text for that note empty.

The text describing the custom key signature can be safely made invisible, as that won't affect the plugin, as in the following example:

![image](https://github.com/looptailG/musescore-22edo-tuner/assets/99362337/dc6d7dbb-0295-46a1-9a7d-564d35ae03e2)


## Usage
- If the score contains transposing instruments, ensure that the score is being displayed at concert pitch.  If it's not, the notes of transposing instruments will not be tuned correctly.
- If you want to tune only a portion of the score, select it before running the plugin.  If nothing is selected, the entire score will be tuned.
- Launch the plugin:
  - Musescore3: <code>Plugins</code> → <code>Tuner</code> → <code>22EDO</code>
  - Musescore4: <code>Plugins</code> → <code>Playback</code> → <code>22EDO Tuner</code>

If the score contains transposing instruments, you can safely turn off concert pitch after running the plugin, as the tuning of the notes will not be affected.

See [here](https://github.com/looptailG/musescore-22edo-tuner/wiki/Known-Issues#incorrect-handling-of-microtonal-accidental-for-transposing-instruments) for a known issue regarding transposing instruments.


## Installing
### Musescore3
- Download the file <code>22edo_tuner_x.y.z.zip</code>, where <code>x.y.z</code> is the version of the plugin.  You can find the latest version [here](https://github.com/looptailG/musescore-22edo-tuner/releases/latest).
- Extract the file `22EdoTuner.qml`, and move it to Musescore's plugin folder.
- Follow the steps listed [here](https://musescore.org/en/handbook/3/plugins#enable-disable) to enable the plugin.

### Musescore4
- Download the file <code>22edo_tuner_x.y.z.zip</code>, where <code>x.y.z</code> is the version of the plugin.  You can find the latest version [here](https://github.com/looptailG/musescore-22edo-tuner/releases/latest).
- Extract the folder `22edo_tuner` and move it to Musescore's plugin folder.
- Follow the steps listed [here](https://musescore.org/en/handbook/4/plugins#enable-disable) to enable the plugin.
