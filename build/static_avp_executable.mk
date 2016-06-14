# See build/core/raw_executable.mk for the original.

LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_MODULE_SUFFIX := .bin

# Do not include default libc etc
LOCAL_SYSTEM_SHARED_LIBRARIES :=

ifeq ($(TARGET_IS_64_BIT),true)
LOCAL_2ND_ARCH_VAR_PREFIX := $(TARGET_2ND_ARCH_VAR_PREFIX)
else
LOCAL_2ND_ARCH_VAR_PREFIX :=
endif

include $(BUILD_SYSTEM)/binary.mk

$(LOCAL_BUILT_MODULE) : PRIVATE_TARGET_CC := $($(LOCAL_2ND_ARCH_VAR_PREFIX)TARGET_CC)
$(LOCAL_BUILT_MODULE) : PRIVATE_TARGET_LD := $($(LOCAL_2ND_ARCH_VAR_PREFIX)TARGET_LD)

$(LOCAL_BUILT_MODULE) : PRIVATE_ELF_FILE := $(intermediates)/$(PRIVATE_MODULE).elf
$(LOCAL_BUILT_MODULE) : PRIVATE_LINK_SCRIPT := $(LOCAL_NVIDIA_LINK_SCRIPT_PATH)/$(LOCAL_MODULE).x
$(LOCAL_BUILT_MODULE) : PRIVATE_RAW_EXECUTABLE_LDFLAGS :=
$(LOCAL_BUILT_MODULE) : PRIVATE_RAW_EXECUTABLE_LDFLAGS += --entry=_start --gc-sections
$(LOCAL_BUILT_MODULE) : PRIVATE_RAW_EXECUTABLE_LDFLAGS += $(LOCAL_NVIDIA_RAW_EXECUTABLE_LDFLAGS)
$(LOCAL_BUILT_MODULE) : PRIVATE_OBJCOPY_FLAGS := $(LOCAL_NVIDIA_OBJCOPY_FLAGS)

# This is a WAR until we have immplemented the missing functions in NVOs.
# Once implemented, PRIVATE_LIBS must be defined to an empty string or removed.
ifeq ($(AVP_EXTERNAL_TOOLCHAIN),)
  $(LOCAL_BUILT_MODULE) : PRIVATE_LIBS :=
else
  $(LOCAL_BUILT_MODULE) : PRIVATE_LIBS := `$(PRIVATE_TARGET_CC) -mthumb-interwork -print-libgcc-file-name`
endif

$(all_objects) : TARGET_PROJECT_INCLUDES :=
$(all_objects) : TARGET_C_INCLUDES :=
$(all_objects) : TARGET_GLOBAL_CFLAGS :=
$(all_objects) : TARGET_GLOBAL_CPPFLAGS :=

include $(NVIDIA_BASE)

$(LOCAL_BUILT_MODULE): $(all_objects) $(all_libraries)
	@echo "target Linking static AVP executable: $(PRIVATE_MODULE)"
	$(hide) mkdir -p $(dir $@)
	$(hide) $(PRIVATE_TARGET_LD) \
		$(addprefix --script ,$(PRIVATE_LINK_SCRIPT)) \
		$(PRIVATE_RAW_EXECUTABLE_LDFLAGS) \
		-static \
		-o $(PRIVATE_ELF_FILE) \
		$(PRIVATE_ALL_OBJECTS) \
		--start-group $(PRIVATE_ALL_STATIC_LIBRARIES) --end-group \
		$(PRIVATE_LIBS)
	$(hide) $(TARGET_OBJCOPY) -O binary $(PRIVATE_OBJCOPY_FLAGS) $(PRIVATE_ELF_FILE) $@

LOCAL_2ND_ARCH_VAR_PREFIX :=
