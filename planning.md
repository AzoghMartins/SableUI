# SableUI Planning

SableUI is a modular World of Warcraft 3.3.5a UI suite for an AzerothCore private server using `mod-playerbots`, `mod-individual-progression`, `mod-playerbot-bettercombat`, and `mod-playerbot-bettersetup`.

The first goal is to build a stable one-folder addon and then grow feature modules inside it. The largest early module is `Shell`, which should become the main full-screen control surface for character, party, raid, bot, inventory, and progression workflows.

## Current Local Context

- Client addon target: WotLK 3.3.5a, TOC interface `30300`.
- Addon path: `Interface/AddOns/SableUI`.
- Current core scaffold exists with TOC, namespace boot, defaults, theme helpers, module registry, command bridge, and slash commands.
- `Modules/Shell` exists as an internal SableUI module with a first operations frame.
- Useful local addon references are available nearby: `Ace3`, `ElvUI`, `MultiBot`, `Omen`, `Recount`, and `SharedMedia`.
- Custom AzerothCore module paths:
  - `/home/azoghmartins/azeroth-repo/AzerothDev/modules/mod-playerbot-bettercombat`
  - `/home/azoghmartins/azeroth-repo/AzerothDev/modules/mod-playerbot-bettersetup`

## Current Implementation Status

Created files:

- `SableUI/SableUI.toc`
- `SableUI/Core/Init.lua`
- `SableUI/Core/Defaults.lua`
- `SableUI/Core/Utils.lua`
- `SableUI/Theme/Theme.lua`
- `SableUI/Core/Modules.lua`
- `SableUI/Core/Commands.lua`
- `SableUI/Core/Roster.lua`
- `SableUI/Core/Progression.lua`
- `SableUI/Core/Profiles.lua`
- `SableUI/Core/Slash.lua`
- `SableUI/Modules/Shell/Shell.lua`
- `SableUI/Libs/Ace3/*`

Available slash commands:

- `/sable` opens Shell
- `/sableui` opens Shell
- `/sable help`
- `/sable shell`
- `/sable modules`
- `/sable module <name> on|off|load|toggle`
- `/sable profile list|save <name>|load <name>|delete <name>`
- `/sable pull`
- `/sable tank`
- `/sable tankclear`
- `/sable automark`
- `/sable sap`
- `/sable setup`
- `/sable restock`
- `/sable spec <role-or-spec>`
- `/sable petspec <tank|dps|stealth|control>`

Current implementation notes:

- Ace3 is embedded under `SableUI/Libs/Ace3` and loaded before core files.
- Active profile selection is character-local through `SableUICharDB.profile`.
- Profile definitions are global in `SableUIDB.profiles`, so profiles saved by one character can be loaded by another.
- Module enablement is character-local through `SableUICharDB.modules`.
- Shell > Modules shows module checkbox rows backed by the module registry; planned modules without internal module files are marked `missing`.
- Core roster scanning now lives in `SableUI.Roster`.
- Roster classification supports stored/manual `Player`, `Classbot`, `Altbot`, or `Unknown` values; automatic Classbot vs Altbot detection still needs server support or command feedback.
- Progression querying targets the selected Party/Raid member before sending `.ip get` and parses the known `Progression Level for <name> = <tier>` system response into `SableUICharDB.progression.cache`.
- Progression member query UI is disabled for now because addon-side targeting triggers Blizzard protected-action warnings. A server helper module should expose this later without client retargeting.
- Character > Stats has a first real stats panel covering summary, attributes, combat, defense, and resistances.

## Resolved Architecture Decisions

- Ace3 should be embedded into SableUI core so users do not need to download Ace3 separately.
- SableUI should install as one folder only: `Interface/AddOns/SableUI`.
- Modules live as internal folders under `SableUI/Modules`.
- Shell is an internal module; `/sable` and `/sableui` open it directly.
- Shell > Modules hosts module toggles now and should later add profile controls.
- Module enablement is per character.
- Profiles should be saveable and loadable from other characters, but module on/off state still belongs to the active character.
- MultiBot is only a reference source. SableUI should replace it instead of integrating with its runtime state.
- Bot roster source should be party/raid units. Bots are expected to always be in the player's party or raid.
- SableUI should add its own classification checks for Classbot versus Altbot.
- Individual Progression can be queried with `.ip get` against the target. If client-side parsing is too weak, extend a custom server module to expose cleaner data.
- DamageMeter should support grouped rows with click-to-expand details for individual bots.

