# Action Bar Button Growth Direction

## Summary

Reverse button growth direction (top/bottom, right/left) of any multi-row/column action bar.

## What it does

With Dragonflight, Blizz changed the button growth direction for multi-row action bars. Formerly, it was ‘top to bottom’ (downwards), now it is ‘bottom to top’ (upwards).

I don’t know why they did this. For most action bars, this is not overly tragic, as you can adjust your spell mapping/keybinds accordingly. However, it can be a real problem with Action Bar 1, which is used as the override and vehicle UI bar, resulting in the “wrong” keybinds in the vehicle UI.

This addon allows you to reverse the button growth direction.

So if you were tempted to use a ‘biggy’ addon like Dominos or Bartender _just to get the button growth direction fixed,_ you might want to give this one a try. It has no impact on your client performance, it does its stuff only at login, then nothing. Be sure to read the “Taint” section further down.

By default, only the Y-axis button growth direction of Action Bar 1 is reversed (from ‘bottom to top’ to ‘top to bottom’); everything else remains unchanged.

---

*If you’re having trouble reading this description on CurseForge, you might want to try switching to the [Repo Page](https://github.com/tflo/Action-Bar-Button-Growth-Direction?tab=readme-ov-file#action-bar-button-growth-direction). You’ll find the exact same text there, but it’s much easier to read and free from CurseForge’s rendering errors.*

---

## A bit more in-depth

Let’s say you have an action bar with horizontal orientation like this:

1 2 3 4 5 6 7 8 9 0 Q W  

If you converted this bar to 3-row bar _before Dragonflight,_ you got ‘top to bottom’:

1 2 3 4  
5 6 7 8  
9 0 Q W  

Since Dragonflight, you get ‘bottom to top’:

9 0 Q W  
5 6 7 8  
1 2 3 4  

That’s where the addon comes into play: it can revert the growth direction to the one before Dragonflight (‘top to bottom’).

For the sake of completeness, I also added the ability to reverse the growth direction on the X-axis (horizontal), but since Blizz hasn’t screwed that up (it’s still ‘left to right’), I don’t think there’s much use for it, and it’s completely disabled by default. But who knows, maybe they have ambitious plans to screw that up in the future.

## Setup

The addon has __no user interface.__ However, all settings are exposed to a database in the __SavedVariables__ file, which means you can edit them there and they will be preserved across future addon updates.

I hope you can live with that, but adding a config UI for something that you will change once in your WoW lifetime – if ever – is way too much overhead for my taste. __It's very likely that the default settings (see below) are fine for you and you won't want to change anything.__

The SavedVariables file is at `../World of Warcraft/_retail_/WTF/Account/[your account number]/SavedVariables/ActionBarButtonGrowthDirection.lua`. Use a _text editor_ to edit the file (e.g. TextEdit, BBEdit, Notepad++, …), do not use a word processor (e.g. MS Word). To edit and save the file in-place, you don’t have to quit WoW but you have to be logged out. Otherwise the client will overwrite your changes at next logout/reload.

__It’s pretty straightforward:__

- You have __one big table with all action bars for each the Y- and the X-axis.__ The order corresponds to the action bars by index (so `[1]` is Action Bar 1, `[6]` is Action Bar 6, and so on). An action bar set to `false` will be left unchanged; if set to `true`, the button growth direction will be reversed on the respective axis.
- You have a __small `enabled` table.__ This is a quick way to set the behavior for _all_ bars per axis, and it can overwrite any setting in the big per-bar tables. You can set it to:
  - `"none"`: No bar will be reversed for the respective axis. Per-bar settings are ignored.
  - `"all"`: All bars will be reversed for the respective axis. Per-bar settings are ignored.
  - `"some"`: The per-bar settings from the big table for this axis will be used.

__The defaults are:__

- X-axis is completely unmodified (`enabled.x = "none"`).
- On the Y-axis, Action Bar 1 is reversed, the rest is unchanged.

So, if you want to reverse all bars on the Y-axis, just set the `enabled.y` to `"all"` instead of `"some"`.

## Taint

When I started experimenting with the scripts, I expected to get heavy taint propagating issues (e.g. “Action blocked…” popups). The addon does nothing during combat, but still, we are fiddling with global tables (the action bars) that are further on used for secure actions. 

To my surprise, I didn’t get any taint issues, not one – so far. But this may be different for you because of different environment conditions like different addon sets, or even localizations.

__Update note 2025:__ I got a couple of “Action blocked” popups that blamed this addon, around late 11.2.0, but only in Edit Mode, and never later (e.g. 11.2.5). I could ignore them without consequences, and I was not able to reproduce them reliably. Never got one outside Edit Mode, never got one in any raid or other encounter, or during vehicle UIs.

But this may be different for you because of different environment conditions like different addon sets, or even localizations. And any Blizz patch can change this.

I have added an alternative method to reverse the growth direction, which you can try _if_ you get taint with the default method. Chances are slim that it will help in this case, but they are – probably – there.

To use the alternative method, set `method` to `2` in the SavedVariables table. If you are taint-free with the default method, do not use method 2, as it is rather clumsy and has much room for improvement.

Please report any taint issues at the issues link (see header of the CurseForge page or last line of this ReadMe).

---

Feel free to share your suggestions or report issues on the [GitHub Issues](https://github.com/tflo/Action-Bar-Button-Growth-Direction/issues) page of the repository.  
__Please avoid posting suggestions or issues in the comments on Curseforge.__

---

__Addons by me:__

- [___PetWalker___](https://www.curseforge.com/wow/addons/petwalker): Never lose your pet again (…or randomly summon a new one).
- [___Auto Quest Tracker Mk III___](https://www.curseforge.com/wow/addons/auto-quest-tracker-mk-iii): Continuation of the one and only original. Up to date and tons of new features.
- [___Goyita___](https://www.curseforge.com/wow/addons/goyita): Your Black Market assistant. Know when BMAH auctions will end. Tracking, alerts, history, info.
- [___Move 'em All___](https://www.curseforge.com/wow/addons/move-em-all): Mass move items/stacks from your bags to wherever. Works also fine with most bag addons.
- [___Auto Discount Repair___](https://www.curseforge.com/wow/addons/auto-discount-repair): Automatically repair your gear – where it’s cheap.
- [___Auto-Confirm Equip___](https://www.curseforge.com/wow/addons/auto-confirm-equip): Less (or no) confirmation prompts for BoE and BtW gear.
- [___Slip Frames___](https://www.curseforge.com/wow/addons/slip-frames): Unit frame transparency and click-through on demand – for Player, Pet, Target, and Focus frame.
- [___Action Bar Button Growth Direction___](https://www.curseforge.com/wow/addons/action-bar-button-growth-direction): Fix the button growth direction of multi-row action bars to what is was before Dragonflight (top --> bottom).
- [___EditBox Font Improver___](https://www.curseforge.com/wow/addons/editbox-font-improver): Better fonts and font size for the macro/script edit boxes of many addons, incl. Blizz's. Comes with 70+ preinstalled monospaced fonts.
