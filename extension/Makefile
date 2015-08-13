# (C)2004-2010 SourceMod Development Team
# Makefile written by David "BAILOPAN" Anderson

###########################################
### EDIT THESE PATHS FOR YOUR OWN SETUP ###
###########################################

#HL2SDK_ORIG = ../../hl2sdks/hl2sdk
#HL2SDK_OB = ../../hl2sdks/hl2sdk-ob
#HL2SDK_CSS = ../../hl2sdks/hl2sdk-css
#HL2SDK_HL2DM = ../../hl2sdks/hl2sdk-hl2dm
#HL2SDK_DODS = ../../hl2sdks/hl2sdk-dods
#HL2SDK_2013 = ../../hl2sdks/hl2sdk-2013
#HL2SDK_L4D = ../../hl2sdks/hl2sdk-l4d
#HL2SDK_ND = ../../hl2sdks/hl2sdk-nd
#HL2SDK_L4D2 = ../../hl2sdks/hl2sdk-l4d2
#HL2SDK_BLADE = ../../hl2sdks/hl2sdk-blade
#HL2SDK_INSURGENCY = ../../hl2sdks/hl2sdk-insurgency
#HL2SDK_CSGO = ../../hl2sdks/hl2sdk-csgo
HL2SDK_TF2 = ../hl2sdk-tf2

SMSDK = ../sourcemod-1.8
MMSOURCE = ../metamod-source-1.11-dev

#####################################
### EDIT BELOW FOR OTHER PROJECTS ###
#####################################

PROJECT = tank

#Uncomment for Metamod: Source enabled extension
USEMETA = true

OBJECTS = sdk/smsdk_ext.cpp extension.cpp CDetour/detours.cpp asm/asm.c

ENGINE = tf2

INCLUDE += -I. -I.. -Isdk -I$(SMSDK)/public -I$(SMSDK)/public/extensions -I$(SMSDK)/sourcepawn/include

##############################################
### CONFIGURE ANY OTHER FLAGS/OPTIONS HERE ###
##############################################

C_OPT_FLAGS = -DNDEBUG -O3 -funroll-loops -pipe -fno-strict-aliasing
C_DEBUG_FLAGS = -D_DEBUG -DDEBUG -g -ggdb3
C_GCC4_FLAGS = -fvisibility=hidden
CPP_GCC4_FLAGS = -fvisibility-inlines-hidden
CPP = gcc
CPP_OSX = clang

##########################
### SDK CONFIGURATIONS ###
##########################

override ENGSET = false

# Check for valid list of engines
ifneq (,$(filter original orangebox css hl2dm dods sdk2013 tf2 left4dead nd left4dead2 blade insurgency csgo,$(ENGINE)))
	override ENGSET = true
endif

OS := $(shell uname -s)

ifeq "$(OS)" "Darwin"
	LIB_EXT = dylib
	ifeq "$(ENGINE)" "sdk2013"
		HL2LIB = $(HL2SDK)/lib/public/osx32
	else
		HL2LIB = $(HL2SDK)/lib/mac
	endif
else
	LIB_EXT = so
	ifeq "$(ENGINE)" "original"
		HL2LIB = $(HL2SDK)/linux_sdk
	else ifeq "$(ENGINE)" "sdk2013"
		HL2LIB = $(HL2SDK)/lib/public/linux32
	else
		HL2LIB = $(HL2SDK)/lib/linux
	endif
endif

ifeq "$(ENGINE)" "original"
	HL2SDK = $(HL2SDK_ORIG)
	CFLAGS += -DSOURCE_ENGINE=1
	LIB_SUFFIX = _i486.$(LIB_EXT)
	BUILD_SUFFIX = .1.ep1
endif
ifeq "$(ENGINE)" "orangebox"
	HL2SDK = $(HL2SDK_OB)
	CFLAGS += -DSOURCE_ENGINE=3
	LIB_SUFFIX = _i486.$(LIB_EXT)
	BUILD_SUFFIX = .2.ep2
