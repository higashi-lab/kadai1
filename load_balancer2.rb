class Packet < Controller
#  add_periodic_timer_event(:time_out,10);
	def start
    @firstClient = ""
		@fdbList = {}
    @srvList = []
    @searchFlug = true
    @ackFlug = false
    @count = 0
	end

	def switch_ready dpid
		@fdbList[dpid.to_hex] = {}
	end

	def switch_disconnected dpid
		@fdbList.delete(dpid.to_hex)
	end

	def packet_in dpid,message
    if @searchFlug
      search_server(dpid,message)
    end
    if @ackFlug
      resister_server(dpid,message)
    end

		@fdbList[dpid.to_hex][message.macsa] = message.in_port
		port = @fdbList[dpid.to_hex][message.macda] ? @fdbList[dpid.to_hex][message.macda] : OFPP_FLOOD
		if @fdbList[dpid.to_hex][message.macda]
			send_flow_mod_add(
				dpid,
				:match => Match.new( :in_port => port,
														 :dl_dst => message.macda),
				:actions => Trema::SendOutPort.new(port) )
		end
		send_packet_out(
			dpid,
			:packet_in => message,
			:actions => Trema::SendOutPort.new(port) )
	end 


  def search_server dpid,message
    send_packet_out(
			dpid,
			:packet_in => message,
			:actions => Trema::SendOutPort.new(OFPP_FLOOD) )
    @firstClient = message.macda
    @ackFlug = true
    @searchFlug = false
  end

  def resister_server dpid,message
    if (message.macsa == @firstClient)
      @srvList << Server.new(message.macsa,dpid.to_hex,message.in_port)
      @count += 1
      if @count > 15
        @ackFlug = false
        outputFile
      end
    end
  end
=begin
  private
  def time_out
    puts @srvList.join ","
  end
=end

  def outputFile
    file = "test.txt"
    str = "client: #@firstClient \n"
    for var in @srvList do
      str = str + var.to_s + "\n"
    end
    mode = "w"
    open( file , mode ){|f| f.write(str)}
  end

end

class Server
  def initialize(m,d,p)
    @macsa = m
    @dpid = d
    @port = p
  end

  def to_s
    "#@macsa, #@dpid, #@port"
  end
end
