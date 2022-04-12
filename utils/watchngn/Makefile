#
# Copyright (C) 2010 segal.di.ubi.pt
# Copyright (C) 2022 ku@digitaldolphins.jp
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=watchngn
PKG_VERSION:=0
PKG_RELEASE:=3

PKG_MAINTAINER:=kenjiuno <ku@digitaldolphins.jp>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/watchngn
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Enable the configuration of programmed reboots or network interface restarts
  PKGARCH:=all
endef

define Package/watchngn/description
Restart network interfaces or reboot if pings to hosts fail, or set up periodic reboots. Configured via UCI /etc/config/watchngn
endef

define Package/watchngn/conffiles
/etc/config/watchngn
endef

define Build/Compile
endef

define Package/watchngn/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/watchngn.init $(1)/etc/init.d/watchngn
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/watchngn.sh $(1)/usr/bin/watchngn.sh
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/watchngn.config $(1)/etc/config/watchngn
endef

$(eval $(call BuildPackage,watchngn))