endif
ifeq "$(ENGINE)" "css"
	HL2SDK = $(HL2SDK_CSS)
	CFLAGS += -DSOURCE_ENGINE=6
	LIB_PREFIX = lib
	LIB_SUFFIX = _srv.$(LIB_EXT)
	BUILD_SUFFIX = .2.css
endif
ifeq "$(ENGINE)" "hl2dm"
	HL2SDK = $(HL2SDK_HL2DM)
	CFLAGS += -DSOURCE_ENGINE=7
	LIB_PREFIX = lib
	LIB_SUFFIX = _srv.$(LIB_EXT)
	BUILD_SUFFIX = .2.hl2dm
endif
ifeq "$(ENGINE)" "dods"
	HL2SDK = $(HL2SDK_DODS)
	CFLAGS += -DSOURCE_ENGINE=8
	LIB_PREFIX = lib
	LIB_SUFFIX = _srv.$(LIB_EXT)
	BUILD_SUFFIX = .2.dods
endif
ifeq "$(ENGINE)" "sdk2013"
	HL2SDK = $(HL2SDK_2013)
	CFLAGS += -DSOURCE_ENGINE=9
	LIB_PREFIX = lib
	LIB_SUFFIX = _srv.$(LIB_EXT)
	BUILD_SUFFIX = .2.sdk2013
endif
ifeq "$(ENGINE)" "tf2"
	HL2SDK = $(HL2SDK_TF2)
	CFLAGS += -DSOURCE_ENGINE=10
	LIB_PREFIX = lib
	LIB_SUFFIX = _srv.$(LIB_EXT)
	BUILD_SUFFIX = .2.tf2
endif
ifeq "$(ENGINE)" "left4dead"
	HL2SDK = $(HL2SDK_L4D)
	CFLAGS += -DSOURCE_ENGINE=11
	LIB_PREFIX = lib
	LIB_SUFFIX = .$(LIB_EXT)
	BUILD_SUFFIX = .2.l4d
endif
ifeq "$(ENGINE)" "nd"
	HL2SDK = $(HL2SDK_ND)
	CFLAGS += -DSOURCE_ENGINE=12
	LIB_PREFIX = lib
	LIB_SUFFIX = _srv.$(LIB_EXT)
	BUILD_SUFFIX = .2.nd
endif
ifeq "$(ENGINE)" "left4dead2"
	HL2SDK = $(HL2SDK_L4D2)
	CFLAGS += -DSOURCE_ENGINE=13
	LIB_PREFIX = lib
	LIB_SUFFIX = _srv.$(LIB_EXT)
	BUILD_SUFFIX = .2.l4d2
endif
ifeq "$(ENGINE)" "blade"
	HL2SDK = $(HL2SDK_BLADE)
	CFLAGS += -DSOURCE_ENGINE=16
	LIB_PREFIX = lib
	LIB_SUFFIX = .$(LIB_EXT)
	BUILD_SUFFIX = .2.blade
endif
ifeq "$(ENGINE)" "insurgency"
	HL2SDK = $(HL2SDK_INSURGENCY)
	CFLAGS += -DSOURCE_ENGINE=17
	LIB_PREFIX = lib
	LIB_SUFFIX = .$(LIB_EXT)
	BUILD_SUFFIX = .2.insurgency
endif
ifeq "$(ENGINE)" "csgo"
	HL2SDK = $(HL2SDK_CSGO)
	CFLAGS += -DSOURCE_ENGINE=18
	LIB_PREFIX = lib
	LIB_SUFFIX = .$(LIB_EXT)
	BUILD_SUFFIX = .2.csgo
endif
HL2PUB = $(HL2SDK)/public

ifeq "$(ENGINE)" "original"
	INCLUDE += -I$(HL2SDK)/public/dlls
	METAMOD = $(MMSOURCE)/core-legacy
else
	INCLUDE += -I$(HL2SDK)/public/game/server
	METAMOD = $(MMSOURCE)/core
