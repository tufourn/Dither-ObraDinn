# Obra Dinn style dithering
This is my attempt at recreating Obra Dinn dithering effect in Godot. I also wrote [a blog post](https://tufourn.com/posts/obra-dinn-style-dithering/) about it.

The files related to the effect are located in `Dither/`. `post_process.gd` and `dither.glsl` are for the compositor effect, and `create_cubemap_image.gd` is used to generate the cubemap face.

This repo also contains a sample project to demonstrate the dithering effect.