## Design Goals

1. Make SableUI feel like one cohesive interface, even when modules are enabled independently.
2. Keep the core small and dependable: theme, media, saved settings, module registry, shared helpers, slash commands, and options.
3. Keep high-risk or large features in internal modules so they can be soft-disabled without destabilizing the entire UI.
4. Treat bot command flows as first-class UI actions, not as raw chat macros scattered through the codebase.
5. Respect WotLK-era addon constraints, especially combat lockdown and the older Lua/API surface.
6. Build with private-server realities in mind: commands and server behavior may be custom and should be isolated behind a command bridge.

## Important 3.3.5a Constraints

- Lua is 5.1-era. Avoid modern Lua syntax and APIs.
- Secure frames and action buttons are restricted in combat. Action bars, unit frames, and click-cast style controls need careful protected-frame design.
- Already-loaded addon Lua cannot be truly unloaded during a session. Disabling a module can soft-disable its behavior immediately, but a full unload requires `ReloadUI`.
- Nested module folders inside one addon are not separately visible to WoW as addons. Internal module Lua is loaded by `SableUI.toc`, while heavy frames/data can still be created lazily at runtime.
- `COMBAT_LOG_EVENT_UNFILTERED` uses the WotLK-era event argument pattern, not the modern retail helper APIs.
- Addon startup order is controlled by TOC dependencies and file order.

## Proposed Addon Layout

Use one installable addon folder with internal module folders:

```text
Interface/AddOns/
  SableUI/
    SableUI.toc
    planning.md
    Core/
    Media/
    Theme/
    Config/
    Widgets/
    Utils/
    Modules/
      Shell/
      UnitFrames/
      ActionBars/
      NamePlates/
      ThreatMeter/
      DamageMeter/
      Chat/
      BotControl/
```

Notes:

- Use `UnitFrames`, not `UnitFranes`, as the module name.
- All module files are referenced from `SableUI.toc`.
- Modules can be soft-enabled/disabled per character; true Lua unload requires a UI reload because everything is inside one addon.
- Heavy UI frames should still be created lazily when a module is opened or enabled.

## Core Addon Responsibilities

`SableUI` owns shared behavior:

- Global namespace: `SableUI`.
- Saved variables:
  - `SableUIDB` for global/account-wide profile data, theme presets, and reusable settings.
  - `SableUICharDB` for character-specific layout and module enablement.
  - Future profile tools should allow copying profile settings from other characters without making module enablement account-wide.
- Theme system:
  - Fonts.
  - Colors.
  - Textures.
  - Spacing, border sizes, panel opacity, statusbar style.
  - Class color helpers.
  - Reaction color helpers.
  - Power/resource color helpers.
- Media registry:
  - Built-in fallback font and texture paths.
  - Optional SharedMedia registration/detection.
- Module registry:
  - Known module TOC names and display names.
  - Enabled/disabled state.
  - Runtime loaded state.
  - Soft enable/disable hooks.
  - Reload-required messaging for modules that cannot be fully disabled live.
- Command bridge:
  - Safe wrappers for `SendChatMessage`.
  - Routing helpers for SAY, PARTY, RAID, WHISPER, target, and selected bot.
  - Canonical command definitions for custom PlayerBot commands.
- Shared widgets:
  - Panels, buttons, icon buttons, tabs, scroll lists, status bars, dropdowns, confirmation dialogs.
- Slash commands:
  - `/sable`
  - `/sableui`
  - Likely subcommands: `config`, `shell`, `modules`, `reload`, `debug`.
- Debug/logging:
  - Toggleable verbose mode.
  - Central print prefix.
  - Optional event tracing for development.