endif

ifeq "$(USEMETA)" "true"

	ifeq "$(OS)" "Darwin"
		ifeq "$(ENGINE)" "sdk2013"
			LINK = $(HL2LIB)/tier1.a $(HL2LIB)/mathlib.a libvstdlib.dylib libtier0.dylib
			CFLAGS += -liconv
		else
			LINK = $(HL2LIB)/tier1_i486.a $(HL2LIB)/mathlib_i486.a libvstdlib.dylib libtier0.dylib
		endif
		ifneq (,$(filter insurgency csgo,$(ENGINE)))
			LINK += $(HL2LIB)/interfaces_i486.a
		endif
	else
		ifneq (,$(filter css hl2dm dods tf2 l4d2 nd,$(ENGINE)))
			LINK = $(HL2LIB)/tier1_i486.a $(HL2LIB)/mathlib_i486.a libvstdlib_srv.so libtier0_srv.so
		else ifneq (,$(filter l4d blade insurgency csgo,$(ENGINE)))
			LINK = $(HL2LIB)/tier1_i486.a $(HL2LIB)/mathlib_i486.a libvstdlib.so libtier0.so
			ifneq (,$(filter blade insurgency csgo,$(ENGINE)))
				LINK += $(HL2LIB)/interfaces_i486.a
			endif
		else ifeq "$(ENGINE)" "sdk2013"
			LINK = $(HL2LIB)/tier1.a $(HL2LIB)/mathlib.a libvstdlib_srv.so libtier0_srv.so
		else
			LINK = $(HL2LIB)/tier1_i486.a $(HL2LIB)/mathlib_i486.a vstdlib_i486.so tier0_i486.so
		endif

	endif

	INCLUDE += -I$(HL2PUB) -I$(HL2PUB)/engine -I$(HL2PUB)/tier0 -I$(HL2PUB)/tier1 -I$(METAMOD) \
		-I$(METAMOD)/sourcehook 
	CFLAGS += -DSE_EPISODEONE=1 -DSE_DARKMESSIAH=2 -DSE_ORANGEBOX=3 -DSE_BLOODYGOODTIME=4 -DSE_EYE=5 \
		-DSE_CSS=6 -DSE_HL2DM=7 -DSE_DODS=8 -DSE_SDK2013=9 -DSE_TF2=10 -DSE_LEFT4DEAD=11 -DSE_NUCLEARDAWN=12 \
		-DSE_LEFT4DEAD2=13 -DSE_ALIENSWARM=14 -DSE_PORTAL2=15 -DSE_BLADE=16 -DSE_INSURGENCY=17 \
		-DSE_CSGO=18 -DSE_DOTA=19
endif

LINK += -m32 -lm -ldl

CFLAGS += -DPOSIX -D_alloca=alloca -DCOMPILER_GCC -Wall -Werror -Wno-overloaded-virtual -Wno-switch -Wno-unused \
	-msse -DSOURCEMOD_BUILD -DHAVE_STDINT_H -m32 -std=c++11 -Wno-array-bounds

ifneq "$(ENGINE)" "sdk2013"
	CFLAGS += -Dstricmp=strcasecmp -Dstrcmpi=strcasecmp -D_stricmp=strcasecmp -D_strnicmp=strncasecmp -Dstrnicmp=strncasecmp \
	-D_snprintf=snprintf -D_vsnprintf=vsnprintf 
endif

CPPFLAGS += -Wno-non-virtual-dtor -fno-exceptions -fno-rtti

################################################
### DO NOT EDIT BELOW HERE FOR MOST PROJECTS ###
################################################

BINARY = $(PROJECT).ext$(BUILD_SUFFIX).$(LIB_EXT)

ifeq "$(DEBUG)" "true"
	BIN_DIR = Debug
	CFLAGS += $(C_DEBUG_FLAGS)
else
	BIN_DIR = Release
	CFLAGS += $(C_OPT_FLAGS)
