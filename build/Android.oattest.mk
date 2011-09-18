#
# Copyright (C) 2011 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

########################################################################

ART_TEST_DEX_FILES :=

# $(1): directory
define build-art-test-dex
  include $(CLEAR_VARS)
  LOCAL_MODULE := art-test-dex-$(1)
  LOCAL_MODULE_TAGS := optional
  LOCAL_SRC_FILES := $(call all-java-files-under, test/$(1))
  LOCAL_JAVA_LIBRARIES := core
  LOCAL_NO_STANDARD_LIBRARIES := true
  include $(BUILD_JAVA_LIBRARY)
  ART_TEST_DEX_FILES += $(TARGET_OUT_JAVA_LIBRARIES)/$$(LOCAL_MODULE).jar
endef
$(foreach dir,$(TEST_DEX_DIRECTORIES), $(eval $(call build-art-test-dex,$(dir))))

########################################################################

ART_TEST_OAT_FILES :=

# $(1): directory
define build-art-test-oat
# TODO: change DEX2OATD to order-only prerequisite when output is stable
$(TARGET_OUT_JAVA_LIBRARIES)/art-test-dex-$(1).oat: $(TARGET_OUT_JAVA_LIBRARIES)/art-test-dex-$(1).jar $(TARGET_BOOT_OAT) $(DEX2OAT)
	@echo "target dex2oat: $$@ ($$<)"
	$(hide) $(DEX2OAT) $(addprefix --boot-dex-file=,$(TARGET_BOOT_DEX)) --boot=$(TARGET_BOOT_OAT) $(addprefix --dex-file=,$$<) --image=$$@ --strip-prefix=$(PRODUCT_OUT)

ART_TEST_OAT_FILES += $(TARGET_OUT_JAVA_LIBRARIES)/art-test-dex-$(1).oat
endef
$(foreach dir,$(TEST_DEX_DIRECTORIES), $(eval $(call build-art-test-oat,$(dir))))

########################################################################

ART_TEST_OAT_TARGETS :=

# $(1): directory
# $(2): arguments
define declare-test-test-target
.PHONY: test-art-target-oat-$(1)
test-art-target-oat-$(1): test-art-target-sync
	adb shell touch /sdcard/test-art-target-oat-$(1)
	adb shell rm /sdcard/test-art-target-oat-$(1)
	adb shell sh -c "oatexecd -Xbootclasspath:/system/framework/core.jar -Xbootimage:/system/framework/boot.oat -classpath /system/framework/art-test-dex-$(1).jar -Ximage:/system/framework/art-test-dex-$(1).oat $(1) $(2) && touch /sdcard/test-art-target-oat-$(1)"
	$(hide) (adb pull /sdcard/test-art-target-oat-$(1) /tmp/ && echo test-art-target-oat-$(1) PASSED) || (echo test-art-target-oat-$(1) FAILED && exit 1)
	$(hide) rm /tmp/test-art-target-oat-$(1)

ART_TEST_OAT_TARGETS += test-art-target-oat-$(1)
endef

$(eval $(call declare-test-test-target,HelloWorld,))
$(eval $(call declare-test-test-target,Fibonacci,10))
# TODO: enable this when manyArgs is passing (and remove compiler_test IntMath test cases)
#$(eval $(call declare-test-test-target,IntMath,))
$(eval $(call declare-test-test-target,ExceptionTest,))

########################################################################