## Module Enable/Disable Model

The core should support two layers:

1. Runtime soft state:
   - `module:Enable()`
   - `module:Disable()`
   - Event unregistering.
   - Frame hiding.
   - Hook behavior guarded by `module.enabled`.
   - Heavy frame/data creation delayed until first use.

This gives users immediate per-character control while keeping SableUI installable as a single folder. Loaded Lua remains in memory until reload.

## External Dependencies

Ace3 should be embedded into the SableUI core distribution.

- Embedded `Ace3`: config, events, profiles, and mature WotLK patterns without requiring a separate user download.
- Optional `SharedMedia`: useful for font/statusbar texture selection.
- Reference only, not hard dependency at first:
  - `MultiBot` for current PlayerBot UI command patterns, but not as a runtime dependency.
  - `Omen` for threat-meter behavior and WotLK threat API usage.
  - `Recount` for combat log parsing and data window patterns.
  - `ElvUI` for broad UI-suite organization patterns.

Implementation note:

- Vendor only the Ace3 libraries we use, rather than blindly loading every Ace3 component if the final feature set does not need all of them.
- The addon should still avoid hard failure when optional `SharedMedia` is missing.

## PlayerBot Command Contracts

The UI should call command helpers instead of manually sending strings throughout modules.

Known `mod-playerbot-bettercombat` commands:

- `pull`
  - Uses current player target.
  - Selects controlled main tank bot in group/raid.
  - Supports tank openers such as warrior `heroic throw`, druid faerie fire/moonfire, paladin avenger's shield/hand of reckoning/exorcism, death knight death grip/icy touch.
  - Holds support bots briefly and releases group into combat.
- `tank`
  - Arms a saved tank pull position.
  - Next `Aedm` ground-target cast stores the tank position.
  - `tank clear` clears it.
- `automark`
  - Toggles automatic skull/X maintenance.
- `sap`
  - Uses controlled rogue bots and their `rti cc target`.

Known `mod-playerbot-bettersetup` commands:

- `setup`
- `spec`
- `spec <spec|role>`
- `spec manual <on|off>`
- `spec switch [1|2]`
- `restock`
- `petspec <tank|dps|stealth|control>`

Selectors from `mod-playerbots` still matter and should be supported as command-prefix inputs where useful:

- Examples: `@group2 @hunter restock`, `@group2 @warrior spec fury`.

## Bot Roster And Classification

The primary roster source is the live party/raid roster.

- Bots are expected to always be part of the player's party or raid.
- Shell and BotControl should scan `party*` and `raid*` unit tokens rather than depending on MultiBot friend/account rosters.
- SableUI should maintain a roster cache with name, GUID, class, level, online/dead state, role hints, and current unit token.
- SableUI needs custom checks to classify a unit as a Classbot or Altbot. The exact detection mechanism is still implementation work.
- MultiBot can be studied for command examples, but SableUI should not integrate with its UI state or saved variables.

## Command Bridge Plan

Create a central API such as:

```lua
SableUI.Commands:SendToGroup(command)
SableUI.Commands:SendToTarget(command)
SableUI.Commands:WhisperBot(botName, command)
SableUI.Commands:SendSelector(selector, command)
SableUI.Commands:Pull()
SableUI.Commands:TankMark()
SableUI.Commands:ClearTankMark()
SableUI.Commands:AutoMark()
SableUI.Commands:Sap()
SableUI.Commands:Setup(selector)
SableUI.Commands:Spec(selector, specOrRole)
SableUI.Commands:Restock(selector)
SableUI.Commands:PetSpec(selector, petRole)
```

Command sending rules:

- Combat orchestration commands that operate on the current player target can use `PARTY` or `RAID` when grouped, matching current PlayerBot command patterns.
- Single-bot actions should prefer `WHISPER` to the bot name.
- GM/server dot commands should be isolated behind explicit functions and not mixed with ordinary bot commands.
- Every command button should have a disabled/error state when it requires a target, group, selected bot, or GM permission.

## Planned Internal Modules

### Shell

Primary near-full-screen operations window.

