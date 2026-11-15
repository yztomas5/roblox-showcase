# Roblox showcase

A small, complete Roblox feature written the way I build production games: a coin field that players walk through
to collect coins. It is tiny on purpose, so every rule I follow fits in a few files you can read in ten minutes.

My data package, [Vault](https://github.com/yztomas5/vault), is in its own repository.

## What it shows

| Rule | Where |
|---|---|
| **One script per side.** A single server `Script` and a single client `LocalScript` load every module. | `src/Server/init.server.luau`, `src/Client/init.client.luau` |
| **A boot that cannot hang the game.** Modules are ordered by `Priority` and `Dependencies`; every `Init` runs with a time budget and a loud warning if it stalls; `Start` runs in its own task; a module that fails to load is reported and skipped. | `src/Shared/Boot.luau` |
| **The server decides, the client draws.** The server never creates a visual. It validates with numbers and positions; the client builds and animates every coin. | `CoinService` vs `CoinController` |
| **Prediction with acknowledgements.** The client hides a coin the moment you touch it and sends a request with a sequence number. The server always answers, accepted or not, and the client only undoes its guess for that exact request. A lost answer times out and the coin comes back. | `CoinController.predict` / `settle`, `CoinService.onCollect` |
| **Fair validation under lag.** Reach forgives the distance a player can travel while the request is in flight, instead of rejecting honest players with high ping. | `Coins.reachable` |
| **Rate limiting with a token bucket.** A bucket tolerates the bursts that network jitter creates, where a fixed minimum gap would reject legal requests. | `Coins.bucket` / `Coins.take` |
| **Atomic data changes.** Every change goes through one `update` that edits a copy and commits only if the change succeeds. | `DataService.update` |
| **State late joiners can read.** Taken coins are attributes on a replicated folder, so a player who joins later sees the same field without extra messages. | `CoinService.publish`, `CoinController.watch` |
| **Deterministic layout.** Server and client compute the same spots from one seed with a portable integer generator, so the layout never travels over the network. | `Coins.layout` |
| **Config driven, no magic numbers.** Every tuning value lives in one config file; every network name lives in one channels file. | `src/Shared/Config` |
| **Cleanup by design.** Connections and instances are tracked and released together. | `src/Shared/Janitor.luau` |
| **Light on the frame.** All coins move in one `BulkMoveTo` call per frame. | `CoinController.step` |

The code has no comments by choice: names and small functions carry the meaning.

## Tools

| Tool | Use |
|---|---|
| [Rojo](https://rojo.space) | the project lives in files and syncs into Studio |
| [Rokit](https://github.com/rojo-rbx/rokit) | pins every tool version (`rokit.toml`) |
| [Lune](https://lune-org.github.io/docs) | runs the tests outside Roblox |
| [StyLua](https://github.com/JohnnyMorganz/StyLua) and [selene](https://github.com/Kampfkarren/selene) | formatting and lint |
| [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) | strict type checking (`--!strict` in every module) |
| GitHub Actions | runs format, lint, build and tests on every push |

## Run it

```bash
rokit install
lune run tests/run.luau
rojo serve
```

Then connect the Rojo plugin in Studio and press Play.

## Layout

```
src/
  Server/
    init.server.luau          boots the services
    Services/
      DataService.luau        player data with atomic updates
      CoinService.luau        validates pickups, pays, publishes state
  Client/
    init.client.luau          boots the controllers
    Controllers/
      CoinController.luau     draws coins, predicts pickups, reconciles
  Shared/
    Boot.luau                 module loader with ordering and a watchdog
    Coins.luau                pure rules: layout, reach, rate limit
    Net.luau                  remote events from one channel list
    Janitor.luau              cleanup
    Config/
      CoinConfig.luau
      NetworkChannels.luau
tests/
  run.luau                    small Lune test runner
  coins.spec.luau
  boot.spec.luau
```

The pure rules (`Coins`, `Boot.order`) have no Roblox dependencies, which is what lets Lune test them in milliseconds.
