# encoding: utf-8

require 'cgi'

module OmnibusChef
  # This class provides a client to the Omnitruck API
  # http://docs.opscode.com/api_omnitruck.html
  class Omnitruck
    attr_reader :node
    def initialize(node)
      @node = node
    end

    def client_url(args={})
      download_url("#{base_url}/download", args)
    end

    def server_url(args={})
      download_url("#{base_url}/download-server", args)
    end

    ARGUMENTS_MAP = {
      :platform => :p,
      :platform_version => :pv,
      :machine => :m,
      :version => :v,
      :prerelease => :prerelease,
      :nightlies => :nightlies
    }

    private

    def base_url
      if ['omnibus_chef']['use_https']
        'https://www.getchef.com/chef'
      else
        'http://www.getchef.com/chef'
      end
    end

    def download_url(base_url, args={})
      args = Mash.new(:url => base_url).merge(args)

      # "latest" is an alias for no defined version
      args[:version] = nil if args[:version] == 'latest'

      # We built a URL which we can call to get a redirect to the
      # actual download URL of the Omnibus package matching the specified
      # arguments
      params = ARGUMENTS_MAP.map do |attr_key, url_key|
        "#{url_key}=#{CGI.escape args[attr_key].to_s}" unless args[attr_key].nil? || args[attr_key].to_s.empty?
      end

      omnibus_chef_url "#{args[:url]}?#{params.compact.join('&')}"
    end

    def omnibus_chef_url(query_url)
      # We call the Omnibus Chef query URL. The Location Header of the answer
      # should point to the actual package to download
      Chef::Log.debug "Getting Omnibus download URL from #{query_url}"
      result = Chef::REST::RESTRequest.new(:head, URI.parse(query_url), nil).call
      if result.is_a? Net::HTTPRedirection
        Chef::Log.debug "Omnibus download URL is #{result['location']}"
        result['location']
      else
        fail "Can retrieve download URL for #{query_url}. Error: #{result}"
      end
    end
  end
end