Initial purpose:

- One place to inspect player, party, raid, bots, target, inventory, and combat control state.
- Primary UI for PlayerBot and progression-specific workflows.
- Bigger and more deliberate than a normal action bar or tooltip-driven addon.

Navigation model:

- Top tabs are the main areas: `Shell`, `Character`, and `Party/Raid`.
- Each top area owns a left-side tab rail.
- `Party/Raid` also owns a bottom member tab rail for party or raid characters.
- Bot-specific controls belong under the relevant Party/Raid member views, not in the top menu.
- Combat command controls should not be a top Shell area.

Shell area left tabs:

- `Modules` default: module enable/disable checkboxes later.
- One settings tab per module.

Character area left tabs:

- `Stats` default.
- `Gear`.
- `Inventory`.
- `Skills`.
- `Talents`.
- `Pets`.
- `Reputation`.

Party/Raid area:

- Bottom tabs represent party/raid members.
- Each selected member uses the same left tabs as Character: `Stats`, `Gear`, `Inventory`, `Skills`, `Talents`, `Pets`, and `Reputation`.
- Player, Classbot, and Altbot members can expose different controls inside the same section.
- Altbot-only sections: inventory, skills, and reputation.
- Hunter and warlock pet views should show active pet information for all relevant members.
- Bot pet views should include `petspec`; Altbot pet views can later include stablemaster controls.
- Raid Stats should eventually support main tank and assist definitions.
- Bot Stats should eventually include strategy controls.

Shell UX decisions:

- Full-screen or near-full-screen with a compact top nav.
- `/sable`, `/sableui`, `/sable shell`, and a later keybind should toggle Shell.
- Should not use decorative card-heavy layout. This is an operations tool.
- Use dense but readable rows and status bands.
- Avoid blocking combat view unless the player intentionally opens it.
- Store position, size, last open tab, and selected bot/group filter per character.
- Size should be computed dynamically from `UIParent` so it stays coherent across 1080p and 4K setups.
- Shell > Modules contains module checkboxes now and should later add profile controls.

First Shell milestone:

1. Window scaffold with theme styling.
2. Top tabs for Shell, Character, and Party/Raid.
3. Left tab rail that changes per top area.
4. Bottom Party/Raid member tab rail.
5. Roster scan for player/party/raid.
6. Responsive Shell sizing based on the game window.

### UnitFrames

Replacement unit frames.

Scope:

- Player.
- Target.
- Target of target.
- Focus if supported in this client/server environment.
- Party.
- Raid.
- Pet.
- Boss frames only if useful/available.

Risks:

- Secure click behavior.
- Combat lockdown.
- Aura filtering performance.
- Integration with Shell and BotControl role data.

Likely design:

- Build after the Shell command model is stable.
- Use core theme widgets and statusbar helpers.
- Avoid replacing every Blizzard frame until replacement behavior is reliable.

### ActionBars

Replacement action bars.

Scope:

- Main bars.
- Paging.
- Stance/forms.
- Pet bar.
- Possess/vehicle if needed for 3.3.5a.
- Keybind text.
- Macro/item/spell cooldown and range states.

Risks:

- Highest combat-lockdown risk.
- Must create protected buttons correctly before combat.
- Drag/drop, paging, and state drivers need a careful WotLK implementation.

Recommendation:

- Defer until core and Shell are working.
- Consider studying Bartender4 locally before implementation.

### NamePlates

Nameplate replacement.

Scope:

- Health bars.
- Cast bars.
- Threat coloring.
- Target highlight.
- Quest/progression/bot-aware markers if feasible.

Risks:

- WotLK nameplate APIs are limited compared to modern clients.
- Performance and scan loops need care.

### ThreatMeter

Visual threat meter.

Scope:

- Current target threat bars.
- Tank/off-tank emphasis.
- Pull-state display where possible.
- Warning states when player or bot is close to pulling threat.

Data sources:

- Blizzard threat APIs like `UnitDetailedThreatSituation`.
- Party/raid unit scans.
- Optional reference behavior from Omen.

### DamageMeter

