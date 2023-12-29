###### wait for it...

<p align="center"><img src="assets/melonsmasks.gif"/></p>
Melon's Masks is a modern, render-target based masking system that is fast, powerful and excrutiatingly easy to use. Plus it works in 3D2D, and on 3D objects!

# Installation
1. Download cl_melons_masks.lua
2. Load it on the client
3. Either use the files return, or modify the file to put the `masks` local into a global (`myaddon.masks = masks` below the definition)

# API
### Enumerations
> `masks.KIND_CUT`  
> Tells the mask to cut the given "source" out

> `masks.KIND_STAMP`  
> Tells the mask to "stamp out" the source, the opposite of CUT

### Functions
> `masks.Start()`  
> Starts the mask render, past this point is what is being cut

> `masks.Source()`  
> Stops the render of the thing being cut, and starts the render of the thing doing the cutting

> `masks.And(masks.KIND_)`  
> Stops the render of the thing doing the cutting, applies it with the given kind, and starts it back up
> > Note:  
> > This MUST be called after `masks.Source`, just like `masks.End`  
> > You MUST provide a kind, unlike `masks.End`

> `masks.End(masks.KIND_?)`  
> Stops the render of the thing doing the cutting, applies it according to the kind, and renders the finished mask  
> Kind defaults to `masks.KIND_CUT`

> `masks.EndToTexture(ITexture, masks.KIND_?)`
> Identical to `masks.End`, except renders the mask to a texture (does not clear the texture before hand!)

# Common Issues
- Remember that this is pushing render targets, you need to do any rendertarget processing before the mask renders.

# Basic example
This shows how to render a gradient rounded box that looks like the following:  

<img src="https://i.imgur.com/HppIXsV.png"/>

```lua
---
--- First, we start the mask
---
masks.Start()
    ---
    --- Now, we draw whatever we want to be cutting
    --- This can be a gradient, an image, anything you want
    --- For this example we'll use a blue rectangle with a red gradient coming from the top right
    --- 
    surface.SetDrawColor(255, 0, 0)
    surface.DrawRect(50, 50, 150, 150)
    surface.SetDrawColor(0, 0, 255)
    surface.SetMaterial(melon.Material("vgui/gradient-r"))
    surface.DrawTexturedRectRotated(50 + (150 / 2), 50 + (150 / 2), 300, 300, 45)

---
--- Next, we start what we call the "Source"
--- This is what is doing the cutting
--- For example, it could be text, a rounded box, anything you want
--- For this example it will be a rounded box
---
masks.Source()
    draw.RoundedBox(20, 50, 50, 150, 150, color_white)

---
--- Finally we end the mask render, and you should see your rounded box!
---
masks.End()
```

# Gradient Text Example
This shows how to render text that is displayed as a gradient

<img src="https://i.imgur.com/gsFm6eN.png"/>

```lua
---
--- First, we start the mask and do what we did before
--- which is draw a red/blue gradient
---
masks.Start()
    surface.SetDrawColor(255, 0, 0)
    surface.DrawRect(50, 50, 150, 150)
    surface.SetDrawColor(0, 0, 255)
    surface.SetMaterial(melon.Material("vgui/gradient-r"))
    surface.DrawTexturedRectRotated(50 + (150 / 2), 50 + (150 / 2), 300, 300, 45)

masks.Source()
    ---
    --- Now we draw the text and end
    --- Notice how this is exactly the same as the example above
    --- These two examples operate on exactly the same principles
    ---
    draw.Text({
        text = "Some Text",
        pos = {50 + (150 / 2), 50 + (150 / 2)},
        xalign = 1,
        yalign = 1,
        font = melon.Font(50, "Poppins"),
    })

masks.End()
```

# Gradient Rounded Box Border
This shows how to render the border of a rounded box being a gradient

<img src="https://i.imgur.com/MUGkOTC.png"/>

```lua
---
--- First, we start the mask and do what we did before
---
masks.Start()
    surface.SetDrawColor(255, 0, 0)
    surface.DrawRect(50, 50, 150, 150)
    surface.SetDrawColor(0, 0, 255)
    surface.SetMaterial(melon.Material("vgui/gradient-r"))
    surface.DrawTexturedRectRotated(50 + (150 / 2), 50 + (150 / 2), 300, 300, 45)

masks.Source()
    ---
    --- Now we draw the rounded box like we did before
    --- This cuts a rounded box out of the gradient
    ---
    draw.RoundedBox(20, 50, 50, 150, 150, color_white)

---
--- Next, we do something new!
--- We use the `And` function
--- This allows you to overlay masks
---
--- Youll also notice the argument given
--- This is an enum that determines which kind of mask is being used
---
--- The default is `masks.KIND_CUT` which cuts the source out of the mask
--- That is what were doing here, were cutting the rounded box drawn above
--- out of the gradient mask
--- 
masks.And(masks.KIND_CUT)
    ---
    --- Next we draw the inner box to cut
    ---
    draw.RoundedBox(20 - 5, 50 + 10, 50 + 10, 150 - 20, 150 - 20, color_white)

---
--- Now, we end the mask render
--- But we give the argument `masks.KIND_STAMP` to the End function
---
--- This is the opposite of `masks.KIND_CUT`
--- This "stamps" a shape out of the mask
---
masks.End(masks.KIND_STAMP)

---
--- As a rundown, this is the order of operations
---
--- 1. Start the mask
--- 2. Render the gradient
--- 3. Start the "Source"
--- 4. Render the larger, border rounded box
--- 5. Cut it out of the gradient mask with `And`, and continue the render
--- 6. Render the smaller, inner rounded box
--- 7. "Stamp" the smaller box out of the box drawn in step 5
--- 8. Finish the render
---
--- If youre confused, just play around with it
---
```

# Transparent Masks
Masks can be transparent, meaning masks get cut depending on transparency.

<img src="https://i.imgur.com/iUpKy2V.png"/>

```lua
---
--- First, we start the mask and render the red/blue gradient, like all the other examples
---
masks.Start()
    surface.SetDrawColor(255, 0, 0)
    surface.DrawRect(50, 50, 150, 150)

    surface.SetDrawColor(0, 0, 255)
    surface.SetMaterial(melon.Material("vgui/gradient-r"))
    surface.DrawTexturedRectRotated(50 + (150 / 2), 50 + (150 / 2), 300, 300, 45)

masks.Source()
    ---
    --- Now we draw the rounded box like we did before
    --- But we use a color with an Alpha on it
    --- Note that colors need to be cached
    --- Best practice is using `surface.SetAlphaMultiplier`, but this is an example
    ---
    draw.RoundedBox(20, 50, 50, 150, 150, Color(255, 255, 255, 100))
    draw.RoundedBox(20, 50 + 20, 50 + 20, 150 - 40, 150 - 40, Color(255, 255, 255, 100))

---
--- And finish the mask
---
masks.End()
```

