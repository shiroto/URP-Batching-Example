
# URP Batching Example
This is a minimal example of how to batch 2D sprites in a 3D scene with shadows using GPU Instancing. All you need is in Content/SampleScene.

## What does this do?
Render an arbitrary amount of sprites in 1 draw call with 3D shadows.

## How can this be extended?
The shader is very simple and only renders a single sprite. By using a sprite atlas and defining a buffer for texture coordinates, you could draw any number of sprites in the same draw call.

## Support
If you found this helpful you can
[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://buymeacoffee.com/marcoknietzsch)