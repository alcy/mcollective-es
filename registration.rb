module MCollective
  module Agent
    class Registration
      attr_reader :timeout, :meta
     
      def initialize
        @meta = {:license => "Apache 2",
          :author => "alcy",
          :url => "http://github.com/alcy/mcollective-es"}

        require 'tire'

        @timeout = 2

        @config = Config.instance

        @eshost = @config.pluginconf["registration.eshost"] || "localhost"
        @esport = @config.pluginconf["registration.esport"] || "9200"
        @esindex = @config.pluginconf["registration.esindex"] || "hosts"
        @estype = @config.pluginconf["registration.estype"] || "document"
        @docttl = @config.pluginconf["registration.docttl"] || "300s"
        @ttldisabled = @config.pluginconf["registration.ttldisabled"] || "false"

        Tire.configure do 
          url "#{@eshost}:#{@esport}"
        end

      end

      def handlemsg(msg, connection)
        req = msg[:body]
        
        begin
          Tire.index @esindex do
            create :mappings => { 
              :document => {
                :_ttl => { :enabled => true, :default => @docttl }
              }
            } unless @ttldisabled == "false" 
            store :data => req,
                  :id => msg[:senderid],
                  :type => @estype

          end
        rescue Exception => e
          Log.instance.debug("Couldn't index : #{e.backtrace.inspect}")
        end

        nil
      end
    end
  end
end
