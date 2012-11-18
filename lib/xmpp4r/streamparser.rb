# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'rexml/parsers/sax2parser'
require 'rexml/source'
require 'nokogiri'
require 'xmpp4r/rexmladdons'

module Jabber
  class StreamParser < Nokogiri::XML::SAX::Document
    # status if the parser is started
    attr_reader :started

    ##
    # Constructs a parser for the supplied stream (socket input)
    #
    # stream:: [IO] Socket input stream
    # listener:: [Object.receive(XMPPStanza)] The listener (usually a Jabber::Protocol::Connection instance)
    #
    def initialize(listener)
      @listener = listener
      @current = nil
      @started = false
    end
    
    def start_element(name, attrs = [])
      e = REXML::Element.new(name)
      e.add_attributes attrs
      @current = @current.nil? ? e : @current.add_element(e)

      # Handling <stream:stream> not only when it is being
      # received as a top-level tag but also as a child of the
      # top-level element itself. This way, we handle stream
      # restarts (ie. after SASL authentication).
      if @current.name == 'stream' and @current.parent.nil?
        @started = true
        @listener.receive(@current)
        @current = nil
      end
    end

    def end_element(name)
      if name == 'stream:stream' and @current.nil?
        @started = false
        @listener.parser_end
      else
        @listener.receive(@current) unless @current.parent
        @current = @current.parent
      end
    end
    
    def characters(s)
      @current.add(REXML::Text.new(s.to_s, @current.whitespace, nil, true)) if @current
    end
    
    def cdata_block(s)
      @current.add(REXML::CData.new(s)) if @current
    end
    
    def end_document
      raise Jabber::ServerDisconnected, "Server Disconnected!"
    end
  end
  
end
