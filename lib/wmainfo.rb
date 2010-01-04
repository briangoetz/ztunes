# = Description
#
# wmainfo-ruby gives you access to low level information on wma/wmv/asf files.
# * It identifies all "ASF_..." objects and shows each objects size
# * It returns info such as bitrate, size, length, creation date etc
# * It returns meta-tags from ASF_Content_Description_Object
#
# = Note:
#
# I wrestled with the ASF spec (150 page .doc format!) with no joy for
# a while, then found Dan Sully's Audio-WMA Perl module:
# (http://cpants.perl.org/dist/Audio-WMA :: http://www.slimdevices.com/)
# This entire library is essentially a translation of (parts of) WMA.pm
# to Ruby. All credit for the hard work is owed to Dan...
#
# License:: Ruby
# Author:: Darren Kirby (mailto:bulliver@badcomputer.org)
# Website:: http://badcomputer.org/unix/code/wmainfo/

# Improved character encoding handling thanks to
# Guillaume Pierronnet <guillaume.pierronnet @nospam@ gmail.com>

require 'iconv'

# raised when errors occur parsing wma header
class WmaInfoError < StandardError
end

class WmaInfo
  # WmaInfo.tags and WmaInfo.info are hashes of NAME=VALUE pairs
  # WmaInfo.header_object is a hash of arrays
  attr_reader :tags, :header_object, :info, :ext_info, :stream
  def initialize(file, opts = {})
    @drm = nil
    @tags = {}
    @header_object = {}
    @info = {}
    @ext_info = {}
    @stream = {}
    @file = file
    @debug = opts[:debug]
    @ic = Iconv.new(opts[:encoding] || "ASCII", "UTF-16LE")
    parse_wma_header
  end

  # for ASF_Header_Object prints: "name: GUID size num_objects"
  # for others, prints: "name: GUID size offset"
  def print_objects
    @header_object.each_pair do |key,val|
      puts "#{key}: #{val[0]} #{val[1]} #{val[2]}"
    end
  end

  # returns true if the file has DRM
  # ie: if a "*Content_Encryption_Object" is found
  def hasdrm?
    @drm ? true : false
  end

  # returns true if tags["tag"] has a value
  def hastag?(tag)
    @tags[tag] ? true : false
  end

  # prettyprint WmaInfo.tags hash
  def print_tags
    @tags.each_pair { |key,val| puts "#{key}: #{val}" }
  end

  # returns true if info["field"] has a value
  def hasinfo?(field)
    @info[field] ? true : false
  end

  # prettyprint WmaInfo.info hash
  def print_info
    @info.each_pair { |key,val| puts "#{key}: #{val}" }
  end

  # prettyprint WmaInfo.stream hash
  def print_stream
    @stream.each_pair { |key,val| puts "#{key}: #{val}" }
  end

  # returns: "filename.wma :: Size: N bytes :: Bitrate: N kbps :: Duration: N seconds"
  # this is useless
  def to_s
    "#{File.basename(@file)} :: Size: #{@size} bytes :: Bitrate: #{@info['bitrate']} kbps :: Duration: #{@info['playtime_seconds']} seconds"
  end

  #--
  #  This cleans up the output when using WmaInfo in irb
  def inspect #:nodoc:
    s = "#<#{self.class}:0x#{(self.object_id*2).to_s(16)} "
    @header_object.each_pair do |k,v|
      s += "(#{k.upcase} size=#{v[1]} offset=#{v[2]}) " unless k == "ASF_Header_Object"
    end
    s += "\b>"
  end
  #++

  private
  def parse_wma_header
    @size = File.size(@file)
    @fh = File.new(@file, "rb")
    @offset = 0
    @file_offset = 30
    @guid_mapping = known_guids
    @reverse_guid_mapping = @guid_mapping.invert

    # read first 30 bytes and parse ASF_Header_Object
    begin
      object_id       = byte_string_to_guid(@fh.read(16))
      object_size     = @fh.read(8).unpack("V")[0]
      header_objects  = @fh.read(4).unpack("V")[0]
      reserved1       = @fh.read(1).unpack("b*")[0]
      reserved2       = @fh.read(1).unpack("b*")[0]
      object_id_name  = @reverse_guid_mapping[object_id]
    rescue
      # not getting raised when fed a non-wma file
      # object_size must be getting value because
      # "Header size reported larger than file size"
      # gets raised instead?
      raise WmaInfoError, "Not a wma header", caller
    end

    if object_size > @size
      raise WmaInfoError, "Header size reported larger than file size", caller
    end

    @header_object[object_id_name] = [object_id,  object_size, header_objects, reserved1, reserved2]

    if @debug
      puts "object_id:       #{object_id}"
      puts "object_id_name:  #{@reverse_guid_mapping[object_id]}"
      puts "object_size:     #{object_size}"
      puts "header_objects:  #{header_objects}"
      puts "reserved1:       #{reserved1}"
      puts "reserved2:       #{reserved2}"
    end

    @header_data = @fh.read(object_size - 30)
    @fh.close
    header_objects.times do
      next_object      = read_and_increment_offset(16)
      next_object_text = byte_string_to_guid(next_object)
      next_object_size = parse_64bit_string(read_and_increment_offset(8))
      next_object_name = @reverse_guid_mapping[next_object_text];

      @header_object[next_object_name] = [next_object_text, next_object_size, @file_offset]
      @file_offset += next_object_size

      if @debug
        puts "next_objectGUID: #{next_object_text}"
        puts "next_object_name: #{next_object_name}"
        puts "next_object_size: #{next_object_size}"
      end

      # start looking at object contents
      if next_object_name == 'ASF_File_Properties_Object'
        parse_asf_file_properties_object
        next
      elsif next_object_name == 'ASF_Content_Description_Object'
        parse_asf_content_description_object
        next
      elsif next_object_name == 'ASF_Extended_Content_Description_Object'
        parse_asf_extended_content_description_object
        next
      elsif next_object_name == 'ASF_Stream_Properties_Object'
        parse_asf_stream_properties_object
        next
      elsif next_object_name == 'ASF_Content_Encryption_Object' || next_object_name == 'ASF_Extended_Content_Encryption_Object'
        parse_asf_content_encryption_object
      end

      # set our next object size
      @offset += next_object_size - 24
    end

    # meta-tag like values go to 'tags' all others to 'info'
    @ext_info.each do |k,v|
      if k =~ /WM\/(TrackNumber|AlbumTitle|AlbumArtist|Genre|Year|Composer|Mood|Lyrics|BeatsPerMinute|Publisher)/
        @tags[k.gsub(/WM\//, "")] = v # dump "WM/"
      else
        @info[k] = v
      end
    end

    # dump empty tags
    @tags.delete_if { |k,v| v == "" || v == nil }
  end

  def parse_asf_content_encryption_object 
    @drm = 1
  end

  def parse_asf_file_properties_object
    fileid                      = read_and_increment_offset(16)
    @info['fileid_guid']        = byte_string_to_guid(fileid)
    @info['filesize']           = parse_64bit_string(read_and_increment_offset(8))
    @info['creation_date']      = read_and_increment_offset(8).unpack("Q")[0]
    @info['creation_date_unix'] = file_time_to_unix_time(@info['creation_date'])
    @info['creation_string']    = Time.at(@info['creation_date_unix'].to_i)
    @info['data_packets']       = read_and_increment_offset(8).unpack("V")[0]
    @info['play_duration']      = parse_64bit_string(read_and_increment_offset(8))
    @info['send_duration']      = parse_64bit_string(read_and_increment_offset(8))
    @info['preroll']            = read_and_increment_offset(8).unpack("V")[0]
    @info['playtime_seconds']   = (@info['play_duration'] / 10000000) - (@info['preroll'] / 1000)
    flags_raw                   = read_and_increment_offset(4).unpack("V")[0]
    if flags_raw & 0x0001 == 0
      @info['broadcast']        = 0
    else
      @info['broadcast']        = 1
    end
    if flags_raw & 0x0002 == 0
      @info['seekable']         = 0
    else
      @info['seekable']         = 1
    end
    @info['min_packet_size']    = read_and_increment_offset(4).unpack("V")[0]
    @info['max_packet_size']    = read_and_increment_offset(4).unpack("V")[0]
    @info['max_bitrate']        = read_and_increment_offset(4).unpack("V")[0]
    @info['bitrate']            = @info['max_bitrate'] / 1000

    if @debug
      @info.each_pair { |key,val| puts "#{key}: #{val}" }
    end

  end

  def parse_asf_content_description_object
    lengths = {}
    keys = %w/Title Author Copyright Description Rating/
    keys.each do |key| # read the lengths of each key
      lengths[key] = read_and_increment_offset(2).unpack("v")[0]
    end
    keys.each do |key| # now pull the data based on length
      begin
          data = read_and_increment_offset(lengths[key])
          @tags[key] = decode_binary_string(data)
      rescue
          @tags[key] = "Unavailable (iconv decode error)"
      end
    end
  end

  def parse_asf_extended_content_description_object
    @ext_info = {}
    @ext_info['content_count'] = read_and_increment_offset(2).unpack("v")[0]
    @ext_info['content_count'].times do |n|
      ext = {}
      ext['base_offset']  = @offset + 30
      ext['name_length']  = read_and_increment_offset(2).unpack("v")[0]
      ext['name']         = decode_binary_string(read_and_increment_offset(ext['name_length']))
      ext['value_type']   = read_and_increment_offset(2).unpack("v")[0]
      ext['value_length'] = read_and_increment_offset(2).unpack("v")[0]

      value = read_and_increment_offset(ext['value_length'])
      if ext['value_type'] <= 1
        begin
            ext['value'] = decode_binary_string(value)
        rescue
            ext['value'] = "Unavailable (iconv decode error)"
        end
      elsif ext['value_type'] == 4
        ext['value'] = parse_64bit_string(value)
      else
        value_type_template = ["", "", "V", "V", "", "v"]
        ext['value'] = value.unpack(value_type_template[ext['value_type']])[0]
      end

      if @debug
        puts "base_offset:  #{ext['base_offset']}"
        puts "name length:  #{ext['name_length']}"
        puts "name:         #{ext['name']}"
        puts "value type:   #{ext['value_type']}"
        puts "value length: #{ext['value_length']}"
        puts "value:        #{ext['value']}"
      end

      @ext_info["#{ext['name']}"] = ext['value']
    end
  end

  def parse_asf_stream_properties_object

    streamType                    = read_and_increment_offset(16)
    @stream['stream_type_guid']   = byte_string_to_guid(streamType)
    @stream['stream_type_name']   = @reverse_guid_mapping[@stream['stream_type_guid']]
    errorType                     = read_and_increment_offset(16)
    @stream['error_correct_guid'] = byte_string_to_guid(errorType)
    @stream['error_correct_name'] = @reverse_guid_mapping[@stream['error_correct_guid']]

    @stream['time_offset']        = read_and_increment_offset(8).unpack("4v")[0]
    @stream['type_data_length']   = read_and_increment_offset(4).unpack("2v")[0]
    @stream['error_data_length']  = read_and_increment_offset(4).unpack("2v")[0]
    flags_raw                     = read_and_increment_offset(2).unpack("v")[0]
    @stream['stream_number']      = flags_raw & 0x007F
    @stream['encrypted']          = flags_raw & 0x8000

    # reserved - set to zero
    read_and_increment_offset(4)

    @stream['type_specific_data'] = read_and_increment_offset(@stream['type_data_length'])
    @stream['error_correct_data'] = read_and_increment_offset(@stream['error_data_length'])

    if @stream['stream_type_name'] == 'ASF_Audio_Media'
      parse_asf_audio_media_object
    end
  end

  def parse_asf_audio_media_object
    data = @stream['type_specific_data'][0...16]
    @stream['audio_channels']        = data[2...4].unpack("v")[0]
    @stream['audio_sample_rate']     = data[4...8].unpack("2v")[0]
    @stream['audio_bitrate']         = data[8...12].unpack("2v")[0] * 8
    @stream['audio_bits_per_sample'] = data[14...16].unpack("v")[0]
  end

  # UTF16LE -> ASCII
  def decode_binary_string(data)
    @ic.iconv(data).strip
  end

  def read_and_increment_offset(size)
    value = @header_data[@offset...(@offset + size)]
    @offset += size
    return value
  end

  def byte_string_to_guid(byteString)
    guidString  = sprintf("%02X", byteString[3])
    guidString += sprintf("%02X", byteString[2])
    guidString += sprintf("%02X", byteString[1])
    guidString += sprintf("%02X", byteString[0])
    guidString += '-'
    guidString += sprintf("%02X", byteString[5])
    guidString += sprintf("%02X", byteString[4])
    guidString += '-'
    guidString += sprintf("%02X", byteString[7])
    guidString += sprintf("%02X", byteString[6])
    guidString += '-'
    guidString += sprintf("%02X", byteString[8])
    guidString += sprintf("%02X", byteString[9])
    guidString += '-'
    guidString += sprintf("%02X", byteString[10])
    guidString += sprintf("%02X", byteString[11])
    guidString += sprintf("%02X", byteString[12])
    guidString += sprintf("%02X", byteString[13])
    guidString += sprintf("%02X", byteString[14])
    guidString += sprintf("%02X", byteString[15])
  end

  def parse_64bit_string(data)
    d = data.unpack('VV')
    d[1] * 2 ** 32 + d[0]
  end

  def file_time_to_unix_time(time)
    (time - 116444736000000000) / 10000000
  end

  def known_guids
    guid_mapping = {
        'ASF_Extended_Stream_Properties_Object'   => '14E6A5CB-C672-4332-8399-A96952065B5A',
        'ASF_Padding_Object'                      => '1806D474-CADF-4509-A4BA-9AABCB96AAE8',
        'ASF_Payload_Ext_Syst_Pixel_Aspect_Ratio' => '1B1EE554-F9EA-4BC8-821A-376B74E4C4B8',
        'ASF_Script_Command_Object'               => '1EFB1A30-0B62-11D0-A39B-00A0C90348F6',
        'ASF_No_Error_Correction'                 => '20FB5700-5B55-11CF-A8FD-00805F5C442B',
        'ASF_Content_Branding_Object'             => '2211B3FA-BD23-11D2-B4B7-00A0C955FC6E',
        'ASF_Content_Encryption_Object'           => '2211B3FB-BD23-11D2-B4B7-00A0C955FC6E',
        'ASF_Digital_Signature_Object'            => '2211B3FC-BD23-11D2-B4B7-00A0C955FC6E',
        'ASF_Extended_Content_Encryption_Object'  => '298AE614-2622-4C17-B935-DAE07EE9289C',
        'ASF_Simple_Index_Object'                 => '33000890-E5B1-11CF-89F4-00A0C90349CB',
        'ASF_Degradable_JPEG_Media'               => '35907DE0-E415-11CF-A917-00805F5C442B',
        'ASF_Payload_Extension_System_Timecode'   => '399595EC-8667-4E2D-8FDB-98814CE76C1E',
        'ASF_Binary_Media'                        => '3AFB65E2-47EF-40F2-AC2C-70A90D71D343',
        'ASF_Timecode_Index_Object'               => '3CB73FD0-0C4A-4803-953D-EDF7B6228F0C',
        'ASF_Metadata_Library_Object'             => '44231C94-9498-49D1-A141-1D134E457054',
        'ASF_Reserved_3'                          => '4B1ACBE3-100B-11D0-A39B-00A0C90348F6',
        'ASF_Reserved_4'                          => '4CFEDB20-75F6-11CF-9C0F-00A0C90349CB',
        'ASF_Command_Media'                       => '59DACFC0-59E6-11D0-A3AC-00A0C90348F6',
        'ASF_Header_Extension_Object'             => '5FBF03B5-A92E-11CF-8EE3-00C00C205365',
        'ASF_Media_Object_Index_Parameters_Obj'   => '6B203BAD-3F11-4E84-ACA8-D7613DE2CFA7',
        'ASF_Header_Object'                       => '75B22630-668E-11CF-A6D9-00AA0062CE6C',
        'ASF_Content_Description_Object'          => '75B22633-668E-11CF-A6D9-00AA0062CE6C',
        'ASF_Error_Correction_Object'             => '75B22635-668E-11CF-A6D9-00AA0062CE6C',
        'ASF_Data_Object'                         => '75B22636-668E-11CF-A6D9-00AA0062CE6C',
        'ASF_Web_Stream_Media_Subtype'            => '776257D4-C627-41CB-8F81-7AC7FF1C40CC',
        'ASF_Stream_Bitrate_Properties_Object'    => '7BF875CE-468D-11D1-8D82-006097C9A2B2',
        'ASF_Language_List_Object'                => '7C4346A9-EFE0-4BFC-B229-393EDE415C85',
        'ASF_Codec_List_Object'                   => '86D15240-311D-11D0-A3A4-00A0C90348F6',
        'ASF_Reserved_2'                          => '86D15241-311D-11D0-A3A4-00A0C90348F6',
        'ASF_File_Properties_Object'              => '8CABDCA1-A947-11CF-8EE4-00C00C205365',
        'ASF_File_Transfer_Media'                 => '91BD222C-F21C-497A-8B6D-5AA86BFC0185',
        'ASF_Advanced_Mutual_Exclusion_Object'    => 'A08649CF-4775-4670-8A16-6E35357566CD',
        'ASF_Bandwidth_Sharing_Object'            => 'A69609E6-517B-11D2-B6AF-00C04FD908E9',
        'ASF_Reserved_1'                          => 'ABD3D211-A9BA-11cf-8EE6-00C00C205365',
        'ASF_Bandwidth_Sharing_Exclusive'         => 'AF6060AA-5197-11D2-B6AF-00C04FD908E9',
        'ASF_Bandwidth_Sharing_Partial'           => 'AF6060AB-5197-11D2-B6AF-00C04FD908E9',
        'ASF_JFIF_Media'                          => 'B61BE100-5B4E-11CF-A8FD-00805F5C442B',
        'ASF_Stream_Properties_Object'            => 'B7DC0791-A9B7-11CF-8EE6-00C00C205365',
        'ASF_Video_Media'                         => 'BC19EFC0-5B4D-11CF-A8FD-00805F5C442B',
        'ASF_Audio_Spread'                        => 'BFC3CD50-618F-11CF-8BB2-00AA00B4E220',
        'ASF_Metadata_Object'                     => 'C5F8CBEA-5BAF-4877-8467-AA8C44FA4CCA',
        'ASF_Payload_Ext_Syst_Sample_Duration'    => 'C6BD9450-867F-4907-83A3-C77921B733AD',
        'ASF_Group_Mutual_Exclusion_Object'       => 'D1465A40-5A79-4338-B71B-E36B8FD6C249',
        'ASF_Extended_Content_Description_Object' => 'D2D0A440-E307-11D2-97F0-00A0C95EA850',
        'ASF_Stream_Prioritization_Object'        => 'D4FED15B-88D3-454F-81F0-ED5C45999E24',
        'ASF_Payload_Ext_System_Content_Type'     => 'D590DC20-07BC-436C-9CF7-F3BBFBF1A4DC',
        'ASF_Index_Object'                        => 'D6E229D3-35DA-11D1-9034-00A0C90349BE',
        'ASF_Bitrate_Mutual_Exclusion_Object'     => 'D6E229DC-35DA-11D1-9034-00A0C90349BE',
        'ASF_Index_Parameters_Object'             => 'D6E229DF-35DA-11D1-9034-00A0C90349BE',
        'ASF_Mutex_Language'                      => 'D6E22A00-35DA-11D1-9034-00A0C90349BE',
        'ASF_Mutex_Bitrate'                       => 'D6E22A01-35DA-11D1-9034-00A0C90349BE',
        'ASF_Mutex_Unknown'                       => 'D6E22A02-35DA-11D1-9034-00A0C90349BE',
        'ASF_Web_Stream_Format'                   => 'DA1E6B13-8359-4050-B398-388E965BF00C',
        'ASF_Payload_Ext_System_File_Name'        => 'E165EC0E-19ED-45D7-B4A7-25CBD1E28E9B',
        'ASF_Marker_Object'                       => 'F487CD01-A951-11CF-8EE6-00C00C205365',
        'ASF_Timecode_Index_Parameters_Object'    => 'F55E496D-9797-4B5D-8C8B-604DFE9BFB24',
        'ASF_Audio_Media'                         => 'F8699E40-5B4D-11CF-A8FD-00805F5C442B',
        'ASF_Media_Object_Index_Object'           => 'FEB103F8-12AD-4C64-840F-2A1D2F7AD48C',
        'ASF_Alt_Extended_Content_Encryption_Obj' => 'FF889EF1-ADEE-40DA-9E71-98704BB928CE',
    }
  end
end
