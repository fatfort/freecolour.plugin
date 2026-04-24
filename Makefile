# freeColour install/restore
#
# Default device is USB (10.11.99.1). Override:
#     make install DEVICE=192.168.1.112
#
# Targets:
#     install            push freeColour.qmd, back up + remove changeGreenColor.qmd, restart xochitl
#     reinstall          (re)push freeColour.qmd and restart xochitl, no backup churn
#     restore            put changeGreenColor.qmd back, drop freeColour.qmd, restart xochitl
#     status             list installed qmd extensions on the device
#     uninstall          drop freeColour.qmd and restart xochitl (does not restore changeGreenColor)

DEVICE  ?= 10.11.99.1
SSH      = ssh -o StrictHostKeyChecking=no root@$(DEVICE)
SCP      = scp -o StrictHostKeyChecking=no
QMD_DIR  = /home/root/xovi/exthome/qt-resource-rebuilder
EXT      = src/freeColour.qmd

.PHONY: install reinstall restore status uninstall

install:
	@echo "==> Backing up changeGreenColor.qmd if present"
	@$(SSH) 'if [ -f $(QMD_DIR)/changeGreenColor.qmd ] && [ ! -f $(QMD_DIR)/changeGreenColor.qmd.bak ]; then cp $(QMD_DIR)/changeGreenColor.qmd $(QMD_DIR)/changeGreenColor.qmd.bak && echo "    backed up"; else echo "    skipped (already backed up or not present)"; fi'
	@echo "==> Removing changeGreenColor.qmd from active extensions"
	@$(SSH) 'rm -f $(QMD_DIR)/changeGreenColor.qmd'
	@echo "==> Pushing freeColour.qmd"
	@$(SCP) $(EXT) root@$(DEVICE):$(QMD_DIR)/freeColour.qmd
	@echo "==> Restarting xochitl"
	@$(SSH) 'systemctl restart xochitl'
	@echo "==> Done. Open a notebook, switch to highlighter or shader, and check the colour palette for brown."

reinstall:
	@$(SCP) $(EXT) root@$(DEVICE):$(QMD_DIR)/freeColour.qmd
	@$(SSH) 'systemctl restart xochitl'
	@echo "==> Reinstalled."

restore:
	@echo "==> Restoring changeGreenColor.qmd"
	@$(SSH) 'if [ -f $(QMD_DIR)/changeGreenColor.qmd.bak ]; then mv $(QMD_DIR)/changeGreenColor.qmd.bak $(QMD_DIR)/changeGreenColor.qmd && echo "    restored from backup"; else echo "    no backup found — fetching from upstream"; curl -fsSL https://raw.githubusercontent.com/FouzR/xovi-extensions/refs/heads/main/3.26/changeGreenColor.qmd -o $(QMD_DIR)/changeGreenColor.qmd; fi'
	@echo "==> Removing freeColour.qmd"
	@$(SSH) 'rm -f $(QMD_DIR)/freeColour.qmd'
	@$(SSH) 'systemctl restart xochitl'
	@echo "==> Restored."

uninstall:
	@$(SSH) 'rm -f $(QMD_DIR)/freeColour.qmd'
	@$(SSH) 'systemctl restart xochitl'
	@echo "==> Uninstalled freeColour.qmd. (Did NOT restore changeGreenColor.qmd; run 'make restore' for that.)"

status:
	@$(SSH) 'ls -la $(QMD_DIR)/*.qmd $(QMD_DIR)/*.bak 2>/dev/null || true'
