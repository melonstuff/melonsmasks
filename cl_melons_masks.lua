---
--- Melon's Masks
--- https://github.com/melonstuff/melonsmasks/
--- Licensed under MIT
---

----
---@module
---@name masks
---@realm CLIENT
----
---- An alternative to stencils that samples a texture
---- For reference:
----  The destination is what is being masked, so a multi stage gradient or some other complex stuff
----  The source is the text, or the thing with alpha
----
local masks = {}
--- youraddon.masks = masks

masks.source = {}
masks.dest   = {}

masks.source.rt = GetRenderTargetEx("MelonMasks_Source",      ScrW(), ScrH(), RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(1, 256), 0, IMAGE_FORMAT_BGRA8888)
masks.dest.rt   = GetRenderTargetEx("MelonMasks_Destination", ScrW(), ScrH(), RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(1, 256), 0, IMAGE_FORMAT_BGRA8888)

masks.source.mat = CreateMaterial("MelonMasks_Source", "UnlitGeneric", {
    ["$basetexture"] = masks.source.rt:GetName(),
    ["$translucent"] = "1",
    ["$vertexalpha"] = "1",
    ["$vertexcolor"] = "1",
})
masks.dest.mat    = CreateMaterial("MelonMasks_Destination", "UnlitGeneric", {
    ["$basetexture"] = masks.dest.rt:GetName(),
    ["$translucent"] = "1",
    ["$vertexalpha"] = "1",
    ["$vertexcolor"] = "1",
})


----
---@enumeration
---@name masks.KIND
----
---@enum (CUT)   Cuts the source out of the destination
---@enum (STAMP) Cuts the destination out of the source
----
---- Determines the type of mask were rendering
----
masks.KIND_CUT   = {BLEND_ZERO, BLEND_SRC_ALPHA, BLENDFUNC_ADD}
masks.KIND_STAMP = {BLEND_ZERO, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD}

----
---@name masks.Start
----
----
---- Starts the mask destination render
---- Whats between this and the `masks.Source` call is the destination
---- See the module declaration for an explaination
----
function masks.Start()
    render.PushRenderTarget(masks.dest.rt)
    render.Clear(0, 0, 0, 0, true, true)
    cam.Start2D()
end

----
---@name masks.Source
----
---- Stops the destination render
---- Whats between this and the `masks.End` call is the source
---- See the module declaration for an explaination
----
function masks.Source()
    cam.End2D()
    render.PopRenderTarget()

    render.PushRenderTarget(masks.source.rt)
    render.Clear(0, 0, 0, 0, true, true)
    cam.Start2D()
end

----
---@name masks.And
----
---@arg (kind: masks.KIND_) The kind of mask this is, remember this is not a number enum
----
---- Renders the given kind of mask and continues the mask render
---- This can be used to layer masks 
---- This must be called post [masks.Source]
---- You still need to call End
----
function masks.And(kind)
    cam.End2D()
    render.PopRenderTarget()

    render.PushRenderTarget(masks.dest.rt)
    cam.Start2D()
        render.OverrideBlend(true,
            kind[1], kind[2], kind[3]
        )
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(masks.source.mat)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        render.OverrideBlend(false)
    masks.Source()
end

----
---@name masks.End
----
---@arg (kind: masks.KIND_) The kind of mask this is, remember this is not a number enum
---@arg (x:         number) The x coordinate to render the rectangle at, defaults to 0
---@arg (y:         number) The y coordinate to render the rectangle at, defaults to 0
---@arg (w:         number) The width of the rectangle to render
---@arg (h:         number) The height of the rectangle to render
----
---- Stops the source render and renders everything finally
---- See the module declaration for an explaination
----
function masks.End(kind, x, y, w, h)
    kind = kind or masks.KIND_CUT

    cam.End2D()
    render.PopRenderTarget()

    render.PushRenderTarget(masks.dest.rt)
    cam.Start2D()
        render.OverrideBlend(true,
            kind[1], kind[2], kind[3]
        )
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(masks.source.mat)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        render.OverrideBlend(false)
    cam.End2D()
    render.PopRenderTarget()

    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(masks.dest.mat)
    surface.DrawTexturedRect(x or 0, y or 0, w or ScrW(), h or ScrH())
end

----
---@name masks.EndToTexture
----
---@arg (tex:     ITexture)
---@arg (kind: masks.KIND_) The kind of mask this is, remember this is not a number enum
----
---- Stops the source render and renders everything to the given ITexture
----
function masks.EndToTexture(texture, kind)
    kind = kind or masks.KIND_CUT

    cam.End2D()
    render.PopRenderTarget()

    render.PushRenderTarget(masks.dest.rt)
    cam.Start2D()
        render.OverrideBlend(true,
            kind[1], kind[2], kind[3]
        )
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(masks.source.mat)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        render.OverrideBlend(false)
    cam.End2D()
    render.PopRenderTarget()

    if IsValid(texture) then
        render.CopyTexture(masks.dest.rt, texture)
    end
end

---
--- Examples
--- These depend on melonlib being installed
--- Although you can copy from them just fine
---
if not melon then return masks end

---
--- Basic example
--- This shows how to render a gradient rounded box
---
melon.DebugHook(false, "HUDPaint", function()
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

    if __render_melons_masks_ then
        __render_melons_masks_("gradround")
    end
end )

----
---- Gradient Text Example
---- This shows how to render text that is a gradient
----
melon.DebugHook(false, "HUDPaint", function()
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

    if __render_melons_masks_ then
        __render_melons_masks_("gradtext")
    end
end )

----
---- Gradient Rounded Box Border
---- This shows how to render the border of a rounded box being a gradient
----
melon.DebugHook(false, "HUDPaint", function()
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

    if __render_melons_masks_ then
        __render_melons_masks_("gradborder")
    end
end )

----
---- Transparent masks
---- This shows that transparency is translated into the mask render
----
melon.DebugHook(false, "HUDPaint", function()
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

    if __render_melons_masks_ then
        __render_melons_masks_("transparent")
    end
end )

---
--- End of examples
---

return masks
