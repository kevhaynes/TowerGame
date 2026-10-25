# UI Scripts

Scripts attached to the scenes in `scenes/ui/`. Keep them thin; game logic belongs in `core/` or `combat/`.

`build_menu.gd` builds the first-level tower selection panel from the tower
definitions available in `data/towers/`.

`menu_widgets.gd` holds the menu scene paths and the shared background,
page header and definition card builders used by the menus.
