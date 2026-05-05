# freeColour install/restore
#
# Ships:
#   - src/changeGreenColor.qmd  (vendored from ingatellent, MIT — enabling
#                                REPLACE on ensureSelection so tools can
#                                hold color=ARGB(9) + custom colorCode)
#   - build/freeColour.qmd      (ours — preset palette + neutral default,
#                                forked from ingatellent's addColorSelector
#                                via bin/compile-qmd.sh)
#
# Picker now uses a 2-row 5+4 grid for the 8 recents + rainbow swatch, so
# it survives the narrower landscape pen menu on Porsche.
#
# A patched floating.qmd (build/floating.qmd via bin/patch-floating.py)
# exists in this repo as an experiment to swap the QuickTools 4-button
# column for a 2x2 grid, but pushing it caused other pen selectors in
# Toolbar.qml to disappear on Ferrari (the GridLayout swap evidently
# breaks something Foldout/PenTool depends on). The install/reinstall
# targets no longer push it. Keep the script around for later iteration.
#
# Default device is USB (10.11.99.1). Override:
#     make install DEVICE=192.168.1.112
#
# Targets:
#     compile      compile src/freeColour.qml-diff -> build/freeColour.qmd
#     install      compile + push both qmds, back up + remove existing
#                  changeGreenColor + addColorSelector, restart xochitl
#     reinstall    recompile + push, restart, no backup churn
#     restore      restore the upstream changeGreenColor from .bak (and
#                  floating.qmd from .bak if one exists from a prior
#                  install), drop our installed files, restart
#     uninstall    drop our installed files; restore floating.qmd from .bak
#                  if present (does NOT restore changeGreenColor; use
#                  restore for that)
#     status       list installed qmd extensions on the device
#     decompile    decompile src/addColorSelector.qmd to /tmp for reading

DEVICE   ?= 10.11.99.1
SSH       = ssh -o StrictHostKeyChecking=no root@$(DEVICE)
SCP       = scp -o StrictHostKeyChecking=no
QMD_DIR   = /home/root/xovi/exthome/qt-resource-rebuilder
EXT_CGC   = src/changeGreenColor.qmd
EXT_FCL   = build/freeColour.qmd
SRC_FCL   = src/freeColour.qml-diff
QMLDIFF  ?= $(HOME)/src/qmldiff/target/release/qmldiff

.PHONY: compile install reinstall restore uninstall status decompile

compile: $(EXT_FCL)

$(EXT_FCL): $(SRC_FCL) reference/hashtab bin/compile-qmd.sh
	@bin/compile-qmd.sh $(SRC_FCL)

install: compile
	@echo "==> Backing up existing changeGreenColor.qmd if present and not already backed up"
	@$(SSH) 'if [ -f $(QMD_DIR)/changeGreenColor.qmd ] && [ ! -f $(QMD_DIR)/changeGreenColor.qmd.bak ]; then cp $(QMD_DIR)/changeGreenColor.qmd $(QMD_DIR)/changeGreenColor.qmd.bak && echo "    backed up"; else echo "    skipped (already backed up or not present)"; fi'
	@echo "==> Pushing changeGreenColor.qmd (ingatellent 3.26)"
	@$(SCP) $(EXT_CGC) root@$(DEVICE):$(QMD_DIR)/changeGreenColor.qmd
	@echo "==> Pushing freeColour.qmd (presets + neutral default)"
	@$(SCP) $(EXT_FCL) root@$(DEVICE):$(QMD_DIR)/freeColour.qmd
	@echo "==> Removing upstream addColorSelector.qmd (replaced by freeColour.qmd)"
	@$(SSH) 'rm -f $(QMD_DIR)/addColorSelector.qmd'
	@echo "==> Restarting xochitl"
	@$(SSH) 'systemctl restart xochitl'
	@echo "==> Done. Open a notebook → tap a pen → 'Pick custom color' should show 8 preset swatches plus a hex field defaulted to FFFFFFFF."

reinstall: compile
	@$(SCP) $(EXT_CGC) root@$(DEVICE):$(QMD_DIR)/changeGreenColor.qmd
	@$(SCP) $(EXT_FCL) root@$(DEVICE):$(QMD_DIR)/freeColour.qmd
	@$(SSH) 'rm -f $(QMD_DIR)/addColorSelector.qmd'
	@$(SSH) 'systemctl restart xochitl'
	@echo "==> Reinstalled."

restore:
	@echo "==> Restoring original changeGreenColor.qmd from .bak (or upstream if no backup)"
	@$(SSH) 'if [ -f $(QMD_DIR)/changeGreenColor.qmd.bak ]; then mv $(QMD_DIR)/changeGreenColor.qmd.bak $(QMD_DIR)/changeGreenColor.qmd && echo "    restored from .bak"; else curl -fsSL https://raw.githubusercontent.com/FouzR/xovi-extensions/refs/heads/main/3.26/changeGreenColor.qmd -o $(QMD_DIR)/changeGreenColor.qmd; fi'
	@echo "==> Restoring floating.qmd from .bak if present"
	@$(SSH) 'if [ -f $(QMD_DIR)/floating.qmd.bak ]; then mv $(QMD_DIR)/floating.qmd.bak $(QMD_DIR)/floating.qmd && echo "    restored from .bak"; else echo "    no .bak, leaving floating.qmd alone"; fi'
	@echo "==> Removing our freeColour.qmd and any leftover addColorSelector.qmd"
	@$(SSH) 'rm -f $(QMD_DIR)/freeColour.qmd $(QMD_DIR)/addColorSelector.qmd'
	@$(SSH) 'systemctl restart xochitl'
	@echo "==> Restored."

uninstall:
	@$(SSH) 'rm -f $(QMD_DIR)/freeColour.qmd $(QMD_DIR)/addColorSelector.qmd'
	@$(SSH) 'if [ -f $(QMD_DIR)/floating.qmd.bak ]; then mv $(QMD_DIR)/floating.qmd.bak $(QMD_DIR)/floating.qmd && echo "    restored floating.qmd from .bak"; fi'
	@$(SSH) 'systemctl restart xochitl'
	@echo "==> Uninstalled. (Did NOT touch changeGreenColor.qmd; run 'make restore' for that.)"

status:
	@$(SSH) 'ls -la $(QMD_DIR)/*.qmd $(QMD_DIR)/*.bak 2>/dev/null || true'

decompile:
	@cp src/addColorSelector.qmd /tmp/addColorSelector-decomp.qmd
	@$(QMLDIFF) hash-diffs -r reference/hashtab /tmp/addColorSelector-decomp.qmd
	@echo "Decompiled to /tmp/addColorSelector-decomp.qmd"
