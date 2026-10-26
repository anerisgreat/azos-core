---
marp: true
theme: azos
paginate: true
title: Presentation Title
footer: Author Name · Venue · Date
# Per-deck overrides of theme variables, e.g. the generated outro text:
# style: |
#   section { --outro-title: "Thanks!"; --outro-subtitle: "me@example.com"; }
---

<!-- _class: intro -->
<!-- _footer: "" -->

# Presentation Title

## A subtitle explaining the talk

Author Name · Date

<!--
Speaker notes go in HTML comments like this one: they are hidden from the
slide but appear in the presenter view (press `p` in the HTML output).
-->

---

# Agenda

1. Motivation
2. Layouts
3. Media
4. Wrap-up

---

<!-- _class: divider -->

# Layouts

---

# Two columns

<div class="columns">
<div>

## Left

- Markdown works inside the columns
- Leave a **blank line** after each `<div>`

</div>
<div>

## Right

```python
def hello():
    return "world"
```

</div>
</div>

---

# Three columns

<div class="columns-3">
<div>

### Fast
Something about speed.

</div>
<div>

### Simple
Something about simplicity.

</div>
<div>

### Cheap
Something about cost.

</div>
</div>

---

<!-- _class: lead -->

# A centred statement

Use `lead` for a single big idea.

---

<!-- _class: divider -->

# Media

---

# Image on the right

![bg right:40%](https://picsum.photos/800/900)

- Title and text keep the left side
- `right:40%` sets the image width
- Local files work too: `![bg right](./img/figure.png)`

---

# Image on the left

![bg left:45% fit](https://picsum.photos/900/700)

- `fit` keeps the whole image visible
- Use `contain` / `cover` for other scaling

---

<!-- _class: lead -->
<!-- _color: white -->

![bg brightness:0.45](https://picsum.photos/1600/900)

# Full-bleed background

---

# Centred image with caption

![w:640 center](https://picsum.photos/1280/560)

<div class="caption">Figure 1: a caption under the image.</div>

---

<!-- Several bg images are laid out side by side; add `vertical` to stack them -->

![bg](https://picsum.photos/700/800?1)
![bg](https://picsum.photos/700/800?2)
![bg](https://picsum.photos/700/800?3)

---

# Table

| Option | Speed | Cost |
|--------|------:|-----:|
| A      |  fast |  $$$ |
| B      |  slow |    $ |
| C      |   ok  |   $$ |

---

# Code

```nix
{pkgs, ...}: {
  home.packages = with pkgs; [marp-cli];
}
```

Inline `code` is styled too.

---

# Quote & math

> Simplicity is prerequisite for reliability.
> — Edsger W. Dijkstra

Inline math $e^{i\pi} + 1 = 0$ and display math:

$$
\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}
$$

---

<div class="small">

# Lots of text

Wrap dense content in `<div class="small">` to shrink it, or rely on the
theme's auto-scaling for headings and code blocks.

</div>

---

<!-- _class: outro -->
<!-- _footer: "" -->
