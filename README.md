<p align="center">
  <a href="https://make.fun/bounty/roblox-brainrot-01"><img src="https://make.fun/badge/roblox-brainrot-01.svg" alt="roblox-brainrot-01 badge" /></a>
  <a href="https://make.fun/bounty/roblox-brainrot-01"><img src="https://make.fun/badge/roblox-brainrot-01/Lolod17/brainrot-bog/rank.svg" alt="rank badge" /></a>
  <a href="https://make.fun/bounty/roblox-brainrot-01"><img src="https://make.fun/badge/roblox-brainrot-01/Lolod17/brainrot-bog/reward.svg" alt="reward badge" /></a>
</p>

# BRAINROT BOG

A 3D Roblox swamp game where you dredge brainrot characters from a glowing pedestal, carry them
home to your floating raft, and build a cash-printing deck before the Mud Tide sweeps the bog clean.

Made for [make.fun/bounty/roblox-brainrot-01](https://make.fun/bounty/roblox-brainrot-01).

## The loop

1. **Dredge.** Walk onto the Dredge Pedestal and hold **E** to pay the growing price and pull a
   random character out of the bog. Rarity is rolled first (Common 45% down to Secret 0.15%), then
   a uniform pick inside that rarity.
2. **Take it home.** Pick the character up and walk back to your raft on the edge of the island.
   You can only carry one at a time.
3. **Place it on your deck.** Step onto your raft's deck pad while carrying and the character is
   installed in the next free slot and starts earning.
4. **Cash ticking.** Every placed character pays its rate in cash per second, ticked four times
   a second and shown live on your HUD.
5. **Upgrades.** Spend cash at the Upgrade Shack (**U**) on more deck slots (4 to 12) and on
   Walk Speed so the trips home are shorter.
6. **Stealing with the Bog Lock.** Any unlocked character on *someone else's* raft gets a
   hold-to-steal prompt (**E**, 2.5 s hold, 5 s cooldown). Bog Lock is an Upgrade Shack purchase
   that locks one of your own characters against theft.
7. **The Mud Tide.** Every 110 seconds a warning banner and horn flash, then a brown wall of
   parts sweeps in from the map edge. Anyone on open water, the boardwalks or the mud islands
   when it passes is swallowed and loses 10% of their cash. Your raft is safe.
8. **Rebirth.** At the Toll Booth, once you have earned 7500 cash in a life, take rebirth: cash
   resets to 25 but you gain a permanent +30% earnings multiplier. At six rebirths the Bog Baron
   panel fires.

## The cast

Fifteen characters across seven rarities. Rates are cash per second.

| Name | Rarity | Rate (cash/s) |
|---|---|---|
| Soggy Waffle Steve | Common | 1 |
| Taxi Rat | Common | 2 |
| Grandma Cucumber | Common | 4 |
| Moth Intern | Uncommon | 7 |
| Skateboard Goat | Uncommon | 11 |
| Toilet Philosopher | Uncommon | 16 |
| Croissant Sorcerer | Rare | 24 |
| Pigeon Baron | Rare | 34 |
| Microwave Monk | Rare | 48 |
| Drill Sergeant Duck | Epic | 72 |
| Cosmic Lobster | Epic | 110 |
| Unicycle Alien | Legendary | 170 |
| Giga Shrimp | Legendary | 260 |
| The Investor | Mythic | 420 |
| Godfather Goldfish | Secret | 900 |

## Files

| File | What it does |
|---|---|
| `main.ts` | Node 22 hand-in program: checks the screenshots, copies the game to `/output` and writes `dossier.json`. |
| `vendor/makefun-roblox.ts` | The kit's vendored `buildDossier` library. Unchanged. |
| `default.project.json` | Rojo project mapping: `src/server` -> `ServerScriptService.Server`, `src/client` -> `StarterPlayerScripts.Client`. |
| `game.rbxl` | The built place. Rebuild with `rojo build default.project.json --output game.rbxl`. |
| `PLAY.json` | The published place link, place id and universe id. |
| `TOUR.json` | The reviewer tour: one step per screenshot, each naming the Demo preset that reaches it. |
| `screenshots/` | Four captures of the game running in Studio; the first by name is the cover. |
| `src/server/init.server.luau` | The one server entry: requires every module, builds the world, wires the Remotes, owns join/leave, the money tick and the tide cycle. |
| `src/server/Config.luau` | Every tunable number in one place: prices, tick rate, rarity weights and colours, tide timings. |
| `src/server/Cast.luau` | The fifteen characters: name, rarity, rate, joke and a build recipe for each. |
| `src/server/World.luau` | Builds the whole swamp out of parts and returns the anchors the other modules read. |
| `src/server/BrainrotFactory.luau` | Turns a cast recipe into a placed Model and owns the Bog-Lock attribute. |
| `src/server/PlayerState.luau` | Every player's cash, placed characters, carried state and rebirth count, in one table. |
| `src/server/Dredge.luau` | The pedestal prompt, the price curve, spawning a rolled character and carrying it home. |
| `src/server/Upgrades.luau` | The Upgrade Shack prompt: deck slots, Walk Speed and Bog Lock, at the configured curve. |
| `src/server/Steal.luau` | Hold-to-steal prompts on other players' unlocked characters, with lock and cooldown checks. |
| `src/server/MudTide.luau` | The tide cycle: warning, horn, the sweeping wall and the swallow check. |
| `src/server/Rebirth.luau` | The Toll Booth prompt, the life reset and the permanent multiplier; the Bog Baron panel at six. |
| `src/server/Demo.luau` | Developer loadout presets for screenshots and review. |
| `src/client/init.client.luau` | The client entry: binds the HUD and the Fx layer to the server's Remotes. |
| `src/client/Hud.luau` | Cash counter, rate, deck slots, rebirth progress, tide banner and alerts. |
| `src/client/Fx.luau` | Client-side visual flourishes for the tide, the pedestal glow and the Bog Baron panel. |

## Build and run

```sh
rojo build default.project.json --output game.rbxl
```

Then open `game.rbxl` in Roblox Studio and press Play. `PLAY.json` must name your published place,
place id and universe id before the gate accepts the entry.

To check the hand-in program without the grader's container:

```sh
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

## The Demo module and the reviewer presets

`Demo` (the module at `ServerScriptService.Server.Demo`) is a development and review tool. It only
touches server state through the same functions the normal loop uses, so it cannot do anything a
player could not. A reviewer calls one preset from the Studio command bar after Play, or a tour
step names it, and the screen is set up without playing the whole loop.

| Preset | Argument | What it sets up |
|---|---|---|
| `Demo.PresetCover` | `"player name"` or `nil` for the first player | Three placed characters on the raft, cash in the thousands, tide countdown pinned at 12 s. |
| `Demo.PresetDredge` | `"player name"` or `nil` | A Mythic character standing on the glowing pedestal with the dredge prompt on screen. |
| `Demo.PresetBase` | `"player name"` or `nil` | Four placed characters, one of them Bog-Locked, deck slot counter visible. |
| `Demo.PresetTide` | `"player name"` or `nil` | The player out on the boardwalk and the tide wall triggered to sweep in. |
| `Demo.BuySlot` | `"player name"` or `nil` | Buys the next deck slot at the configured price, for hand-testing the Upgrade Shack. |
| `Demo.ResetLife` | player instance | Clears placed and carried models and resets the life without a rebirth. |

## The tour

`TOUR.json` carries one step per screenshot, in the screenshots' order by name: `1-cover.jpg`,
`2-dredge.jpg`, `3-base.jpg`, `4-tide.jpg`. Each step names its screenshot, the keys to press, a
wait in milliseconds, and the `Demo` call that reaches that screen, so make.fun's reviewers can
bring the game there themselves in Studio.
