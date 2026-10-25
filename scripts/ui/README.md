# UI Scripts

Scripts attached to the scenes in `scenes/ui/`. Keep them thin; game logic belongs in `core/` or `combat/`.

`build_menu.gd` builds the first-level tower selection panel from the tower
definitions available in `data/towers/`.

`tower_panel.gd` opens when a built tower is tapped and offers to sell it
for `Wallet.sell_refund` of its price (70%), freeing the build pad.

`menu_widgets.gd` holds the menu scene paths and the shared background,
page header and definition card builders used by the menus.
