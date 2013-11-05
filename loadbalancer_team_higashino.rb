class Packet < Controller
    MIN_INDEX = 128
    MAX_INDEX = 254

	def start
    @firstClient = ""
		@fdb = {}

    @srvIP = []
    @srvMAC = {}
    @srvPort = {}
    @isFirst = true
    @targetSrv = ""
    @target = 0

	end

	def switch_ready dpid
    search_server(dpid)
	end

	def packet_in dpid,message
 
   if message.arp_reply?
      get_arp_reply(dpid,message)
      defalt_OFPP(dpid,message)
    elsif message.arp_request?
      defalt_OFPP(dpid,message)
    end

    if message.ipv4?

      if message.ipv4_daddr.to_s.split(".")[3].to_i >= 128 

        @target = (@target + 1) % (@srvIP.size)
        @targetSrv = @srvIP[@target]

		    send_flow_mod_add(
			    dpid,
            :hard_timeout => 0.1,
			      :match => ExactMatch.from(message),
			      :actions => [
			         SetIpDstAddr.new(@srvIP[@target]),
			         SetEthDstAddr.new(@srvMAC[@targetSrv]),
			         SendOutPort.new(@srvPort[@targetSrv])
		        ]
		      )
        send_packet_out(
			    dpid,
			    :packet_in => message,
		      :actions => [
		         SetIpDstAddr.new(@srvIP[@target]),
		         SetEthDstAddr.new(@srvMAC[@targetSrv]),
		         SendOutPort.new(@srvPort[@targetSrv])
	        ]
        )
      end


      if message.ipv4_daddr.to_s.split(".")[3].to_i < 128

  	  	@fdb[message.macsa] = message.in_port
  		  port = @fdb[message.macda] ? @fdb[message.macda] : OFPP_FLOOD

        if port
			    send_flow_mod_add(
				    dpid,
            :match => Match.new( :in_port => port,
						  						       :dl_dst => message.macda),
				    :actions => Trema::SendOutPort.new(port)
          )
        end
        
        send_packet_out(
          dpid,
		      :packet_in => message,
          :actions => Trema::SendOutPort.new(port)
        )
		    
      end
    end
	end


  def create_arp_req n
    ip = '192.168.0.' + n.to_s
    Pio::Arp::Request.new(
      :source_mac => '00:00:00:00:00:00',
      :sender_protocol_address => '0.0.0.0',
      :target_protocol_address => ip
    )
  end

  def flood dpid,packet
    send_packet_out(
      dpid,
      :data => packet,
      :actions => Trema::SendOutPort.new( OFPP_FLOOD )
    )
  end

  def search_server dpid
    for i in MIN_INDEX..MAX_INDEX do
      arp_req = create_arp_req(i)
      flood(dpid, arp_req.to_binary)
    end
  end

  def get_arp_reply dpid,message
    ip = message.arp_spa.to_s
    bit = ip.split(".")
    low = bit[3].to_i
    if ((!@srvMAC.key?(ip))&&(low>=MIN_INDEX))

      @srvIP.push(ip)
      @srvMAC[ip] = message.arp_sha.to_s
      @srvPort[ip] = message.in_port

    end
  end

  def defalt_OFPP(dpid,message)
    flow_OFPP(dpid,message)
    send_packet_OFPP(dpid, message)
  end
  def flow_OFPP(dpid,message)

			  send_flow_mod_add(
				  dpid,
				  :match => Match.from(message),
				  :actions => Trema::SendOutPort.new(OFPP_FLOOD)
        )
  end

  def send_packet_OFPP(dpid, message)
 
      send_packet_out(
        dpid,
        :packet_in => message,
        :actions => Trema::SendOutPort.new(OFPP_FLOOD)
      )

  end
end