endif

ifeq "$(USEMETA)" "true"
	BIN_DIR := $(BIN_DIR).$(ENGINE)
endif

ifeq "$(OS)" "Darwin"
	CPP = $(CPP_OSX)
	LIB_EXT = dylib
	CFLAGS += -DOSX -D_OSX
	LINK += -dynamiclib -lstdc++ -mmacosx-version-min=10.5
else
	LIB_EXT = so
	CFLAGS += -D_LINUX
	LINK += -shared
endif

IS_CLANG := $(shell $(CPP) --version | head -1 | grep clang > /dev/null && echo "1" || echo "0")

ifeq "$(IS_CLANG)" "1"
	CPP_MAJOR := $(shell $(CPP) --version | grep clang | sed "s/.*version \([0-9]\)*\.[0-9]*.*/\1/")
	CPP_MINOR := $(shell $(CPP) --version | grep clang | sed "s/.*version [0-9]*\.\([0-9]\)*.*/\1/")
else
	CPP_MAJOR := $(shell $(CPP) -dumpversion >&1 | cut -b1)
	CPP_MINOR := $(shell $(CPP) -dumpversion >&1 | cut -b3)
endif

# If not clang
ifeq "$(IS_CLANG)" "0"
	CFLAGS += -mfpmath=sse -DGNUC
endif

# Clang || GCC >= 4
ifeq "$(shell expr $(IS_CLANG) \| $(CPP_MAJOR) \>= 4)" "1"
	CFLAGS += $(C_GCC4_FLAGS)
	CPPFLAGS += $(CPP_GCC4_FLAGS)
endif

# Clang >= 3 || GCC >= 4.7
ifeq "$(shell expr $(IS_CLANG) \& $(CPP_MAJOR) \>= 3 \| $(CPP_MAJOR) \>= 4 \& $(CPP_MINOR) \>= 7)" "1"
	CFLAGS += -Wno-delete-non-virtual-dtor
endif

# OS is Linux and not using clang
ifeq "$(shell expr $(OS) \= Linux \& $(IS_CLANG) \= 0)" "1"
	LINK += -static-libgcc
endif

OBJ_BIN := $(OBJECTS:%.cpp=$(BIN_DIR)/%.o)

# This will break if we include other Makefiles, but is fine for now. It allows
#  us to make a copy of this file that uses altered paths (ie. Makefile.mine)
#  or other changes without mucking up the original.
MAKEFILE_NAME := $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))

$(BIN_DIR)/%.o: %.cpp
	$(CPP) $(INCLUDE) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

all: check
	mkdir -p $(BIN_DIR)/sdk
	mkdir -p $(BIN_DIR)/CDetour
	if [ "$(USEMETA)" = "true" ]; then \
		ln -sf $(HL2LIB)/$(LIB_PREFIX)vstdlib$(LIB_SUFFIX); \
		ln -sf $(HL2LIB)/$(LIB_PREFIX)tier0$(LIB_SUFFIX); \
	fi
	$(MAKE) -f $(MAKEFILE_NAME) extension

check:
	if [ "$(USEMETA)" = "true" ] && [ "$(ENGSET)" = "false" ]; then \
		echo "You must supply one of the following values for ENGINE:"; \
		echo "blade, csgo, css, dods, hl2dm, insurgency, left4dead, left4dead2, nd, orangebox, original, sdk2013, or tf2"; \
		exit 1; \
	fi

extension: check $(OBJ_BIN)
	$(CPP) $(INCLUDE) $(OBJ_BIN) $(LINK) -o $(BIN_DIR)/$(BINARY)

debug:
	$(MAKE) -f $(MAKEFILE_NAME) all DEBUG=true

default: all

clean: check
	rm -rf $(BIN_DIR)/*.o
	rm -rf $(BIN_DIR)/sdk/*.o
	rm -rf $(BIN_DIR)/CDetour/*.o
	rm -rf $(BIN_DIR)/$(BINARY)

