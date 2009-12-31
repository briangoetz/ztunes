#
# FileHandler implements a generic file-to-file transform, which might be as simple as renaming a file from one
# location to another, or might be an arbitrary transform action (including shelling out to a helper program)
# 
class FileHandler
    # The isTransform property indicates whether any nontrivial transformation is done; if no transform is done,
    # the caller is expected to do the transform in the form of a file rename / copy command
    attr_reader :is_transform

    # A hash mapping acceptable input file types to their output types
    attr_reader :type_map

    def initialize(typeMap, isTransform = false)
        @type_map = typeMap
        @is_transform = isTransform
    end

    def outputType(file)
        @type_map[PathUtils.extension(file)]
    end

    def handles?(file)
        outputType(file) != nil
    end

    def getOutputFile(file, inputBase)
        th = MediaFile.for(file)
        return nil if !th
        wasExtn = PathUtils.extension(file)
        newExtn = outputType(file)

        f = th.fileName()
        f = PathUtils.replaceExtension(f, wasExtn, newExtn) if (wasExtn != newExtn)
        f
    end
end
