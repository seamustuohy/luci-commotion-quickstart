# Copyright (C) 2013 Open Technology Institute
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
include $(TOPDIR)/rules.mk

PKG_NAME:=commotion-quick-start
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/ipkg-install

include $(INCLUDE_DIR)/package.mk

define Package/commotion-quick-start
  SECTION:=commotion
  CATEGORY:=Commotion
  TITLE:=Commotion Quick Start Wizard
  DEPENDS:=+commotionbase
  URL:=http://commotionwireless.net
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/commotion-quick-start/description
  Commotion rapid-deployment infrastructure
endef

define Package/commotion-quick-start/install
	echo "Testing"
	$(CP) -a ./files/* $(1)/ || true
endef

$(eval $(call BuildPackage,commotion-quick-start))
