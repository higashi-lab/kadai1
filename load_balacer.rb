class Packet < Controller
	def start
		@fdbList = {}
	end

	def switch_ready dpid
		@fdbList[dpid.to_hex] = {}
	end

	def switch_disconnected dpid
		@fdbList.delete(dpid.to_hex)
	end

	def packet_in dpid,message
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

end