Combat stats window.

Scope:

- Damage done.
- Healing done.
- Damage taken.
- Deaths.
- Interrupts/dispels later.
- Segment reset and current fight view.
- Grouped actor rows, with click-to-expand detail rows for individual bots.

Data sources:

- `COMBAT_LOG_EVENT_UNFILTERED`.
- GUID-to-unit roster cache.

Risks:

- Combat log volume.
- Correct ownership for pets/guardians/bots.
- Memory growth if old fight data is not pruned.

Recommendation:

- Start smaller than Recount.
- Build the display and data model around only the modes we actually use.

### Chat

Improved chat window.

Scope:

- Cleaner tabs.
- Better timestamps.
- Bot response highlighting.
- Command echo/logging.
- Optional filters for noisy bot chatter.

Risks:

- Avoid hiding important server feedback.
- Do not break standard chat edit box behavior.

### BotControl

Combat-focused bot action bar.

Scope:

- Pull.
- Follow/stay.
- Attack/flee.
- Passive/aggressive modes where supported.
- CC commands.
- Quick spec/setup/restock commands outside combat, if safe.
- Targeted single-bot controls.

Relationship to Shell:

- Shell is the full operations window.
- BotControl is the always-available compact combat strip.
- Both should use the same command bridge.

## Possible Future Modules

- `SableUI_Questing`: quest sync, bot quest state, guide integration.
- `SableUI_Progression`: Individual Progression status and bracket-aware UI.
- `SableUI_Loot`: loot assignment, bot inventory cleanup, sell/drop safeguards.
- `SableUI_Debug`: event inspector and command diagnostics for development.
- `SableUI_Map`: bot positioning, tank pull markers, saved locations.

## Theme Direction

Working direction:

- Dark neutral base.
- Muted metal/charcoal panels.
- Strong readable status colors.
- Class colors used sparingly for identity.
- Avoid a single-hue palette.
- Tight spacing, crisp borders, compact controls.

Core theme tokens:

- `font.normal`
- `font.bold`
- `font.mono`
- `color.bg`
- `color.panel`
- `color.panelAlt`
- `color.border`
- `color.text`
- `color.textMuted`
- `color.accent`
- `color.good`
- `color.warn`
- `color.bad`
- `color.health`
- `color.power`
- `texture.statusbar`
- `size.border`
- `size.padding`
- `size.rowHeight`

## Implementation Phases

### Phase 1: Core Scaffold

- Create `SableUI.toc`.
- Create global namespace and startup event handling.
- Create saved-variable defaults and migration/version handling.
- Create theme/media helpers.
- Create module registry.
- Create command bridge.
- Create slash commands.
- Create minimal options/module toggle UI.

### Phase 2: Shell Scaffold

- Create `Modules/Shell` internal module.
- Register with core.
- Build near-full-screen frame.
- Add tabs and basic layout.
- Add player/party/raid roster model.
- Add first bot command controls.
- Add command log.

### Phase 3: Bot Workflows

- Add selected bot state.
- Add selector builder UI.
- Add setup/spec/restock/petspec controls.
- Add combat command panel.
- Capture useful chat/system feedback where possible.
- Add safeguards for target/group-required actions.

### Phase 4: Compact BotControl

- Create `SableUI_BotControl`.
- Reuse command bridge.
- Provide combat strip outside Shell.
- Add keybinds.

### Phase 5: Core UI Replacements

Recommended order:

1. Chat.
2. ThreatMeter.
3. DamageMeter.
4. UnitFrames.
5. NamePlates.
6. ActionBars.

ActionBars should come late because protected action button behavior has the highest risk.

## Immediate Next Build Tasks

1. Add Character > Gear equipment layout.
2. Add Character > Inventory bag layout.
3. Add Party/Raid member detail layouts using the core roster cache.
4. Decide the server-side command or response format for reliable Classbot versus Altbot classification and Individual Progression lookups.
5. Add Shell UI controls for profile save/load instead of slash-only profile management.
6. Start scaffolding the remaining internal module folders so module toggles can be exercised beyond Shell.
