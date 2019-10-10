require 'uri'

#
# Logging
#
begin
  require 'java'
  $delegate_logger = Java::edu.illinois.library.cantaloupe.script.Logger
rescue
  puts 'Could not load Cantaloupe logger'
end

def log(message, level='info')
  # Log message to cantaloupe logger if available with native Ruby fallback.
  if $delegate_logger.nil?
    puts "#{level}: #{message}"
  else
    $delegate_logger.public_send(level, message)  # call e.g.: Logger.info(message)
  end
end


#
# Whitelist
#
# Loading whitelist from disk once and storing as global variable
# Code outside of CustomDelegate because that class is instantiated EVERY request
def get_whitelist(path)
  log("opening whitelist: #{path}")

  whitelist = File.read(path).split("\n") # double quotes are important!
  whitelist.freeze # prevent modification, will be used by multiple threads
  return whitelist
end

$whitelist_path = ENV['WHITELIST_PATH']
log("loading edepot whitelist from disk: #{$whitelist_path}...")
$edepot_whitelist = get_whitelist($whitelist_path)
log("loaded whitelist: #{$edepot_whitelist.length} documents whitelisted")


##
# Sample Ruby delegate script containing stubs and documentation for all
# available delegate methods. See the user manual for more information.
#
# The application will create an instance of this class early in the request
# cycle and dispose of it at the end of the request cycle. Instances don't need
# to be thread-safe, but sharing information across instances (requests)
# **does** need to be done thread-safely.
#
# This version of the script works with Cantaloupe version 4, and not earlier
# versions. Likewise, earlier versions of the script are not compatible with
# Cantaloupe 4.
#
class CustomDelegate

  ##
  # Attribute for the request context, which is a hash containing information
  # about the current request.
  #
  # This attribute will be set by the server before any other methods are
  # called. Methods can access its keys like:
  #
  # ```
  # identifier = context['identifier']
  # ```
  #
  # The hash will contain the following keys in response to all requests:
  #
  # * `client_ip`        [String] Client IP address.
  # * `cookies`          [Hash<String,String>] Hash of cookie name-value pairs.
  # * `identifier`       [String] Image identifier.
  # * `request_headers`  [Hash<String,String>] Hash of header name-value pairs.
  # * `request_uri`      [String] Public request URI.
  # * `scale_constraint` [Array<Integer>] Two-element array with scale
  #                      constraint numerator at position 0 and denominator at
  #                      position 1.
  #
  # It will contain the following additional string keys in response to image
  # requests:
  #
  # * `full_size`      [Hash<String,Integer>] Hash with `width` and `height`
  #                    keys corresponding to the pixel dimensions of the
  #                    source image.
  # * `operations`     [Array<Hash<String,Object>>] Array of operations in
  #                    order of application. Only operations that are not
  #                    no-ops will be included. Every hash contains a `class`
  #                    key corresponding to the operation class name, which
  #                    will be one of the `e.i.l.c.operation.Operation`
  #                    implementations.
  # * `output_format`  [String] Output format media (MIME) type.
  # * `resulting_size` [Hash<String,Integer>] Hash with `width` and `height`
  #                    keys corresponding to the pixel dimensions of the
  #                    resulting image after all operations have been applied.
  #
  # @return [Hash] Request context.
  #
  attr_accessor :context
  IMAGES_DIR = '/images/'
  IMAGES_EDEPOT_LOCAL_DIR = IMAGES_DIR + 'edepot/'
  EDEPOT_WHITELIST = IMAGES_EDEPOT_LOCAL_DIR + 'stadsarchief_whitelist_small'

  def identifier_parts
    identifier = context['identifier']
    parts = identifier.split(':', 2)
    return parts.first, parts.last
  end

  def decode_edepot_identifier(identifier)
    return identifier.gsub('$', '/')
  end

  def check_edepot_whitelist(identifier)
    if $edepot_whitelist.include? identifier
      log("access granted, identifier #{identifier} in whitelist", 'trace')
      true
    else
      log("access denied, identifier #{identifier} not in whitelist", 'warn')
      false
    end
  end

  def is_authorized_access_private()
    headers = context.fetch('request_headers', {})
    roles = headers.fetch('X-Auth-Roles', '').split(',')
    log("roles in header: #{roles}", 'trace')
    return roles.include? 'edepot_private'
  end

  ##
  # Returns authorization status for the current request. Will be called upon
  # all requests to all public endpoints.
  #
  # Implementations should assume that the underlying resource is available,
  # and not try to check for it.
  #
  # Possible return values:
  #
  # 1. Boolean true/false, indicating whether the request is fully authorized
  #    or not. If false, the client will receive a 403 Forbidden response.
  # 2. Hash with a `status_code` key.
  #     a. If it corresponds to an integer from 200-299, the request is
  #        authorized.
  #     b. If it corresponds to an integer from 300-399:
  #         i. If the hash also contains a `location` key corresponding to a
  #            URI string, the request will be redirected to that URI using
  #            that code.
  #         ii. If the hash also contains `scale_numerator` and
  #            `scale_denominator` keys, the request will be
  #            redirected using that code to a virtual reduced-scale version of
  #            the source image.
  #     c. If it corresponds to 401, the hash must include a `challenge` key
  #        corresponding to a WWW-Authenticate header value.
  #
  # @param options [Hash] Empty hash.
  # @return [Boolean,Hash<String,Object>] See above.
  #
  def authorize(options = {})
    namespace, identifier = identifier_parts()

    case namespace
    when 'edepot', 'edepot_local'
      edepot_identifier = decode_edepot_identifier(identifier)

      if is_authorized_access_private()
        return true
      else
        return check_edepot_whitelist(edepot_identifier)
      end
    else
      log('no IIIF authorization for namespace ' + namespace, 'trace')
      true
    end
  end

  ##
  # Used to add additional keys to an information JSON response. See the
  # [Image API specification](http://iiif.io/api/image/2.1/#image-information).
  #
  # @param options [Hash] Empty hash.
  # @return [Hash] Hash that will be merged into an IIIF Image API 2.x
  #                information response. Return an empty hash to add nothing.
  #
  def extra_iiif2_information_response_keys(options = {})
