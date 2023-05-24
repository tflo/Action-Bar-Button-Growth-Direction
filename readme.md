# Action Bar Button Growth Direction


## Summary

Reverse button growth direction (top/bottom, right/left) of any multi-row/column action bar.


## What it does

With Dragonflight, Blizz changed the button growth direction for multi-row action bars. Formerly, it was ‘top to bottom’ (downwards), now it is ‘bottom to top’ (upwards).

I don’t know why they did that. For most action bars, it is not tragical, since you can adapt your keybindings accordingly. However, it can be a problem with Action Bar 1, or whatever bar is used as override bar, resulting in the “wrong” key binds for the override bar (vehicle UI).

This addon allows you to reverse the button growth direction for all bars, or for specific bars. You can do this for both the Y- and X-axis (vertically/horizontally).

By default, the addon reverses only the Y-axis button growth direction of Action Bar 1 (from ‘bottom to top’ to ‘top to bottom’) and leaves everything else unchanged.


## Explanation

Let’s say you have an action bar with horizontal orientation like this:

```
1 2 3 4 5 6 7 8 9 0 Q W
```

If you converted this bar to 3-throw bar _before Dragonflight_, you got ‘top to bottom’:

```
1 2 3 4
5 6 7 8
9 0 Q W
```

Since Dragonflight, you get ‘bottom to top’:

```
9 0 Q W
5 6 7 8
1 2 3 4
```

The addon just reverts the growth direction to the one before Dragonflight (‘top to bottom’).

For the sake of completeness, I also added the ability to reverse the growth direction on the X-axis (horizontal), but since Blizz hasn’t screwed that up (it’s still ‘left to right’), I don’t think there’s much use for it, and it’s completely disabled by default. But who knows, maybe they have plans to screw that up in the future.


## Setup

The addon has no user interface. However, all settings are exposed to the SavedVariables file, which means you can edit them there and they will be preserved across future addon updates.

It’s pretty straightforward:

- You have one big table with all action bars for each the Y and the X axis. The order corresponds to the action bars by index (so `[1]` is Action Bar 1, `[6]` is Action Bar 6, and so on). An action bar set to `false` will be left unchanged; if set to `true`, the button growth direction will be reversed on the respective axis.
- You have a small `enabled` table. This is a quick way to set the behavior for _all_ bars per axis, and it can overwrite any setting in the big per-bar tables. You can set it to:
  - `”none”`: No bar will be reversed for the respective axis. Per-bar settings are ignored.
  - `”all”`: All bars will be reversed for the respective axis. Per-bar settings are ignored.
  - `”some”`: The per-bar settings from the big table are used.

The defaults are: 

- X-axis is completely disabled (`enabled.x = “none”`), 
- on the Y-axis, Action Bar 1 is reversed, the rest is unchanged.

So, if you want to reverse all bars on the Y-axis, just set the `enabled.y` to `”all”`.


## Taint

When I started experimenting with the scripts, I expected to get heavy taint issues (e.g. “Action blocked…” messages). To my surprise, I didn’t get any taint issues – so far. But this may be different for you, because of different environment conditions (e.g. addon sets, localizations). 

I have added an alternative method to reverse the growth direction, which you can try _if_ you get taint with the default method. Chances are slim that it will help in this case, but they are – probably – there.

To use the alternative method, set `method` to `2` in the SavedVariables table.
