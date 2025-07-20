# VHS Effect Shader for Unity

A custom Unity shader that recreates the nostalgic visual artifacts of VHS recordings, including scanlines, color bleeding, noise, distortion, and chromatic aberration effects.

https://github.com/user-attachments/assets/dcb8cb12-ca31-49be-b1ba-47d32e8e15a1


## Features

- **Authentic VHS Artifacts**: Scanlines, color bleeding, static noise, and horizontal distortion
- **Customizable Parameters**: Fine-tune intensity, frequency, and speed of all effects
- **Real-time Animation**: Time-based effects for dynamic VHS-style degradation
- **Easy Integration**: Simple post-processing script for immediate use
- **Performance Optimized**: Efficient shader implementation suitable for real-time applications


## Quick Start
1. Grab the setup for Quad and Canvas/Image from TvSetupScene.unity

2. Customize the Effect
   - Select the `VHSMaterial` in the Project window
   - Adjust parameters in the Inspector to achieve your desired look


## Shader Parameters

| Parameter | Range | Description |
|-----------|-------|-------------|
| `_ScanlineIntensity` | 0-4 | Controls the strength of horizontal scanlines |
| `_NoiseIntensity` | 0-2 | Controls the amount of static/noise overlay |
| `_ColorBleed` | 0-10 | Controls chromatic aberration and color channel offset |
| `_Distortion` | 0-10 | Controls horizontal wobble/distortion intensity |
| `_WobbleFrequency` | 0-110 | Controls the frequency of the wobble effect |
| `_WobbleSpeed` | 0-20 | Controls the speed of animated distortion |
| `_ScanlineCount` | Float | Number of scanlines across the screen |


## Project Structure

```
Assets/VHS/
├── Shaders/
│   └── VHSEffect.shader          # Main VHS effect shader
├── Scripts/
│   └── VHSPostProcess.cs         # Post-processing component
├── Materials/
│   └── VHSMaterial.mat           # Pre-configured material
├── Textures/
│   └── VHSRenderTexture.renderTexture
└── Scenes/
    └── TvSetupScene.unity        # Demo scene
```


## Usage Examples

### Basic Post-Processing Setup

```csharp
using UnityEngine;
using VHS.Scripts;

public class VHSController : MonoBehaviour
{
    public Material vhsMaterial;
    
    void Start()
    {
        var postProcess = Camera.main.gameObject.AddComponent<VhsPostProcess>();
        postProcess._vhsMaterial = vhsMaterial;
    }
}
```


### Runtime Parameter Control

```csharp
public class VHSEffectController : MonoBehaviour
{
    public Material vhsMaterial;
    
    private void Update()
    {
        // Animate noise intensity over time
        float noise = Mathf.Sin(Time.time) * 0.5f + 0.5f;
        vhsMaterial.SetFloat("_NoiseIntensity", noise);
        
        // Control distortion with input
        if (Input.GetKey(KeyCode.Space))
        {
            vhsMaterial.SetFloat("_Distortion", 2.0f);
        }
    }
}
```


## Technical Details

Built for Unity's built-in render pipeline


## Implementation Notes

The shader implements several key VHS characteristics:

1. **Scanlines**: Sine wave-based horizontal lines with adjustable intensity
2. **Color Grading**: Subtle desaturation and blue tint typical of VHS
3. **Chromatic Aberration**: RGB channel separation for color bleeding effect
4. **Noise**: Time-based random static overlay
5. **Distortion**: Animated horizontal wobble using sine waves


## Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
