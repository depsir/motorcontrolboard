#!/usr/bin/env ruby
require "serialport"
class MotorControlBoard
	# Descriptor of the vid/pid of the board. Something like '10c4:ea60'.
    # Can be obtained through a command like 'lsusb'.
    # 
    # Setting this variable allow to discover the port where the board is conencted automatically
	attr_accessor :vidpid
    # String describing the port where the board is connected.
    # Usually is something like '/dev/ttyUSB0'. Can be auto-discovered, setting the #vidpid variable if the vid:pid of the board is known
    attr_accessor :port
    # Baud rate of the connection. In the actual firmware version it should be 57600
    attr_accessor :baud_rate
    # attr_reader :sp

    # Shortcut to set a '/dev/ttyUSBx' port. It also connects to that port
    # 
    # Params:
    # +num+:: number of the ttyUSB port to be set
    def setPort(num)
        @port = '/dev/ttyUSB' + num.to_s
        connect
    end

    # Connect to serial port specified by @port member
    # 
    # If @vidpid is set, it checks if that device is connected to a serial port and that port is chosen, regardless of the @port value.
    # If block given it closes the connection at the end of the block
    def connect
    	if findPort()
    		puts "Automatically selected port #{@port}"
    	end
        data_bits = 8
        stop_bits = 1
        parity = SerialPort::NONE
        begin
            @sp = SerialPort.new(@port, @baud_rate, data_bits, stop_bits, parity)
            @open = true

        rescue
            puts 'ERROR: Unable to find serial port ' + @port
            @open = false
        end

        if block_given?
            yield
            self.disconnect
            p "port closed"
        end
        @open
    end

    # Disconnect from serial port
    def disconnect
        if @open
            @open = false
            @sp.close
        end
    end

    # Find the port to which the board is connected, looking for the specified @vidpid
    def findPort
    	begin
    		if @vidpid
		    	busNumber = Integer(`lsusb|grep #{@vidpid}`[4..6])
		    	port = `ls /sys/bus/usb-serial/devices/ -ltrah |grep usb#{busNumber}`.chop
		    	@port = '/dev/'+port.gsub(/ttyUSB[0-9]+/).first
		    else
		    	false
		    end
	    rescue
	    	false
	    end
    end

    # Send a single char
    def sendC(char)
        if (!@open)
            connect()
        end
        @sp.putc char.chr
    end

    # Send a string of char
    def sendS(string)
        string.each_char do |char| 
            sendC(char) 
        end
    end

    def startByte()
        sendC(0x55)
        sleep 0.1
    end
end
