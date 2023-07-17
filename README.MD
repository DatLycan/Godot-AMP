
# <img src="https://raw.githubusercontent.com/DatLycan/AMP/main/icon.svg" height="26" /> AMP (Adaptive Music Player)

Create adaptive music systems in your game using the `AdaptiveMusicPlayer` and `AudioStemPlayer`.
> Only compatible with **Godot 4.x**

## Features

- Easily create adaptive music systems in your Godot game.
- Dynamically change music properties like BPM, time signature, etc., through the inspector.
- Add or remove song stems from the track during runtime.
- Use `StemPlaybackPreset` to define how each stem should be played.

## Nodes

### AdaptiveMusicPlayer

The `AdaptiveMusicPlayer` node extends Godot's `AnimationPlayer` node and provides a way to play adaptive Music. 
It holds values that can be changed in the inspector that correspond to song data.

### AudioStemPlayer

The `AudioStemPlayer` node extends Godot's `AudioStreamPlayer` node and is designed to be used alongside the `AdaptiveMusicPlayer`.  
An `AudioStemPlayer` represents a different stem (instrument, track, etc.) of your song. 
It holds instructions for the `AdaptiveMusicPlayer` for how a stem should be played and what should be played.

## Installation

1. Download the AMP plugin from [here](https://github.com/DatLycan/AMP/releases).
 
2. Place the plugin directory inside the "addons" folder of your Godot project.
 
3. Enable the plugin in your project by going to "Project Settings" > "Plugins" and activate AMP.

 
**or**

1. Install directly from the Godot Asset Library
 
2. Enable the plugin in your project by going to "Project Settings" > "Plugins" and activate AMP.

## Usage

1. Add the `AdaptiveMusicPlayer` node to your scene and configure its properties in the inspector, such as BPM, time signature, and measure count.
 
2. Add one or more `AudioStemPlayer` nodes as children of the `AdaptiveMusicPlayer`. 
 
3. Customize the `AudioStemPlayer` properties and assign a unique identifier to each stem.
 
4. In your script, you can dynamically add or remove stems from the `AdaptiveMusicPlayer` using the `add(identifier)` and `remove(identifier)` methods, respectively.

 
```gdscript
# Example usage of adding stems with identifiers
var amp = get_node("AdaptiveMusicPlayer")
amp.add("stem_one_identifier")
amp.add("stem_two_identifier")

# You can also use group identifiers to add multiple stems at once
amp.add("Group/group_identifier")
```

> You can also use `StemPlaybackPreset` to define how each stem should be played and assign it to the corresponding `AudioStemPlayer` node.


## License

This plugin is released under the [MIT License](LICENSE.txt).
