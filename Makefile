# freeColour install/restore
#
# v1 ships ingatellent/xovi-qmd-extensions/3.26/{changeGreenColor,addColorSelector}.qmd
# (MIT) — verified working hex-ARGB picker on rMPP and Move (issue #12).
# changeGreenColor is the enabling REPLACE on `ensureSelection`; the picker
# UI lives in addColorSelector and emits `penColorSelected(hex_rgb, ARGB)`
# directly, bypassing the colour-swatch substitution path that our v0.1
# clone of FouzR's pre-3.26 file got nowhere with.
#
# Default device is USB (10.11.99.1). Override:
#     make install DEVICE=192.168.1.112
#
# Targets:
#     install      push both qmds, back up + remove the existing changeGreenColor, restart xochitl
#     reinstall    push both qmds and restart xochitl, no backup churn
#     restore      restore the upstream changeGreenColor from .bak, drop our installed files, restart
#     uninstall    drop our installed files (does NOT restore the .bak; use restore for that)
#     status       list installed qmd extensions on the device

DEVICE   ?= 10.11.99.1
SSH       = ssh -o StrictHostKeyChecking=no root@$(DEVICE)
SCP       = scp -o StrictHostKeyChecking=no
QMD_DIR   = /home/root/xovi/exthome/qt-resource-rebuilder
EXT_CGC   = src/changeGreenColor.qmd
EXT_ACS   = src/addColorSelector.qmd

.PHONY: install reinstall restore uninstall status

install:
	@echo "==> Backing up existing changeGreenColor.qmd if present and not already backed up"
	@$(SSH) 'if [ -f $(QMD_DIR)/changeGreenColor.qmd ] && [ ! -f $(QMD_DIR)/changeGreenColor.qmd.bak ]; then cp $(QMD_DIR)/changeGreenColor.qmd $(QMD_DIR)/changeGreenColor.qmd.bak && echo "    backed up"; else echo "    skipped (already backed up or not present)"; fi'
	@echo "==> Pushing changeGreenColor.qmd (ingatellent 3.26)"
	@$(SCP) $(EXT_CGC) root@$(DEVICE):$(QMD_DIR)/changeGreenColor.qmd
	@echo "==> Pushing addColorSelector.qmd (ingatellent 3.26)"
	@$(SCP) $(EXT_ACS) root@$(DEVICE):$(QMD_DIR)/addColorSelector.qmd
	@echo "==> Cleaning up any leftover freeColour.qmd from v0.1 dead-end"
	@$(SSH) 'rm -f $(QMD_DIR)/freeColour.qmd'
	@echo "==> Restarting xochitl"
	@$(SSH) 'systemctl restart xochitl'
	@echo "==> Done. Open a notebook → tap a pen → 'Pick custom color' should appear in the colour menu."

reinstall:
	@$(SCP) $(EXT_CGC) root@$(DEVICE):$(QMD_DIR)/changeGreenColor.qmd
	@$(SCP) $(EXT_ACS) root@$(DEVICE):$(QMD_DIR)/addColorSelector.qmd
	@$(SSH) 'systemctl restart xochitl'
	@echo "==> Reinstalled."

restore:
	@echo "==> Restoring original changeGreenColor.qmd from .bak (or upstream if no backup)"
	@$(SSH) 'if [ -f $(QMD_DIR)/changeGreenColor.qmd.bak ]; then mv $(QMD_DIR)/changeGreenColor.qmd.bak $(QMD_DIR)/changeGreenColor.qmd && echo "    restored from .bak"; else curl -fsSL https://raw.githubusercontent.com/FouzR/xovi-extensions/refs/heads/main/3.26/changeGreenColor.qmd -o $(QMD_DIR)/changeGreenColor.qmd; fi'
	@echo "==> Removing our addColorSelector.qmd"
	@$(SSH) 'rm -f $(QMD_DIR)/addColorSelector.qmd'
	@echo "==> Removing leftover freeColour.qmd if present"
	@$(SSH) 'rm -f $(QMD_DIR)/freeColour.qmd'
	@$(SSH) 'systemctl restart xochitl'
	@echo "==> Restored."

uninstall:
	@$(SSH) 'rm -f $(QMD_DIR)/addColorSelector.qmd $(QMD_DIR)/freeColour.qmd'
	@$(SSH) 'systemctl restart xochitl'
	@echo "==> Uninstalled addColorSelector.qmd. (Did NOT touch changeGreenColor.qmd; run 'make restore' for that.)"

status:
	@$(SSH) 'ls -la $(QMD_DIR)/*.qmd $(QMD_DIR)/*.bak 2>/dev/null || true'
