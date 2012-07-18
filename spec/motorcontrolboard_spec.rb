require 'spec_helper'

describe MotorControlBoard do
before :each do
    @m = MotorControlBoard.new
end

describe "#new" do
    it "takes 0..2 parameters and returns a MotorControlBoard object" do
        @m.should be_an_instance_of MotorControlBoard
    end
end

describe "#dataMask" do
	it "should return the valid bit as binary mask string" do
		@m.dataMask.should eql "0b"+'0'*(@m.getMaxPos+1)
		@m.data[1]['valid']='1'
		@m.dataMask.should eql "0b"+'0'*(@m.getMaxPos-1)+'10'
		@m.data[0]['valid']='1'
		@m.dataMask.should eql "0b"+'0'*(@m.getMaxPos-1)+'11'
	end
end

describe "#maskToPos" do
	it "should extract positions with 1 in the mask" do
		@m.maskToPos('0b0000').should eql []
		@m.maskToPos('0b0000').should_not eql [0]
		@m.maskToPos('0b0001').should eql [0]
		@m.maskToPos('0b0010').should eql [1]
		@m.maskToPos('0b0011').should eql [0, 1]
	end
end

describe "#invalidateData" do
	it "should reset the valid bit" do
		@m.data[0]['valid']='1'
		@m.data[(@m.getMaxPos())]['valid']='1'
		@m.data[12]['valid']='1'
		@m.data[24]['valid']='1'
		@m.invalidateData
		@m.dataMask.should eql "0b"+'0'*(@m.getMaxPos+1)
		@m.data[0]['valid']='1'
		@m.data[1]['valid']='1'
		@m.data[2]['valid']='1'
		@m.data[3]['valid']='1'
		@m.invalidateData
		@m.dataMask.should eql "0b"+'0'*(@m.getMaxPos+1)
	end
end

describe "#validateData" do
	it "should reset the valid bit" do
		@m.data[0]['valid']='1'
		@m.data[(@m.getMaxPos())]['valid']='1'
		@m.data[12]['valid']='1'
		@m.data[24]['valid']='1'
		@m.validateData
		@m.dataMask.should eql "0b"+'1'*(@m.getMaxPos+1)
		@m.data[0]['valid']='1'
		@m.data[1]['valid']='1'
		@m.data[2]['valid']='1'
		@m.data[3]['valid']='1'
		@m.validateData
		@m.dataMask.should eql "0b"+'1'*(@m.getMaxPos+1)
	end
end

describe "#maskToValid" do
	it "should transform a mask into valid bits" do
		[0,1].repeated_permutation(4).each do |mask|
			mask = '0b' +'0'*(@m.getMaxPos-3) + mask.join
			@m.invalidateData
			@m.maskToValid(mask)
			@m.dataMask.should eql mask
		end
		[0,1].repeated_permutation(4).each do |mask|
			mask = '0b'+ mask.join + '0'*(@m.getMaxPos-3)
			@m.invalidateData
			@m.maskToValid(mask)
			@m.dataMask.should eql mask
		end
		[0,1].repeated_permutation(4).each do |mask|
			mask = '0b' +'0'*11+ mask.join+'0'*(@m.getMaxPos-11-3)
			@m.invalidateData
			@m.maskToValid(mask)
			@m.dataMask.should eql mask
		end
	end
end

describe "#maskFromNames" do
	it "should create a mask according to the names passed as parameter" do
		@m.maskFromNames().should eql "0b"+'0'*(@m.getMaxPos+1)
		@m.maskFromNames(:ctrl_kp).should eql "0b"+'0'*24+'1'
		@m.maskFromNames(:ctrl_ki).should eql "0b"+'0'*23+'10'
		@m.maskFromNames(:ctrl_kp, :ctrl_ki).should eql "0b"+'0'*23+'11'
		@m.maskFromNames(:board_id).should eql "0b"+'1'+'0'*24
	end
end

describe "#positionFromName" do
	it "return the position of the given name" do
		@m.positionFromName(:ctrl_kp).should eql 0
		@m.positionFromName(:ctrl_ki).should eql 1
		@m.positionFromName(:board_id).should eql 24
	end
end

end