=begin
    Example:
    {
        'attribution' =>  'Copyright My Great Organization. All rights '\
                          'reserved.',
        'license' =>  'http://example.org/license.html',
        'logo' =>  'http://example.org/logo.png',
        'service' => {
            '@context' => 'http://iiif.io/api/annex/services/physdim/1/context.json',
            'profile' => 'http://iiif.io/api/annex/services/physdim',
            'physicalScale' => 0.0025,
            'physicalUnits' => 'in'
        }
    }
=end
    {}
  end

  ##
  # Tells the server which source to use for the given identifier.
  #
  # @param options [Hash] Empty hash.
  # @return [String] Source name.
  #
  def source(options = {})
    namespace, identifier = identifier_parts()

    log('source switch statement, identifier: ' + identifier, 'trace')

    case namespace
    when 'objectstore', 'edepot', 'beeldbank'
      source = 'HttpSource'
    when 'edepot_local'
      source = 'FilesystemSource'
    else
      source = 'FilesystemSource'
    end

    log('using source: ' + source, 'debug')
    source
  end

  ##
  # @param options [Hash] Empty hash.
  # @return [String,nil] Blob key of the image corresponding to the given
  #                      identifier, or nil if not found.
  #
  def azurestoragesource_blob_key(options = {})
  end

  ##
  # @param options [Hash] Empty hash.
  # @return [String,nil] Absolute pathname of the image corresponding to the
  #                      given identifier, or nil if not found.
  #
  def filesystemsource_pathname(options = {})
    namespace, identifier = identifier_parts()

    log('namespace: ' + namespace, 'trace')

    if namespace === 'edepot_local'
      log('edepot_local identifier: ' + identifier, 'trace')
      parts = identifier.split('$')
      log('parts: ' + parts.join(', '), 'debug')
      IMAGES_EDEPOT_LOCAL_DIR + parts.join('-')
    else
      IMAGES_DIR  + context['identifier']
    end
  end

  ##
  # Returns one of the following:
  #
  # 1. String URI
  # 2. Hash with the following keys:
  #     * `uri` [String] (required)
  #     * `username` [String] For HTTP Basic authentication (optional).
  #     * `secret` [String] For HTTP Basic authentication (optional).
  #     * `headers` [Hash<String,String>] Hash of request headers (optional).
  # 3. nil if not found.
  #
  # @param options [Hash] Empty hash.
  # @return See above.
  #
  def httpsource_resource_info(options = {})
    namespace, identifier = identifier_parts()

    # TODO: read base URIs from config file, see commit 850c9fd38b1072b2a4374f45cd810fad12bd45e8 for load_props code
    case namespace
    when 'objectstore'
      return "https://f8d5776e78674418b6f9a605807e069a.objectstore.eu/Images/#{identifier}"
    when 'beeldbank'
      return "https://beeldbank.amsterdam.nl/component/ams_memorixbeeld_download/?format=download&id=#{identifier}"
    when 'edepot'
      edepot_identifier = decode_edepot_identifier(identifier)
      uri = URI.decode(edepot_identifier)

      return {
        "uri" => "https://bwt.uitplaatsing.hcp-a.basis.lan/rest/#{uri}",
        "headers" => {
          "Authorization" => ENV['HCP_AUTHORIZATION']
        }
      }
    end
  end

  ##
  # @param options [Hash] Empty hash.
  # @return [String] Identifier of the image corresponding to the given
  #                  identifier in the database.
  #
  def jdbcsource_database_identifier(options = {})
  end

  ##
  # Returns either the media (MIME) type of an image, or an SQL statement that
  # can be used to retrieve it, if it is stored in the database. In the latter
  # case, the "SELECT" and "FROM" clauses should be in uppercase in order to
  # be autodetected. If nil is returned, the media type will be inferred some
  # other way, such as by identifier extension or magic bytes.
  #
  # @param options [Hash] Empty hash.
  # @return [String, nil]
  #
  def jdbcsource_media_type(options = {})
  end

  ##
  # @param options [Hash] Empty hash.
  # @return [String] SQL statement that selects the BLOB corresponding to the
  #                  value returned by `jdbcsource_database_identifier()`.
  #
  def jdbcsource_lookup_sql(options = {})
  end

  ##
  # @param options [Hash] Empty hash.
  # @return [Hash<String,Object>,nil] Hash containing `bucket` and `key` keys;
  #                                   or nil if not found.
  #
  def s3source_object_info(options = {})
  end

  ##
  # Tells the server what overlay, if any, to apply to an image in response
  # to a request. Will be called upon all image requests to any endpoint if
  # overlays are enabled and the overlay strategy is set to `ScriptStrategy`
  # in the application configuration.
  #
  # N.B.: When a string overlay is too large or long to fit entirely within
  # the image, it won't be drawn. Consider breaking long strings with LFs (\n).
  #
  # @param options [Hash] Empty hash.
  # @return [Hash<String,String>,nil] For image overlays, a hash with `image`,
  #         `position`, and `inset` keys. For string overlays, a hash with
  #         `background_color`, `color`, `font`, `font_min_size`, `font_size`,
  #         `font_weight`, `glyph_spacing`,`inset`, `position`, `string`,
  #         `stroke_color`, and `stroke_width` keys.
  #         Return nil for no overlay.
  #
  def overlay(options = {})
  end

  ##
  # Tells the server what regions of an image to redact in response to a
  # particular request. Will be called upon all image requests to any endpoint
  # if redactions are enabled in the application configuration.
  #
  # @param options [Hash] Empty hash.
  # @return [Array<Hash<String,Integer>>] Array of hashes, each with `x`, `y`,
  #         `width`, and `height` keys; or an empty array if no redactions are
  #         to be applied.
  #
  def redactions(options = {})
    []
  end

end
