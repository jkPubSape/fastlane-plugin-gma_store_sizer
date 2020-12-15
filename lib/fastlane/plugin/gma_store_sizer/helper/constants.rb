module Fastlane
  module Helper
		class AppThinningPlistKeys
			SIZE_COMPRESSED_APP_ODR = "sizeCompressedAppAndODR".freeze
			VARIANTS = "variants".freeze
			VARIANT_NAME_SUBSTRING = "Apps/".freeze
			LIMIT_UNCOMPRESSED_INITIAL_ODR = "limitUncompressedInitialPrefetchedODR".freeze
			ON_DEMAND_RESOURCES_ASSET_PACKS = "onDemandResourcesAssetPacks".freeze
			SIZE_COMRESSED_APP = "sizeCompressedApp".freeze
			SIZE_COMRESSED_ODR = "sizeCompressedODR".freeze
			SIZE_UNCOMRESSED_APP = "sizeUncompressedApp".freeze
			SIZE_COMRESSED_APP_ODR = "sizeUncompressedAppAndODR".freeze
			SIZE_UNCOMRESSED_INITIAL_ODR = "sizeUncompressedInitialPrefetchedODR".freeze
			SIZE_UNCOMRESSED_INITIAL_ODR_EXCEEDS_LIMIT = "sizeUncompressedInitialPrefetchedODRExceedsLimit".freeze
			SIZE_UNCOMRESSED_ODR = "sizeUncompressedODR".freeze
			TAGS_UNCOMPRESSED_INITIAL_ODR = "tagsUncompressedInitialPrefetchedODR".freeze
			VARIANT_DESCRIPTORS = "variantDescriptors".freeze
			DEVICE = "device".freeze
			OS_VERSION = "os-version".freeze
		end
	end
end
