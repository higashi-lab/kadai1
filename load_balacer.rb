class PacketIO < Controller

	def start
		@fdbs = {}
	end	

	def packet_in dpid,message
		switch = @fdbs[dpid]
		if switch == nil
			@fdbs[dpid] = {}
		end

		@fdbs[dpid][message.macsa] = message.in_port
		port = @fdbs[dpid][message.macda]

		if port 
			send_flow_mod_add(dpid,
			:match => Match.from(message),
			:actions => SendOutPort.new(port))
			send_packet_out(dpid, 
  			:packet_in => message,
			:actions => Trema::SendOutPort.new(port))
		else
			send_packet_out(dpid, 
  			:packet_in => message,
			:actions => Trema::SendOutPort.new(OFPP_FLOOD))
		end

	end

end
