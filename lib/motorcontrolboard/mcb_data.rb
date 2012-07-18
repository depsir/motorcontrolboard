#!/usr/bin/env ruby
require "yaml"

class MotorControlBoard

    # Internal representation of the board memory, as array of hashes
    attr_reader :data

    # Init the internal representation loading the given file.
    # 
    # Params:
    # +initFile+:: the path to a yaml file containing the data structure to be used.
    # The file should contain at least mask_name, position and type. 
    # Also if value and valid are present they will be set to 0.
    # Other fields are permitted although they will not be used:
    # this functionality is not tested.
    # 
    # Data will be sorted by position
	def initData(initFile)
        @data = []
        initData = YAML.load_file(initFile)
        initData.each do |datum|
            datum['value']=0
            datum['valid']=0
        end
        @data = initData
        sortData()
    end 

    # Return internal data in yaml format
    def saveData
        YAML.dump @data
    end

    # Dump internal data to yaml format and save to file
    # Params:
    # +path+:: path where to save the yaml data
    def saveDataToFile(path)
        File.open(path, 'w') do |f|
            YAML.dump(@data, f)
        end
    end

    # Return the index of the matching row diven some search params in hash format
    # 
    # Params:
    # +needle+:: the hash to search. Search is performed by mask_name, position and type.
    # 
    # If the result contains one row only, its index is returned, otherwise nil is returned
    def findData(needle)
        result = @data
        result = result.select { |a| a['mask_name']==needle['mask_name']} if needle['mask_name'] != nil
        result = result.select { |a| a['position']==needle['position']} if needle['position'] != nil
        result = result.select { |a| a['type']==needle['type']} if needle['type'] != nil
        if result.length == 1        
            @data.index result.first
        else
            nil
        end
    end

    # Add data to internal representation
    # 
    # Params:
    # +newData+:: data to add in array of hashes format 
    # If the valid field is present, only rows with valid==1 will be taken into account.
    # The matching row, selected with the #findData method, is updated with the new value and the valid bit is set
    def addData(newData)
        if newData[0]['valid'] != nil 
            newData = newData.select{|newData| newData['valid']==1}
        end
        newData.each do |newValidDatum|
            if (index = findData(newValidDatum))
                @data[index]['value'] = newValidDatum['value']
                @data[index]['valid'] = 1
            else
                puts 'Unable to find entry matching mask_name and position'
                puts newValidDatum
            end
        end
        sortData()
    end
    # Load data from a yaml representation
    # 
    # #addData is called so that everything is stored in the internal state
    def loadData(dataToLoad)
        addData(YAML.load(dataToLoad))
    end

    # Load a yaml file and saves to state with #addData
    def loadDataFromFile(path)
        addData(YAML.load_file(path))
    end

    # Set valid bit to 0 for each row
    def dataResetValid
        @data.each {|row| row['valid']=0}
    end

    # Set valid bit to 1 for each row
    def dataSetValid
        @data.each {|row| row['valid']=1}
    end
    
    # Sort data by position
    def sortData
        @data = @data.sort_by { |row| row['position'] }
    end

    # Return the maximum value of the position field among all data
    def getMaxPos
        @data.max_by {|row| row['position']}['position']
    end

    def validDataLength
        @data.select{|row| row['valid']==1}.inject(0){|sum, row| sum+lenByType(row['type'])}
    end
end