#!/usr/bin/env ruby
require "rubygems"
require 'timeout'

require_relative "motorcontrolboard/mcb_connection.rb"
require_relative "motorcontrolboard/mcb_data.rb"


# This class implements an interface to communicate with a Motor Control Board
# (http://irawiki.disco.unimib.it/irawiki/index.php/INFIND2011/12_Motor_control_board)
# 
# It uses an internal representation of the commands that can be sent to the board
# and also the representation of the memory locations where is possible to write/read
# along with the position, the type and the actual value.
# 
# A row in the internal representation, which corresponds to a memory location
# in the physical board, is composed by some fields:
# * mask_name: a symbol to target the field. Is derived from the mask defined in the serial header file of the firmware. The symbol is obtained by removing the initial MASK_ and making the name lowercase
# * position: the position of the memory location, starting from zero
# * type: the tipe of the memory location. It can be one among FLSC accoring to the ARRAY::pack documentation
# * value: the value of the memory location
# * valid: a valid bit. If set, the row will be involved in the next read/write command
class MotorControlBoard
    # Accept as argument an hash specifying #port, #vidpid, and or #baud_rate
    # #data has to be initialized with the apposite function #initData
    def initialize(args = {})
        @port = args['port'] || '/dev/ttyUSB0'
        @baud_rate = args['baud_rate'] || 57600
        @vidpid = args['vidpid']
    end

    
    # Return the mask of the valid bits of the internal representation
    # 
    # The data get sorted but the position is not taken in account so for example if a position is missing a zero will not be added.
    # The user is responsible to provide consistent data
    def dataMask
        sortData()
        '0b' + @data.inject(''){|mem, ob| ob['valid'].to_s + mem    }
    end

    # Return the values according to valid bit
    # 
    # The data get sorted but the position is not taken in account
    # Values are also packed according to their type
    def dataValues
        sortData()
        @data.select{|data| data['valid']==1}.inject("") {|acc, val| acc << [val['value']].pack(val['type'])}
    end

    # Set the valid bit according to a given mask
    def maskToValid(mask)
        maskToPos(mask).each do |pos|
            (@data.select{|row| row['position']==pos}.first)['valid']=1
        end
    end


    # Return a mask according to the names passed as parameters
    # 
    # The length of the mask will be the max pos + 1 so if there are missing/duplicated positions the mask will be inconsistent
    def maskFromNames(*names)
        mask = '0'*(getMaxPos()+1)
        names.each do |name|
            mask[positionFromName(name)]='1'
        end

        mask='0b'+mask.reverse
    end
    # Return the position given the name
    def positionFromName(name)
        (@data.select{|newData| newData['mask_name']==name}.first)['position']
    end

    # Return the mask conresponding to the given position
    def maskByPos(pos)
        return "0b"+"1"+"0"*pos
    end

    # Return the byte length of a type used by pack/unpack
    def lenByType(type)
        case type
        when 'L', 'F'
            4
        when 'S'
            2
        when 'C'
            1
        else
            0
        end
    end

    # Return an array of poses given a mask
    def maskToPos(mask)
        pos = []
        mask[2..-1].reverse.each_char.with_index do |e, i| 
            if e=='1' 
                pos << i
             end
         end
        pos
    end

    # commands
    def sendCommand(command)
        startByte()
        sendC(command)
        if @echo
            puts 'sent: ' + command
            puts 'waiting for return'
            rec = @sp.getc
            puts 'received: ' + rec
            puts 'does they match? ' + (command==rec).to_s
        end
    end
    
    # Send the command set
    def cmd_set
        self.sendCommand('S')
    end
    # Send the command get
    def cmd_get
        self.sendCommand('G')
    end
    # Send the command start
    def cmd_start
        self.sendCommand('x')
    end
    # Send the command gorunning
    def cmd_gorunning
        self.sendCommand('a')
    end
    # Send the command gocalib
    def cmd_gocalib
        self.sendCommand('b')
    end
    # Send the command goinit
    def cmd_goinit
        self.sendCommand('i')
    end
    # Send the command coast
    def cmd_coast
        self.sendCommand('j')
    end
    # Send the command uncoast
    def cmd_uncoast
        self.sendCommand('u')
    end
    # Send the command reset
    def cmd_reset
        self.sendCommand('r')
    end
    # Send the command whois and return the result
    def cmd_whois
        self.sendCommand('w')
        who = ""
        while (char = @sp.getc) != "\u0000"
            who << char
        end
        who
    end
        

    # Set data according to valid bit. The value saved in the internal representation will be set
    def setByValid()
        mask = dataMask()
        values = dataValues()
        cmd_set()
        sleep 0.1
        self.sendS([Integer(mask)].pack('L'))
        sleep 0.1
        self.sendS(values)
    end

    # Send single data by name
    # 
    # Params:
    # +name+:: The symbol matching the name of the mask
    # +val+:: The value to assign
    def setByName(name, val)
        dataResetValid
        maskToValid(maskFromNames(name))
        (@data.select {|row| row['mask_name']==name}.first)['value']=val
        setByValid()
    end

    # yet to be implemented.. is this useful?
    def setByPos(pos, val)
    end


    # Read data at the given position
    def getSingleData(pos)
        getByMask(maskByPos(pos))
    end

    # Read data according to the given names
    def getByNames(*names)
        getByMask(maskFromNames(*names))
    end

    # Read data according to the given mask
    def getByMask(mask)
        dataResetValid
        maskToValid(mask)
        getByValid
    end
    
    # Get data according to the valid bit
    def getByValid()
        mask = dataMask()
        if (Integer(mask)!=0) 
            @data = @data.sort_by { |row| row['position'] }
            len = validDataLength
            cmd_get()
            sleep 0.1
            self.sendS([Integer(mask)].pack('L'))
            result = []
            readBytes = []
            begin
                Timeout::timeout(1) do
                    len.times {readBytes << @spr.getc}
                    readBytes.reverse!

                    @data.select{|data| data['valid']==1}.each do |row| #do we need to revert this??
                        data=""
                        lenByType(row['type']).times do
                            data << readBytes.pop
                        end
                        value = data.unpack(row['type']).first
                        row['value'] = value
                        result << {'mask_name'=>row['mask_name'], 'value' => value}
                    end
                end
            rescue
                puts 'Timeout to read with mask ' + mask
                puts 'Read ' + readBytes.length.to_s + '/' + len.to_s + ' bytes'
            end
            return result
        end
    end
end